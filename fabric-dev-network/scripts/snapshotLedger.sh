#!/usr/bin/env bash

set -euo pipefail

# Simple helper to trigger a Fabric ledger snapshot for a given channel/org,
# export it from the peer volume as a tarball, hash it, and append a DR log entry.
#
# Usage (from fabric-dev-network root):
#   ./scripts/snapshotLedger.sh <channel> <org-id>
# Example:
#   ./scripts/snapshotLedger.sh amlchannel 1   # BankA

ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOTDIR}"

export PATH="${ROOTDIR}/fabric-samples/bin:${PATH}"
export FABRIC_CFG_PATH="${ROOTDIR}/fabric-samples/config"
export TEST_NETWORK_HOME="${ROOTDIR}"

. "${ROOTDIR}/scripts/envVar.sh"

CHANNEL_NAME="${1:-amlchannel}"
ORG_ID="${2:-1}"

BACKUP_ROOT="${ROOTDIR}/backups"
DR_LOG="${ROOTDIR}/infra/ledger-snapshots.log"

resolve_operator() {
  if [ -n "${DR_OPERATOR:-}" ]; then
    echo "${DR_OPERATOR}"
  elif [ -n "${SNAPSHOT_OPERATOR:-}" ]; then
    echo "${SNAPSHOT_OPERATOR}"
  elif [ -n "${OPERATOR:-}" ]; then
    echo "${OPERATOR}"
  elif [ -n "${USER:-}" ]; then
    echo "${USER}"
  else
    whoami 2>/dev/null || echo "unknown"
  fi
}

OPERATOR_NAME="$(resolve_operator)"

timestamp_utc() {
  date -u +"%Y%m%dT%H%M%SZ"
}

snapshot_exists() {
  ${CONTAINER_CLI} run --rm \
    -v "${PEER_VOLUME}:/var/hyperledger/production" \
    busybox test -d "/var/hyperledger/production/${SNAPSHOT_RELATIVE_DIR}"
}

wait_for_snapshot() {
  local attempt=0
  local max_attempts=30
  while [ "${attempt}" -lt "${max_attempts}" ]; do
    if snapshot_exists; then
      return 0
    fi
    sleep 2
    attempt=$((attempt + 1))
  done
  fatalln "Snapshot directory not created for block ${SNAPSHOT_BLOCK} on ${ORG_NAME} after waiting ${max_attempts} attempts."
}

CONTAINER_CLI="${CONTAINER_CLI:-docker}"
SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

resolve_volume_name() {
  local base_name="$1"
  local default_name="${base_name}"
  local compose_name="compose_${base_name}"
  if ${CONTAINER_CLI} volume inspect "${compose_name}" >/dev/null 2>&1; then
    echo "${compose_name}"
  else
    echo "${default_name}"
  fi
}

case "${ORG_ID}" in
  1)
    ORG_NAME="banka"
    PEER_VOLUME="$(resolve_volume_name "peer0.banka.example.com")"
    ;;
  2)
    ORG_NAME="bankb"
    PEER_VOLUME="$(resolve_volume_name "peer0.bankb.example.com")"
    ;;
  3)
    ORG_NAME="consortiumops"
    PEER_VOLUME="$(resolve_volume_name "peer0.consortiumops.example.com")"
    ;;
  4)
    ORG_NAME="regulatorobserver"
    PEER_VOLUME="$(resolve_volume_name "peer0.regulatorobserver.example.com")"
    ;;
  *)
    errorln "Unsupported ORG_ID '${ORG_ID}'. Expected 1 (BankA), 2 (BankB), 3 (ConsortiumOps), or 4 (RegulatorObserver)."
    exit 1
    ;;
esac

infoln "Starting ledger snapshot for channel '${CHANNEL_NAME}', org '${ORG_NAME}' (ORG_ID=${ORG_ID})"

setGlobals "${ORG_ID}"

BLOCK_HEIGHT=""
if peer channel getinfo -c "${CHANNEL_NAME}" > /tmp/ledger-snapshot-getinfo.json 2>/dev/null; then
  if command -v jq >/dev/null 2>&1; then
    BLOCK_HEIGHT="$(jq -r '.height' /tmp/ledger-snapshot-getinfo.json 2>/dev/null || echo "")"
  else
    BLOCK_HEIGHT="$(grep -E '"height"' /tmp/ledger-snapshot-getinfo.json | sed -E 's/[^0-9]*([0-9]+).*/\1/' || echo "")"
  fi
fi

if [[ -z "${BLOCK_HEIGHT}" || ! "${BLOCK_HEIGHT}" =~ ^[0-9]+$ ]]; then
  BLOCK_HEIGHT="1"
fi

BLOCK_HEIGHT_INT=$((BLOCK_HEIGHT))
if [ "${BLOCK_HEIGHT_INT}" -gt 0 ]; then
  SNAPSHOT_BLOCK=$((BLOCK_HEIGHT_INT - 1))
else
  SNAPSHOT_BLOCK=0
fi
SNAPSHOT_RELATIVE_DIR="snapshots/completed/${CHANNEL_NAME}/${SNAPSHOT_BLOCK}"

if snapshot_exists; then
  infoln "Snapshot directory already present for block ${SNAPSHOT_BLOCK}; skipping request."
else
  infoln "Requesting snapshot at block ${SNAPSHOT_BLOCK} (ledger height ${BLOCK_HEIGHT_INT})"

  set -x
  peer snapshot submitrequest \
    --channelID "${CHANNEL_NAME}" \
    --blockNumber "${SNAPSHOT_BLOCK}" \
    --peerAddress "${CORE_PEER_ADDRESS}" \
    --tlsRootCertFile "${CORE_PEER_TLS_ROOTCERT_FILE}"
  { set +x; } 2>/dev/null

  wait_for_snapshot
fi

ARCHIVE_DIR="${BACKUP_ROOT}/${CHANNEL_NAME}/${ORG_NAME}"
mkdir -p "${ARCHIVE_DIR}"

TIMESTAMP="$(timestamp_utc)"
ARCHIVE_NAME="snapshot-${CHANNEL_NAME}-${ORG_NAME}-block${SNAPSHOT_BLOCK}-${TIMESTAMP}.tgz"

infoln "Exporting snapshot directory '${SNAPSHOT_RELATIVE_DIR}' from volume '${PEER_VOLUME}' to '${ARCHIVE_DIR}/${ARCHIVE_NAME}'"

set -x
${CONTAINER_CLI} run --rm \
  -v "${PEER_VOLUME}:/var/hyperledger/production" \
  -v "${ARCHIVE_DIR}:/backups" \
  busybox sh -c "cd /var/hyperledger/production && tar -czf /backups/${ARCHIVE_NAME} ${SNAPSHOT_RELATIVE_DIR}"
{ set +x; } 2>/dev/null

ARCHIVE_PATH="${ARCHIVE_DIR}/${ARCHIVE_NAME}"
HASH_PATH="${ARCHIVE_PATH}.sha256"

infoln "Computing SHA-256 for '${ARCHIVE_PATH}'"

set -x
shasum -a 256 "${ARCHIVE_PATH}" > "${HASH_PATH}"
{ set +x; } 2>/dev/null

REL_ARCHIVE_PATH="backups/${CHANNEL_NAME}/${ORG_NAME}/${ARCHIVE_NAME}"
REL_HASH_PATH="${REL_ARCHIVE_PATH}.sha256"

mkdir -p "$(dirname "${DR_LOG}")"

{
  echo "${TIMESTAMP} | op=peer-ledger-snapshot | org=${ORG_NAME} | channel=${CHANNEL_NAME} | height=${BLOCK_HEIGHT_INT} | block=${SNAPSHOT_BLOCK} | archive=${REL_ARCHIVE_PATH} | sha256=${REL_HASH_PATH} | operator=${OPERATOR_NAME}"
} >> "${DR_LOG}"

successln "Snapshot completed for channel='${CHANNEL_NAME}', org='${ORG_NAME}'"
successln "Archive: ${REL_ARCHIVE_PATH}"
successln "Hash:    ${REL_HASH_PATH}"
successln "Logged entry in ${DR_LOG}"


