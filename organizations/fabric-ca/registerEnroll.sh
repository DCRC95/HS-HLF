#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd)
cd "${ROOT_DIR}"

BIN_DIR="${ROOT_DIR}/fabric-samples/bin"
if [[ -d "${BIN_DIR}" && ":$PATH:" != *":${BIN_DIR}:"* ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

if [ -f "scripts/utils.sh" ]; then
  # shellcheck disable=SC1091
  . "scripts/utils.sh"
else
  infoln() {
    echo -e "\033[1m$*\033[0m"
  }
fi

function ensure_ca_material() {
  local ca_folder=$1
  local cert_path="organizations/fabric-ca/${ca_folder}/ca-cert.pem"
  if [ ! -f "${cert_path}" ]; then
    echo "CA certificate not found at ${cert_path}. Ensure CA containers are running." >&2
    exit 1
  fi
}

function write_node_ous() {
  local target_msp_dir=$1
  local ca_port=$2
  local ca_name=$3
  cat <<EOF > "${target_msp_dir}/config.yaml"
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/localhost-${ca_port}-${ca_name}.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/localhost-${ca_port}-${ca_name}.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/localhost-${ca_port}-${ca_name}.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/localhost-${ca_port}-${ca_name}.pem
    OrganizationalUnitIdentifier: orderer
EOF
}

function enroll_peer_org() {
  local org_key=$1          # banka
  local msp_id=$2           # BankAMSP
  local domain=$3           # banka.example.com
  local ca_name=$4          # ca-banka
  local ca_port=$5          # 7054
  local peer_list=$6        # "peer0 peer1"
  local user_label=${7:-user1}
  local admin_label=${8:-admin}
  local auditor_label=${9:-auditor1}

  local org_path="${ROOT_DIR}/organizations/peerOrganizations/${domain}"
  local ca_cert="${ROOT_DIR}/organizations/fabric-ca/${org_key}/ca-cert.pem"
  ensure_ca_material "${org_key}"

  infoln "Enrolling CA admin for ${msp_id}"
  mkdir -p "${org_path}"
  export FABRIC_CA_CLIENT_HOME="${org_path}"
  set -x
  fabric-ca-client enroll -u "https://admin:adminpw@localhost:${ca_port}" --caname "${ca_name}" --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null

  write_node_ous "${org_path}/msp" "${ca_port}" "${ca_name}"

  mkdir -p "${org_path}/msp/tlscacerts"
  cp "${ca_cert}" "${org_path}/msp/tlscacerts/ca.crt"

  mkdir -p "${org_path}/tlsca"
  cp "${ca_cert}" "${org_path}/tlsca/tlsca.${domain}-cert.pem"

  mkdir -p "${org_path}/ca"
  cp "${ca_cert}" "${org_path}/ca/ca.${domain}-cert.pem"

  for peer in ${peer_list}; do
    infoln "Registering ${peer} for ${msp_id}"
    set -x
    fabric-ca-client register --caname "${ca_name}" --id.name "${peer}" --id.secret "${peer}pw" --id.type peer --tls.certfiles "${ca_cert}"
    { set +x; } 2>/dev/null
  done

  infoln "Registering ${user_label} for ${msp_id}"
  set -x
  fabric-ca-client register --caname "${ca_name}" --id.name "${user_label}" --id.secret "${user_label}pw" --id.type client --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null

  infoln "Registering ${admin_label} for ${msp_id}"
  set -x
  fabric-ca-client register --caname "${ca_name}" --id.name "${admin_label}" --id.secret "${admin_label}pw" --id.type admin --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null

  infoln "Registering ${auditor_label} for ${msp_id}"
  set -x
  fabric-ca-client register --caname "${ca_name}" --id.name "${auditor_label}" --id.secret "${auditor_label}pw" --id.type client --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null

  for peer in ${peer_list}; do
    local peer_host="${peer}.${domain}"
    infoln "Generating MSP for ${peer_host}"
    set -x
    fabric-ca-client enroll -u "https://${peer}:${peer}pw@localhost:${ca_port}" --caname "${ca_name}" -M "${org_path}/peers/${peer_host}/msp" --tls.certfiles "${ca_cert}"
    { set +x; } 2>/dev/null
    cp "${org_path}/msp/config.yaml" "${org_path}/peers/${peer_host}/msp/config.yaml"

    infoln "Generating TLS certs for ${peer_host}"
    set -x
    fabric-ca-client enroll -u "https://${peer}:${peer}pw@localhost:${ca_port}" --caname "${ca_name}" -M "${org_path}/peers/${peer_host}/tls" --enrollment.profile tls --csr.hosts "${peer_host}" --csr.hosts localhost --tls.certfiles "${ca_cert}"
    { set +x; } 2>/dev/null
    cp "${org_path}/peers/${peer_host}/tls/tlscacerts/"* "${org_path}/peers/${peer_host}/tls/ca.crt"
    cp "${org_path}/peers/${peer_host}/tls/signcerts/"* "${org_path}/peers/${peer_host}/tls/server.crt"
    cp "${org_path}/peers/${peer_host}/tls/keystore/"* "${org_path}/peers/${peer_host}/tls/server.key"
  done

  infoln "Generating user MSP for ${user_label}"
  set -x
  fabric-ca-client enroll -u "https://${user_label}:${user_label}pw@localhost:${ca_port}" --caname "${ca_name}" -M "${org_path}/users/User1@${domain}/msp" --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null
  cp "${org_path}/msp/config.yaml" "${org_path}/users/User1@${domain}/msp/config.yaml"

  infoln "Generating admin MSP for ${msp_id}"
  set -x
  fabric-ca-client enroll -u "https://${admin_label}:${admin_label}pw@localhost:${ca_port}" --caname "${ca_name}" -M "${org_path}/users/Admin@${domain}/msp" --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null
  cp "${org_path}/msp/config.yaml" "${org_path}/users/Admin@${domain}/msp/config.yaml"

  infoln "Generating auditor MSP for ${msp_id}"
  set -x
  fabric-ca-client enroll -u "https://${auditor_label}:${auditor_label}pw@localhost:${ca_port}" --caname "${ca_name}" -M "${org_path}/users/Auditor@${domain}/msp" --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null
  cp "${org_path}/msp/config.yaml" "${org_path}/users/Auditor@${domain}/msp/config.yaml"
}

function create_banka() {
  enroll_peer_org "banka" "BankAMSP" "banka.example.com" "ca-banka" 7054 "peer0 peer1" "user1" "bankaadmin" "auditor1"
}

function create_bankb() {
  enroll_peer_org "bankb" "BankBMSP" "bankb.example.com" "ca-bankb" 8054 "peer0 peer1" "user1" "bankbadmin" "auditor1"
}

function create_consortiumops() {
  enroll_peer_org "consortiumops" "ConsortiumOpsMSP" "consortiumops.example.com" "ca-consortiumops" 10054 "peer0" "user1" "consortiumopsadmin" "auditor1"
}

function create_regulatorobserver() {
  enroll_peer_org "regulatorobserver" "RegulatorObserverMSP" "regulatorobserver.example.com" "ca-regulatorobserver" 11054 "peer0" "user1" "regulatorobserveradmin" "auditor1"
}

function create_orderer_org() {
  local domain="orderer.example.com"
  local orderer_path="${ROOT_DIR}/organizations/ordererOrganizations/${domain}"
  local ca_cert="${ROOT_DIR}/organizations/fabric-ca/ordererOrg/ca-cert.pem"
  ensure_ca_material "ordererOrg"

  infoln "Enrolling orderer CA admin"
  mkdir -p "${orderer_path}"
  export FABRIC_CA_CLIENT_HOME="${orderer_path}"
  set -x
  fabric-ca-client enroll -u https://admin:adminpw@localhost:9054 --caname ca-orderer --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null

  write_node_ous "${orderer_path}/msp" 9054 "ca-orderer"

  mkdir -p "${orderer_path}/msp/tlscacerts"
  cp "${ca_cert}" "${orderer_path}/msp/tlscacerts/tlsca.${domain}-cert.pem"

  mkdir -p "${orderer_path}/tlsca"
  cp "${ca_cert}" "${orderer_path}/tlsca/tlsca.${domain}-cert.pem"

  mkdir -p "${orderer_path}/ca"
  cp "${ca_cert}" "${orderer_path}/ca/ca.${domain}-cert.pem"

  local orderers=("orderer")
  for ord in "${orderers[@]}"; do
    local ord_host="${ord}.${domain}"
    infoln "Registering ${ord_host}"
    set -x
    fabric-ca-client register --caname ca-orderer --id.name "${ord}" --id.secret "${ord}pw" --id.type orderer --tls.certfiles "${ca_cert}"
    { set +x; } 2>/dev/null

    infoln "Generating MSP for ${ord_host}"
    set -x
    fabric-ca-client enroll -u "https://${ord}:${ord}pw@localhost:9054" --caname ca-orderer -M "${orderer_path}/orderers/${ord_host}/msp" --tls.certfiles "${ca_cert}"
    { set +x; } 2>/dev/null
    cp "${orderer_path}/msp/config.yaml" "${orderer_path}/orderers/${ord_host}/msp/config.yaml"

    infoln "Generating TLS certs for ${ord_host}"
    set -x
    fabric-ca-client enroll -u "https://${ord}:${ord}pw@localhost:9054" --caname ca-orderer -M "${orderer_path}/orderers/${ord_host}/tls" --enrollment.profile tls --csr.hosts "${ord_host}" --csr.hosts localhost --tls.certfiles "${ca_cert}"
    { set +x; } 2>/dev/null
    cp "${orderer_path}/orderers/${ord_host}/tls/tlscacerts/"* "${orderer_path}/orderers/${ord_host}/tls/ca.crt"
    cp "${orderer_path}/orderers/${ord_host}/tls/signcerts/"* "${orderer_path}/orderers/${ord_host}/tls/server.crt"
    cp "${orderer_path}/orderers/${ord_host}/tls/keystore/"* "${orderer_path}/orderers/${ord_host}/tls/server.key"
  done

  infoln "Registering orderer admin"
  set -x
  fabric-ca-client register --caname ca-orderer --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null

  infoln "Generating orderer admin MSP"
  set -x
  fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:9054 --caname ca-orderer -M "${orderer_path}/users/Admin@${domain}/msp" --tls.certfiles "${ca_cert}"
  { set +x; } 2>/dev/null
  cp "${orderer_path}/msp/config.yaml" "${orderer_path}/users/Admin@${domain}/msp/config.yaml"
}

function usage() {
  cat <<EOF
Usage: ./organizations/fabric-ca/registerEnroll.sh [banka|bankb|consortiumops|regulator|orderer|all]
EOF
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  MODE=${1:-all}
  case "${MODE}" in
    banka) create_banka ;;
    bankb) create_bankb ;;
    consortiumops) create_consortiumops ;;
    regulator) create_regulatorobserver ;;
    orderer) create_orderer_org ;;
    all)
      create_banka
      create_bankb
      create_consortiumops
      create_regulatorobserver
      create_orderer_org
      ;;
    *)
      usage
      exit 1
      ;;
  esac
fi
