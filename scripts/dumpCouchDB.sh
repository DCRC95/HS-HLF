#!/usr/bin/env bash

set -euo pipefail

# Helper script to export CouchDB state for a peer org, compress the dump,
# hash it, and append evidence to the DR log.
#
# Usage (from fabric-dev-network root):
#   ./scripts/dumpCouchDB.sh <channel> <org-id> [db-list]
# Example:
#   ./scripts/dumpCouchDB.sh amlchannel 1
#
# When db-list is omitted, the script queries CouchDB for all databases whose
# name starts with "<channel>_" and exports each one.

ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOTDIR}"

export PATH="${ROOTDIR}/fabric-samples/bin:${PATH}"
export FABRIC_CFG_PATH="${ROOTDIR}/configtx"
export TEST_NETWORK_HOME="${ROOTDIR}"

. "${ROOTDIR}/scripts/envVar.sh"

CHANNEL_NAME="${1:-amlchannel}"
ORG_ID="${2:-1}"
EXPLICIT_DB_LIST="${3:-}"

COUCHDB_USERNAME="${COUCHDB_USERNAME:-admin}"
COUCHDB_PASSWORD="${COUCHDB_PASSWORD:-adminpw}"
COUCHDB_HOST="${COUCHDB_HOST:-localhost}"

BACKUP_ROOT="${ROOTDIR}/backups/couchdb"
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

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fatalln "Missing required command '$1'. Please install it before running this script."
  fi
}

require_command curl
require_command gzip
require_command shasum

case "${ORG_ID}" in
  1)
    ORG_NAME="banka"
    COUCH_PORT="${COUCHDB_PORT_BANKA:-5984}"
    COUCH_SERVICE="couchdb.banka.example.com"
    ;;
  2)
    ORG_NAME="bankb"
    COUCH_PORT="${COUCHDB_PORT_BANKB:-6984}"
    COUCH_SERVICE="couchdb.bankb.example.com"
    ;;
  3)
    ORG_NAME="consortiumops"
    COUCH_PORT="${COUCHDB_PORT_CONSORTIUMOPS:-7984}"
    COUCH_SERVICE="couchdb.consortiumops.example.com"
    ;;
  4)
    ORG_NAME="regulatorobserver"
    COUCH_PORT="${COUCHDB_PORT_REGULATOROBSERVER:-8984}"
    COUCH_SERVICE="couchdb.regulatorobserver.example.com"
    ;;
  *)
    errorln "Unsupported ORG_ID '${ORG_ID}'. Expected 1 (BankA), 2 (BankB), 3 (ConsortiumOps), or 4 (RegulatorObserver)."
    exit 1
    ;;
esac

COUCH_URL="http://${COUCHDB_USERNAME}:${COUCHDB_PASSWORD}@${COUCHDB_HOST}:${COUCH_PORT}"

fetch_db_list() {
  local response
  response="$(curl -sSf "${COUCH_URL}/_all_dbs")"

  local matcher="${CHANNEL_NAME}_"

  if [ -n "${EXPLICIT_DB_LIST}" ]; then
    IFS=',' read -r -a selected <<< "${EXPLICIT_DB_LIST}"
    printf "%s\n" "${selected[@]}"
    return 0
  fi

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "${response}" | jq -r --arg prefix "${matcher}" '.[] | select(startswith($prefix))'
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    fatalln "Either 'jq' or 'python3' is required to parse CouchDB database names."
  fi

  printf '%s' "${response}" | python3 - "$matcher" <<'PY'
import json
import sys

data = json.load(sys.stdin)
prefix = sys.argv[1]
for name in data:
    if name.startswith(prefix):
        print(name)
PY
}

DATABASES=()
while IFS= read -r db_name; do
  if [ -n "${db_name}" ]; then
    DATABASES+=("${db_name}")
  fi
done < <(fetch_db_list)

if [ ${#DATABASES[@]} -eq 0 ]; then
  warnln "No CouchDB databases matched channel '${CHANNEL_NAME}' for org '${ORG_NAME}'. Nothing to export."
  exit 0
fi

TIMESTAMP="$(timestamp_utc)"

ARCHIVE_BASE="${BACKUP_ROOT}/${CHANNEL_NAME}/${ORG_NAME}"
mkdir -p "${ARCHIVE_BASE}"

mkdir -p "$(dirname "${DR_LOG}")"

for DB_NAME in "${DATABASES[@]}"; do
  ARCHIVE_NAME="couchdb-${CHANNEL_NAME}-${ORG_NAME}-${DB_NAME}-${TIMESTAMP}.json.gz"
  ARCHIVE_PATH="${ARCHIVE_BASE}/${ARCHIVE_NAME}"
  HASH_PATH="${ARCHIVE_PATH}.sha256"

  infoln "Exporting CouchDB database '${DB_NAME}' for org '${ORG_NAME}' from ${COUCH_URL}"

  curl -sSf "${COUCH_URL}/${DB_NAME}/_all_docs?include_docs=true" | gzip > "${ARCHIVE_PATH}"

  shasum -a 256 "${ARCHIVE_PATH}" > "${HASH_PATH}"

  REL_ARCHIVE_PATH="backups/couchdb/${CHANNEL_NAME}/${ORG_NAME}/${ARCHIVE_NAME}"
  REL_HASH_PATH="${REL_ARCHIVE_PATH}.sha256"

  {
    echo "${TIMESTAMP} | op=couchdb-dump | org=${ORG_NAME} | channel=${CHANNEL_NAME} | db=${DB_NAME} | archive=${REL_ARCHIVE_PATH} | sha256=${REL_HASH_PATH} | couch=${COUCH_SERVICE} | operator=${OPERATOR_NAME}"
  } >> "${DR_LOG}"

  successln "Captured CouchDB dump for DB '${DB_NAME}'. Archive: ${REL_ARCHIVE_PATH}"
done

