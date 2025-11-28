# Operational Notes & Follow-ups

## Running Network (CouchDB-enabled)
- The four-org network is currently **up** with CouchDB and Vault integration (`./network.sh up createChannel -c amlchannel -s couchdb -ca`).
- When you finish testing, run `./network.sh down`. Note: CA databases will be reset, requiring re-enrollment (see warning message in `network.sh`).

## Certificate Lifecycle Hardening (2025-11-20)
- **CA certificates:** Configured for 30-day expiry (`csr.ca.expiry=720h`) with 24-hour CRL windows
- **Vault integration:** CA keys are now managed via Vault (dev-only `root.token`; production must use OIDC/AppRole)
- **TLS renewal:** Automated via `scripts/certs/renew_tls.sh` (logs to `logs/cert-renewal.log`)
- **Revocation:** Tested and documented; CRL distribution workflow verified
- **Documentation:** See `docs/security/cert-lifecycle.md` and `fabric-dev-network/organizations/fabric-ca/README.md`

## Evidence Artefacts
- All snapshot tarballs, CouchDB dumps, and hash files live under `fabric-dev-network/backups/`
- Every operation is logged in `fabric-dev-network/infra/ledger-snapshots.log`, and `fabric-dev-network/infra/README.md` mirrors the exact commands, timestamps, and storage paths so auditors can trace them or sync to the target object store/S3 bucket per policy.

## Helper Script Operator Flag
- `scripts/snapshotLedger.sh` and `scripts/dumpCouchDB.sh` accept `DR_OPERATOR=<name>` (falls back to `$USER`) to tag each DR log entry with the human or automation ID responsible. Use this when multiple operators share the environment.

## CA Database Resets
- When CA databases are reset (via `network.sh down` or manual deletion), all previously issued MSP identities become invalid
- Re-enrollment required via `./network.sh up createChannel -ca -c <channel>` or `./organizations/fabric-ca/registerEnroll.sh`
- See `fabric-dev-network/organizations/fabric-ca/README.md` for detailed re-enrollment procedures
