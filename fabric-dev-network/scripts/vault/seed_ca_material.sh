#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NETWORK_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)

VAULT_ADDR=${VAULT_ADDR:-http://localhost:8200}
VAULT_TOKEN_FILE=${VAULT_TOKEN_FILE:-${NETWORK_ROOT}/vault/tokens/root.token}
VAULT_TOKEN=${VAULT_TOKEN:-}

if [[ -z "${VAULT_TOKEN}" ]]; then
  if [[ ! -f "${VAULT_TOKEN_FILE}" ]]; then
    echo "Vault token file not found at ${VAULT_TOKEN_FILE}" >&2
    exit 1
  fi
  VAULT_TOKEN=$(<"${VAULT_TOKEN_FILE}")
fi

declare -a ORGS=(
  "banka|peerOrganizations/banka.example.com|fabric-ca/banka"
  "bankb|peerOrganizations/bankb.example.com|fabric-ca/bankb"
  "consortiumops|peerOrganizations/consortiumops.example.com|fabric-ca/consortiumops"
  "regulatorobserver|peerOrganizations/regulatorobserver.example.com|fabric-ca/regulatorobserver"
  "ordererOrg|ordererOrganizations/orderer.example.com|fabric-ca/ordererOrg"
)

push_secret() {
  local org_key=$1
  local ca_path=$2

  local ca_dir="${NETWORK_ROOT}/organizations/${ca_path}"
  local cert_file="${ca_dir}/ca-cert.pem"
  local key_file
  key_file=$(find "${ca_dir}/msp/keystore" -type f -name "*_sk" -print -quit 2>/dev/null || true)

  if [[ ! -f "${cert_file}" || -z "${key_file}" ]]; then
    echo "Missing CA material for ${org_key} (cert: ${cert_file}, key: ${key_file})" >&2
    return 1
  fi

  local payload
  payload=$(python3 - <<PY
import json, pathlib
cert = pathlib.Path("${cert_file}").read_text()
key = pathlib.Path("${key_file}").read_text()
print(json.dumps({"data": {"cert_pem": cert, "key_pem": key}}))
PY
)

  curl -sS \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --header "Content-Type: application/json" \
    --request POST \
    --data "${payload}" \
    "${VAULT_ADDR}/v1/secret/data/ca/${org_key}" >/dev/null

  echo "Seeded Vault secret for ${org_key} at secret/data/ca/${org_key}"
}

for entry in "${ORGS[@]}"; do
  IFS='|' read -r org_key _ ca_dir <<< "${entry}"
  push_secret "${org_key}" "${ca_dir}"
done

