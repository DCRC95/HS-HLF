## MSP Hardening Evidence – 2025-11-19

### Anchor Peers & Org Definitions (Step 2.5 - Completed 2025-11-19)
- Updated `configtx/configtx.yaml` with anchor peers for `BankAMSP`, `BankBMSP`, `ConsortiumOpsMSP`, and `RegulatorObserverMSP`.
- Generated serialized org definitions using `configtxgen -printOrg` (Step 2.5):
  ```bash
  export PATH="${PWD}/fabric-samples/bin:${PATH}"
  export FABRIC_CFG_PATH="${PWD}/configtx"
  
  configtxgen -configPath configtx -printOrg BankAMSP \
    > organizations/peerOrganizations/banka.example.com/configtx.yaml
  configtxgen -configPath configtx -printOrg BankBMSP \
    > organizations/peerOrganizations/bankb.example.com/configtx.yaml
  configtxgen -configPath configtx -printOrg ConsortiumOpsMSP \
    > organizations/peerOrganizations/consortiumops.example.com/configtx.yaml
  configtxgen -configPath configtx -printOrg RegulatorObserverMSP \
    > organizations/peerOrganizations/regulatorobserver.example.com/configtx.yaml
  ```
  **Result**: All four org definition files generated successfully without errors:
  - `organizations/peerOrganizations/banka.example.com/configtx.yaml` (10KB)
  - `organizations/peerOrganizations/bankb.example.com/configtx.yaml` (10KB)
  - `organizations/peerOrganizations/consortiumops.example.com/configtx.yaml` (11KB)
  - `organizations/peerOrganizations/regulatorobserver.example.com/configtx.yaml` (11KB)
  
  **Status**: Step 2.5 complete. Week 1–2 Plan Item 2 marked as "done".

### MSP Archive Exports (Step 6)
- Stored sanitized tarballs (private keys excluded) under `infra/msp-archives/`:
  - `banka-msp.tar.gz`
  - `bankb-msp.tar.gz`
  - `consortiumops-msp.tar.gz`
  - `regulatorobserver-msp.tar.gz`
  - `orderer-msp.tar.gz`

### CLI Context / Peer Channel Evidence (2025-11-19)
- **Network Bring-Up**: Successfully executed `./network.sh up createChannel -c amlchannel -ca`
  - All 4 peer organisations (BankA, BankB, ConsortiumOps, RegulatorObserver) successfully joined channel `amlchannel`
  - Channel created using `ChannelUsingRaft` profile from `configtx/configtx.yaml`
  - All CA-issued MSPs properly enrolled and configured

- **Peer Channel List Evidence** (2025-11-19):
  ```bash
  export PATH=${PWD}/fabric-samples/bin:${PATH}
  export FABRIC_CFG_PATH=${PWD}/fabric-samples/config
  . scripts/envVar.sh
  
  # BankA (ORG=1)
  setGlobals 1
  peer channel list
  # Output: Channels peers has joined: amlchannel
  
  # BankB (ORG=2)
  setGlobals 2
  peer channel list
  # Output: Channels peers has joined: amlchannel
  
  # ConsortiumOps (ORG=3)
  setGlobals 3
  peer channel list
  # Output: Channels peers has joined: amlchannel
  
  # RegulatorObserver (ORG=4)
  setGlobals 4
  peer channel list
  # Output: Channels peers has joined: amlchannel
  ```
  
  **Result**: All four peer organisations can successfully list the `amlchannel`, confirming:
  - MSP context switching works correctly for all orgs
  - All peers have successfully joined the channel
  - Network is operational and ready for chaincode deployment

### Network Alignment Updates (2025-11-19)
- Updated `network.sh` to use 4-org CA registration functions
- Updated `createChannel.sh` to join all 4 peer orgs and set anchor peers
- Fixed `envVar.sh` to use localhost addresses for peer CLI commands
- Updated `compose-test-net.yaml` to include all 4 peer services
- Fixed `ccp-generate.sh` to generate connection profiles for all 4 orgs
- Fixed orderer TLS hostname references in `orderer.sh`, `setAnchorPeer.sh`, and `configUpdate.sh`

## Ledger Snapshot & DR Evidence – Step 3 (In Progress)

### Snapshot Policy & Runbook
- Added `docs/dr/ledger-snapshot.md` as the canonical policy and runbook for:
  - RPO/RTO targets (15 min / 1 hr for Phase 1 dev network).
  - Peer/orderer snapshot expectations.
  - CouchDB export pattern.
  - Restore procedure and DR rehearsal schedule.

### Snapshot Automation – `scripts/snapshotLedger.sh`
- Helper script to create and export peer ledger snapshots:

  ```bash
  # From fabric-dev-network root
  ./scripts/snapshotLedger.sh amlchannel 1   # BankA
  ./scripts/snapshotLedger.sh amlchannel 2   # BankB
  ./scripts/snapshotLedger.sh amlchannel 3   # ConsortiumOps
  ./scripts/snapshotLedger.sh amlchannel 4   # RegulatorObserver
  ```

- Behaviour:
  - Uses `setGlobals <ORG_ID>` from `scripts/envVar.sh` to bind the Fabric CLI to the correct MSP and peer endpoint.
  - Triggers `peer node snapshot save` into the peer ledger path:
    - `/var/hyperledger/production/snapshots/<channel>/<timestamp>`
  - Exports the snapshot using the named peer volume and a BusyBox helper container:
    - `peer0.banka.example.com`
    - `peer0.bankb.example.com`
    - `peer0.consortiumops.example.com`
    - `peer0.regulatorobserver.example.com`
  - Writes compressed archives and hashes under:
    - `backups/<channel>/<org-name>/snapshot-<channel>-<org-name>-<timestamp>.tgz`
    - `backups/<channel>/<org-name>/snapshot-<channel>-<org-name>-<timestamp>.tgz.sha256`
  - Derives an approximate block height via `peer channel getinfo -c <channel>` and records it with each snapshot.
  - Logs include `op=peer-ledger-snapshot` plus the operator ID (override via `DR_OPERATOR=<name>` when running the script).

### CouchDB Automation – `scripts/dumpCouchDB.sh`
- New helper for weekly state exports when the network runs with CouchDB (`./network.sh ... -s couchdb`):

  ```bash
  ./scripts/dumpCouchDB.sh amlchannel 1                # BankA – auto-detect DBs prefixed amlchannel_
  ./scripts/dumpCouchDB.sh amlchannel 3 amlchannel_cc  # ConsortiumOps – explicit DB list
  ```

- Behaviour:
  - Resolves the correct CouchDB container & host port per org (`couchdb.<org>.example.com` at 5984/6984/7984/8984).
  - Queries `/_all_dbs`, filters names that start with `<channel>_`, or accepts a comma-separated list passed as the third argument.
  - Writes compressed exports under `backups/couchdb/<channel>/<org>/couchdb-<channel>-<org>-<db>-<timestamp>.json.gz` and produces `.sha256` hash files.
  - Appends `op=couchdb-dump` entries to `infra/ledger-snapshots.log` with `db=<db-name>` and the operator ID.

### CouchDB Compose Alignment
- `compose/compose-couch.yaml` now provisions one CouchDB container per peer (`couchdb.banka.example.com`, `couchdb.bankb.example.com`, `couchdb.consortiumops.example.com`, `couchdb.regulatorobserver.example.com`) and maps each peer’s `CORE_LEDGER_STATE_COUCHDBCONFIG_*` env vars to the correct service. Host ports are exposed (5984/6984/7984/8984) so the dump script can reach each database via `localhost`.

### DR Log – `infra/ledger-snapshots.log`
- Each snapshot operation appends a line to `infra/ledger-snapshots.log`:

  ```text
  <timestamp> | op=<peer-ledger-snapshot|couchdb-dump> | org=<org-name> | channel=<channel> | height|db=... | archive=<relative-path> | sha256=<relative-path> | operator=<id>
  ```

- This log is the primary evidence trail for:
  - When snapshots or CouchDB exports were taken.
  - Which organisation/channel/height (or DB) they correspond to.
  - Where the archive and hash are stored under the repo.

### Snapshot Execution – 2025-11-20
- Network brought up with CouchDB via:

  ```bash
  ./network.sh up createChannel -c amlchannel -s couchdb
  ```

- Captured fresh snapshots for all peer orgs:

  ```bash
  DR_OPERATOR=automated-step3 ./scripts/snapshotLedger.sh amlchannel 1
  DR_OPERATOR=automated-step3 ./scripts/snapshotLedger.sh amlchannel 2
  DR_OPERATOR=automated-step3 ./scripts/snapshotLedger.sh amlchannel 3
  DR_OPERATOR=automated-step3 ./scripts/snapshotLedger.sh amlchannel 4
  ```

- Results:
  - BankA → `backups/amlchannel/banka/snapshot-amlchannel-banka-block0-20251120T123516Z.tgz`
  - BankB → `backups/amlchannel/bankb/snapshot-amlchannel-bankb-block0-20251120T123533Z.tgz`
  - ConsortiumOps → `backups/amlchannel/consortiumops/snapshot-amlchannel-consortiumops-block0-20251120T123601Z.tgz`
  - RegulatorObserver → `backups/amlchannel/regulatorobserver/snapshot-amlchannel-regulatorobserver-block0-20251120T123634Z.tgz`
  - Each archive has a matching `.sha256` file and a corresponding `op=peer-ledger-snapshot` entry in `infra/ledger-snapshots.log` (height=1, block=0, operator `automated-step3`).

### CouchDB Dumps – 2025-11-20
- Weekly dump workflow exercised for all four peers:

  ```bash
  DR_OPERATOR=automated-step3 ./scripts/dumpCouchDB.sh amlchannel 1
  DR_OPERATOR=automated-step3 ./scripts/dumpCouchDB.sh amlchannel 2
  DR_OPERATOR=automated-step3 ./scripts/dumpCouchDB.sh amlchannel 3
  DR_OPERATOR=automated-step3 ./scripts/dumpCouchDB.sh amlchannel 4
  ```

- For each org, the script exported the CouchDB databases `amlchannel_` and `amlchannel__lifecycle` and stored them under `backups/couchdb/amlchannel/<org>/` with `.sha256` companions.
- `infra/ledger-snapshots.log` now includes `op=couchdb-dump` entries capturing org, channel, DB name, archive path, CouchDB endpoint, and operator ID.

### Next Evidence to Capture
- With the network running (`./network.sh up createChannel -c amlchannel -ca`):
  - Run at least one snapshot for each org using `snapshotLedger.sh`.
  - Capture:
    - Console output from each run.
    - Resulting archives under `backups/`.
    - Contents of `infra/ledger-snapshots.log`.
  - Append a dated sub‑section here summarising the first successful snapshot set (org, channel, height, archive paths).

