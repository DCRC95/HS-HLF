#!/usr/bin/env bash
#
# renew_tls.sh
# Iterates over Fabric peers/orderers, enrolls fresh TLS certs, swaps them in
# place (with backups), and restarts containers if requested. All activity is
# logged under logs/cert-renewal.log.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NETWORK_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)
LOG_DIR="${NETWORK_ROOT}/logs"
LOG_FILE="${LOG_DIR}/cert-renewal.log"
mkdir -p "${LOG_DIR}"
touch "${LOG_FILE}"

BIN_DIR="${NETWORK_ROOT}/fabric-samples/bin"
if [[ -d "${BIN_DIR}" && ":$PATH:" != *":${BIN_DIR}:"* ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if ! command -v fabric-ca-client >/dev/null 2>&1; then
  echo "fabric-ca-client binary not found in PATH" >&2
  exit 1
fi

AUTO_RESTART=false
TARGET_FILTER="all"

usage() {
  cat <<EOF
Usage: $(basename "$0") [-c component_name] [-r]

Options:
  -c <component>  Only renew TLS material for the given component
                  (e.g., peer0.banka.example.com)
  -r              Restart the Docker container for each component after renewal
  -h              Show this help message
EOF
}

while getopts ":c:rh" opt; do
  case "${opt}" in
    c) TARGET_FILTER="${OPTARG}" ;;
    r) AUTO_RESTART=true ;;
    h)
      usage
      exit 0
      ;;
    \?)
      echo "Invalid option: -${OPTARG}" >&2
      usage
      exit 1
      ;;
    :)
      echo "Option -${OPTARG} requires an argument." >&2
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

export TEST_NETWORK_HOME="${NETWORK_ROOT}"
# shellcheck source=/dev/null
. "${NETWORK_ROOT}/scripts/envVar.sh"

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log_action() {
  local message=$1
  printf "%s | %s\n" "$(timestamp)" "${message}" | tee -a "${LOG_FILE}"
}

restart_component() {
  local container=$1
  if [[ "${AUTO_RESTART}" != "true" ]]; then
    log_action "op=post-renewal | component=${container} | action=pending-restart | note='run docker restart ${container}'"
    return
  fi

  if docker ps --format '{{.Names}}' | grep -q "^${container}\$"; then
    if docker restart "${container}" >/dev/null; then
      log_action "op=restart | component=${container} | status=success"
    else
      log_action "op=restart | component=${container} | status=failure"
    fi
  else
    log_action "op=restart | component=${container} | status=skipped | note='container not running'"
  fi
}

renew_component_tls() {
  local component=$1
  local type=$2
  local org_key=$3
  local domain=$4
  local ca_port=$5
  local ca_name=$6
  local enroll_id=$7
  local enroll_secret=$8
  local tls_rel_path=$9
  local csr_hosts=${10}
  local container=${11}

  if [[ "${TARGET_FILTER}" != "all" && "${component}" != "${TARGET_FILTER}" ]]; then
    return
  fi

  local tls_dir="${NETWORK_ROOT}/${tls_rel_path}"
  local ca_cert="${NETWORK_ROOT}/organizations/fabric-ca/${org_key}/ca-cert.pem"
  local client_home

  if [[ "${type}" == "orderer" ]]; then
    client_home="${NETWORK_ROOT}/organizations/ordererOrganizations/${domain}"
  else
    client_home="${NETWORK_ROOT}/organizations/peerOrganizations/${domain}"
  fi

  if [[ ! -d "${tls_dir}" ]]; then
    log_action "op=renew | component=${component} | status=skipped | reason='missing tls dir ${tls_dir}'"
    return
  fi

  if [[ ! -f "${ca_cert}" ]]; then
    log_action "op=renew | component=${component} | status=skipped | reason='missing CA cert ${ca_cert}'"
    return
  fi

  mkdir -p "${client_home}"
  export FABRIC_CA_CLIENT_HOME="${client_home}"

  local tmpdir
  tmpdir=$(mktemp -d)
  trap 'rm -rf "${tmpdir}"' RETURN

  IFS=',' read -r -a host_array <<< "${csr_hosts}"
  local enroll_args=()
  for host in "${host_array[@]}"; do
    enroll_args+=(--csr.hosts "${host}")
  done

  if fabric-ca-client enroll \
      -u "https://${enroll_id}:${enroll_secret}@localhost:${ca_port}" \
      --caname "${ca_name}" \
      -M "${tmpdir}" \
      --enrollment.profile tls \
      --tls.certfiles "${ca_cert}" \
      "${enroll_args[@]}" >/dev/null; then
    :
  else
    log_action "op=renew | component=${component} | status=failure | reason='enroll failed'"
    return
  fi

  local backup_dir
  backup_dir="${tls_dir}/backup-$(date -u +%Y%m%dT%H%M%SZ)"
  mkdir -p "${backup_dir}"
  if [[ -f "${tls_dir}/server.crt" ]]; then
    cp "${tls_dir}/server.crt" "${backup_dir}/server.crt"
  fi
  if [[ -f "${tls_dir}/server.key" ]]; then
    cp "${tls_dir}/server.key" "${backup_dir}/server.key"
  fi

  local new_cert
  new_cert=$(find "${tmpdir}/signcerts" -type f -name "*.pem" -print -quit 2>/dev/null || true)
  local new_key
  new_key=$(find "${tmpdir}/keystore" -type f -print -quit 2>/dev/null || true)
  local new_ca
  new_ca=$(find "${tmpdir}/tlscacerts" -type f -name "*.pem" -print -quit 2>/dev/null || true)

  if [[ -z "${new_cert}" || -z "${new_key}" ]]; then
    log_action "op=renew | component=${component} | status=failure | reason='missing enrollment output'"
    return
  fi

  cp "${new_cert}" "${tls_dir}/server.crt"
  cp "${new_key}" "${tls_dir}/server.key"
  chmod 640 "${tls_dir}/server.key"
  if [[ -n "${new_ca}" ]]; then
    cp "${new_ca}" "${tls_dir}/ca.crt"
  fi

  local serial
  serial=$(openssl x509 -in "${tls_dir}/server.crt" -noout -serial | cut -d= -f2)
  local expiry
  expiry=$(openssl x509 -in "${tls_dir}/server.crt" -noout -enddate | cut -d= -f2)

  log_action "op=renew | component=${component} | org=${org_key} | serial=${serial:-unknown} | expires='${expiry:-unknown}' | backup=${backup_dir}"

  restart_component "${container}"

  rm -rf "${tmpdir}"
  trap - RETURN
}

COMPONENTS=(
  "peer0.banka.example.com|peer|banka|banka.example.com|7054|ca-banka|peer0|peer0pw|organizations/peerOrganizations/banka.example.com/peers/peer0.banka.example.com/tls|peer0.banka.example.com,localhost|peer0.banka.example.com"
  "peer1.banka.example.com|peer|banka|banka.example.com|7054|ca-banka|peer1|peer1pw|organizations/peerOrganizations/banka.example.com/peers/peer1.banka.example.com/tls|peer1.banka.example.com,localhost|peer1.banka.example.com"
  "peer0.bankb.example.com|peer|bankb|bankb.example.com|8054|ca-bankb|peer0|peer0pw|organizations/peerOrganizations/bankb.example.com/peers/peer0.bankb.example.com/tls|peer0.bankb.example.com,localhost|peer0.bankb.example.com"
  "peer1.bankb.example.com|peer|bankb|bankb.example.com|8054|ca-bankb|peer1|peer1pw|organizations/peerOrganizations/bankb.example.com/peers/peer1.bankb.example.com/tls|peer1.bankb.example.com,localhost|peer1.bankb.example.com"
  "peer0.consortiumops.example.com|peer|consortiumops|consortiumops.example.com|10054|ca-consortiumops|peer0|peer0pw|organizations/peerOrganizations/consortiumops.example.com/peers/peer0.consortiumops.example.com/tls|peer0.consortiumops.example.com,localhost|peer0.consortiumops.example.com"
  "peer0.regulatorobserver.example.com|peer|regulatorobserver|regulatorobserver.example.com|11054|ca-regulatorobserver|peer0|peer0pw|organizations/peerOrganizations/regulatorobserver.example.com/peers/peer0.regulatorobserver.example.com/tls|peer0.regulatorobserver.example.com,localhost|peer0.regulatorobserver.example.com"
  "orderer.example.com|orderer|ordererOrg|orderer.example.com|9054|ca-orderer|orderer|ordererpw|organizations/ordererOrganizations/orderer.example.com/orderers/orderer.example.com/tls|orderer.example.com,localhost|orderer.example.com"
)

for entry in "${COMPONENTS[@]}"; do
  IFS='|' read -r component type org_key domain ca_port ca_name enroll_id enroll_secret tls_rel csr_hosts container <<< "${entry}"
  renew_component_tls "${component}" "${type}" "${org_key}" "${domain}" "${ca_port}" "${ca_name}" "${enroll_id}" "${enroll_secret}" "${tls_rel}" "${csr_hosts}" "${container}"
done

