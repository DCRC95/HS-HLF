# Operational Notes & Follow-ups

## Running Network (CouchDB-enabled)
- The four-org network is currently **up** with CouchDB (`./network.sh up createChannel -c amlchannel -s couchdb`).
- When you finish testing, run `./network.sh down`. Expect the existing warning about `peer0.consortiumops.example.com` because the legacy BFT compose file still references `org1/org2`; this is tracked as a follow-up (see below).

## Evidence Artefacts
- All snapshot tarballs, CouchDB dumps, and hash files live under `fabric-dev-network/backups/` (≈112 KB after the latest run).
- Every operation is logged in `fabric-dev-network/infra/ledger-snapshots.log`, and `fabric-dev-network/infra/README.md` mirrors the exact commands, timestamps, and storage paths so auditors can trace them or sync to the target object store/S3 bucket per policy.

## Helper Script Operator Flag
- `scripts/snapshotLedger.sh` and `scripts/dumpCouchDB.sh` accept `DR_OPERATOR=<name>` (falls back to `$USER`) to tag each DR log entry with the human or automation ID responsible. Use this when multiple operators share the environment.

## Known Gap
- `./network.sh down` still emits `service "peer0.consortiumops.example.com" has neither an image nor a build context specified` because `compose-bft-test-net.yaml` retains the upstream `org1/org2` definitions. We should align the BFT compose artefacts with the four-org naming in a follow-up cleanup.

