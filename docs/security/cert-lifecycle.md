# Certificate Lifecycle Runbook

Last updated: 2025-11-20  
Owners: Security Engineering currently : (rhysconnolly@protonmail.com)  
Pending approval: Security Lead sign-off

## Validity Profiles
- **Fabric CA servers** now pin `csr.ca.expiry` to `720h` (~30 days) across all orgs (BankA, BankB, ConsortiumOps, RegulatorObserver, Orderer). CRLs expire after `24h` to keep revocation state fresh. Evidence: `fabric-dev-network/compose/compose-ca.yaml` and CA logs (e.g. `docker logs ca_banka`).
- **Operational guidance:** regenerate intermediate CA certs at least every 25 days to avoid brushing up against the 30-day ceiling; plan governance approvals one sprint ahead.
- **TLS identities (peers, orderers, gateways)** remain one-year by default but must be re-enrolled via automation every 14 days in dev/stage and every 7 days in prod. Shorter CA lifetimes keep the blast radius bounded even if TLS certs linger.

## Renewal Automation
- Script: `fabric-dev-network/scripts/certs/renew_tls.sh`
  - `-c <component>` restricts to a single peer/orderer, `-r` restarts its container after swapping certs.
  - Sources `scripts/envVar.sh`, loops through Fabric org metadata, and logs every action to `fabric-dev-network/logs/cert-renewal.log`.
  - Backups land under each component’s `tls/backup-<timestamp>` folder.
- Example (BankA peer0 dry run):
  ```bash
  cd /Users/rhys/fabric-dev/fabric-dev-network
  ./scripts/certs/renew_tls.sh -c peer0.banka.example.com
  ```
- Validation: script shellchecked via `docker run --rm -v "$PWD":/mnt koalaman/shellcheck:stable /mnt/fabric-dev-network/scripts/certs/renew_tls.sh`.
- Operational cadence:
  1. Ensure `fabric-samples/bin` is present (script will abort if `fabric-ca-client` is missing).
  2. Run `renew_tls.sh` during a green window; if `AUTO_RESTART` is disabled, follow the log’s restart hint.
  3. Attach log excerpts to the weekly infra evidence (`cert-renewal.log` is the immutable source).

## Revocation Workflow
1. **Capture serial + AKI**  
   ```bash
   FABRIC_CA_CLIENT_HOME=organizations/peerOrganizations/banka.example.com \
     ./fabric-samples/bin/fabric-ca-client certificate list \
     --caname ca-banka --id peer1 \
     --tls.certfiles organizations/fabric-ca/banka/ca-cert.pem
   ```
2. **Revoke certificate / identity**  
   ```bash
   FABRIC_CA_CLIENT_HOME=organizations/peerOrganizations/banka.example.com \
     ./fabric-samples/bin/fabric-ca-client revoke \
     --caname ca-banka \
     --revoke.serial 4bbd863cf6c693cbcfb7af59d73597a0f98aec2c \
     --revoke.aki FBC6E1B6EA69E1998395E2421B2ADC866B34673A \
     --revoke.reason keyCompromise \
     --tls.certfiles organizations/fabric-ca/banka/ca-cert.pem
   ```
   (Optional) Disable the enrollment ID entirely via `--revoke.name peer1`.
3. **Generate + distribute CRL**
   ```bash
   ./fabric-samples/bin/fabric-ca-client gencrl --caname ca-banka \
     --tls.certfiles organizations/fabric-ca/banka/ca-cert.pem
   ```
   Copy `organizations/peerOrganizations/banka.example.com/msp/crls/crl.pem` into:
   - Each BankA peer/user MSP (`.../peers/peer0.../msp/crls/`, etc.)
   - Orderer MSP (`organizations/ordererOrganizations/orderer.example.com/msp/crls/banka-crl.pem`)
4. **Reload peers/orderers**  
   `docker restart peer0.banka.example.com peer0.bankb.example.com peer0.consortiumops.example.com peer0.regulatorobserver.example.com orderer.example.com`
5. **Verification**  
   Attempting to re-enroll the revoked identity now fails (shown below) and the rejected client log is archived in `infra/README.md`.
   ```bash
   FABRIC_CA_CLIENT_HOME=organizations/peerOrganizations/banka.example.com \
     ./fabric-samples/bin/fabric-ca-client enroll \
     -u https://peer1:peer1pw@localhost:7054 --caname ca-banka \
     -M /tmp/revoked-peer1 \
     --tls.certfiles organizations/fabric-ca/banka/ca-cert.pem
   # => Error Code: 20 - Authentication failure
   ```

## Vault & Key Management
- **Architecture:** `compose/compose-ca.yaml` now launches a dev Vault instance plus `vault_agent`. CA services mount rendered keys from `/vault/rendered/<org>` and wait for the agent before starting. Binaries continue to use `bccsp: sw` but key material originates from Vault.
- **Seeding secrets:** `fabric-dev-network/scripts/vault/seed_ca_material.sh` reads the PEM files from `organizations/fabric-ca/<org>` and posts them to `secret/data/ca/<org>`. Run this whenever Vault restarts or after key rotation.
- **Agent configuration:** `fabric-dev-network/vault/config/agent.hcl` renders each key/cert to `vault/rendered/<org>/`.
- **Authentication requirements:** The checked-in `vault/tokens/root.token` exists purely for dev automation. Before staging/prod, replace the token_file method with OIDC or AppRole auth that issues short-lived tokens (<15m) plus wrapped responses. Auditors will expect proof that static root tokens are disabled in every non-dev environment.
- **Key rotation playbook:**
  1. Generate new CA key/cert pair offline (or via Vault Transit if available) and update the secret path.
  2. Flush rendered files (`rm vault/rendered/<org>/*`) and restart `vault_agent`.
  3. Restart CA containers (`docker compose -f compose/compose-ca.yaml up -d --force-recreate`).
  4. Rerun `seed_ca_material.sh` and capture logs to prove the new material loaded.
  5. Notify orderer ops before expiring the old cert; all peers must trust the rotated root.
- **Escalation:** For Vault outages >15 minutes, page Security Engineering. If Vault data is lost, rotate all CA keys immediately and re-issue org MSPs.

## References & Evidence
- `fabric-dev-network/logs/cert-renewal.log` – authoritative renewal log.
- `fabric-dev-network/infra/README.md` – evidence snapshots for Step 2 (commands, outputs, CRL locations, verification).
- `docker logs ca_<org>` – confirm CSR expiry and Vault key paths.
- Scripts shellchecked via `koalaman/shellcheck:stable` container; rerun whenever edits are made.

Approval status: awaiting Security Lead confirmation before moving this runbook into the controlled document set.

