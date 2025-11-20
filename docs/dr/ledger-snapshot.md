## Ledger Snapshot & Disaster Recovery – Policy & Runbook (Phase 1, Step 3)

### 1. Purpose & Scope

This document defines the **ledger snapshot and backup strategy** for the AML AI consortium dev network (`fabric-dev-network`) and serves as the basis for test and production DR design.

- **Scope (Phase 1)**:
  - Orderer and peer ledgers for the `amlchannel` application channel.
  - State databases (CouchDB where enabled).
  - Evidence artefacts and operator procedures suitable for regulator‑grade review.

### 2. Business Continuity Targets

- **Recovery Point Objective (RPO)**:
  - **Target**: 15 minutes.
  - **Interpretation**: In the event of a catastrophic failure, the consortium accepts a maximum of 15 minutes of potential ledger/state loss, assuming:
    - Daily ledger snapshots for each peer.
    - Weekly CouchDB exports for stateful applications.
- **Recovery Time Objective (RTO)**:
  - **Target**: 1 hour.
  - **Interpretation**: For a single‑site failure of the consortium dev network, the goal is to restore a consistent `amlchannel` view and basic chaincode query within 60 minutes, assuming infrastructure and keys are available.

These values are aligned with the expectations in `AML AI NETWORK/deployment-considerations.md` for:
- Regulator‑visible audit trails.
- Timely resumption of analytic pipelines and SAR review workflows.

### 3. Storage & Retention Strategy

- **Primary storage (cloud object store – conceptual)**:
  - Design target is an **encrypted S3‑class bucket** with:
    - Object Lock / WORM for snapshot archives and CouchDB exports.
    - Lifecycle policies for tiering and eventual deletion.
    - KMS‑managed keys and strict IAM policies per consortium member.
  - **Implementation note (dev network)**:
    - The current dev environment writes artefacts under:
      - `backups/<channel>/<org>/` – snapshot and CouchDB archives.
      - `infra/ledger-snapshots.log` – DR log with hashes.
    - Operators are expected to sync these to the target object store for higher environments.

- **Secondary storage (offline / dual‑control)**:
  - For production, selected snapshot archives and hashes SHOULD be exported to:
    - Offline encrypted media, or
    - A Vault‑managed secure archive location.
  - Dual‑control procedures (two‑person rule) apply to decryption keys and restore authorisations.

### 4. Snapshot Automation – Peers & Orderer

#### 4.1 Command pattern

For each peer organisation, snapshots are triggered via the Fabric CLI using the existing `setGlobals` mappings:

```bash
export PATH="${PWD}/fabric-samples/bin:${PATH}"
export FABRIC_CFG_PATH="${PWD}/fabric-samples/config"
. scripts/envVar.sh

# Example: snapshot amlchannel on BankA (ORG=1)
setGlobals 1
HEIGHT=$(peer channel getinfo -c amlchannel | jq -r '.height')
BLOCK=$((HEIGHT-1))
peer snapshot submitrequest \
  --channelID amlchannel \
  --blockNumber "${BLOCK}" \
  --peerAddress "${CORE_PEER_ADDRESS}" \
  --tlsRootCertFile "${CORE_PEER_TLS_ROOTCERT_FILE}"
```

Snapshots are emitted under `/var/hyperledger/production/snapshots/completed/<channel>/<blockNumber>` and then exported by the helper script described below.

#### 4.2 Helper script – `scripts/snapshotLedger.sh`

To minimise operator error and keep evidence consistent, the dev network provides:

- **Script**: `scripts/snapshotLedger.sh`
- **Responsibility**:
  - Trigger a `peer node snapshot save` for a given **channel** and **org**.
  - Package the resulting snapshot into a compressed archive under `backups/`.
  - Compute and store a SHA‑256 hash alongside the archive.
  - Append a structured DR log entry (`op=peer-ledger-snapshot`) to `infra/ledger-snapshots.log`.

**Usage** (run from `fabric-dev-network` root):

```bash
./scripts/snapshotLedger.sh amlchannel 1      # BankA
./scripts/snapshotLedger.sh amlchannel 2      # BankB
./scripts/snapshotLedger.sh amlchannel 3      # ConsortiumOps
./scripts/snapshotLedger.sh amlchannel 4      # RegulatorObserver
```

The script:
- Uses `setGlobals` to select the correct MSP and peer endpoint, derives the ledger height, and targets block `height - 1`.
- Submits `peer snapshot submitrequest` with explicit `--peerAddress` and `--tlsRootCertFile` flags, then waits for `/var/hyperledger/production/snapshots/completed/<channel>/<block>` to appear.
- Detects whether Docker named the volume `compose_peer0.<org>.example.com` or `peer0.<org>.example.com` and uses the correct mount automatically.
- Writes archives under:
  - `backups/<channel>/<org-name>/snapshot-<channel>-<org-name>-block<BlockNumber>-<timestamp>.tgz`
  - Hashes: `.tgz.sha256` alongside the archive.
- Logs to:
  - `infra/ledger-snapshots.log`
- Includes the operator ID in every log line. Override via `DR_OPERATOR=<name>` (falls back to the shell `USER`).

#### 4.4 Couch-aware peer configuration

When the network is started with `-s couchdb`, `compose/compose-couch.yaml` now provisions a dedicated CouchDB container per peer:

- `couchdb.banka.example.com` (port `5984`)
- `couchdb.bankb.example.com` (port `6984`)
- `couchdb.consortiumops.example.com` (port `7984`)
- `couchdb.regulatorobserver.example.com` (port `8984`)

Each peer’s environment automatically points `CORE_LEDGER_STATE_COUCHDBCONFIG_*` to the matching CouchDB service, keeping credentials (`admin` / `adminpw`) aligned with the sample defaults.

#### 4.3 Orderer snapshots

For the orderer:

- Snapshots MAY be created using `orderer` tooling or volume‑level backups of:
  - The `orderer.example.com` volume (mapped to `/var/hyperledger/production/orderer`).
- Initial focus in Phase 1 is on **peer ledger snapshots** for `amlchannel`; orderer snapshot procedures will be aligned once the channel topology is stable and production DR storage is selected.

### 5. CouchDB Dumps (State Database)

Where peers use CouchDB, weekly exports provide a richer view of world state for audit and analytics.

- **Targets**:
  - Each peer‑scoped CouchDB instance (`couchdb.<org>.example.com`).
  - Databases named following Fabric conventions: typically `<channel>_<chaincode-name>`.

- **Automation** – `scripts/dumpCouchDB.sh`:

```bash
# Weekly dump for BankA (auto-detects DBs starting with amlchannel_)
./scripts/dumpCouchDB.sh amlchannel 1

# Dump explicit comma-separated DB list for ConsortiumOps
./scripts/dumpCouchDB.sh amlchannel 3 amlchannel_modelregistry,amlchannel_saranchor
```

- Behaviour:
  - Resolves the CouchDB host/port for the selected org (`couchdb.<org>.example.com` with host ports 5984/6984/7984/8984).
  - Queries `/_all_dbs` and exports every database matching `<channel>_` unless an explicit list is supplied.
  - Writes compressed exports under `backups/couchdb/<channel>/<org>/couchdb-<channel>-<org>-<db>-<timestamp>.json.gz`.
  - Produces `.sha256` hash files and appends `op=couchdb-dump` entries to `infra/ledger-snapshots.log`.
  - Accepts the same `DR_OPERATOR` override used by `snapshotLedger.sh`.

### 6. Integrity Hashing & DR Log

- **Hashing**:
  - Every archive generated by `snapshotLedger.sh` is hashed using:
    - `shasum -a 256 <archive> > <archive>.sha256`
  - The hash file is stored alongside the archive under `backups/`.

- **DR log**:
  - File: `infra/ledger-snapshots.log`
  - Format (one line per operation):

    ```text
    <timestamp> | op=<operation> | org=<org-name> | channel=<channel> | [height|block|db]=... | archive=<relative-path> | sha256=<relative-path> | operator=<id>
    ```

  - `op=peer-ledger-snapshot` entries capture ledger snapshots (with `height=<ledger-height>` and `block=<snapshot-block>`), while `op=couchdb-dump` lines capture CouchDB exports (`db=<db-name>`).
  - The **block height** is derived immediately after the snapshot using:

    ```bash
    peer channel getinfo -c <channel>
    ```

    and is treated as an approximate height for dev; in production, snapshots would be taken during planned maintenance windows to remove ambiguity.

### 7. Restore Runbook (High‑Level)

The following procedure assumes:
- The consortium has access to:
  - Snapshot archives and hashes (from object store or offline media).
  - Valid MSP material and TLS keys.
  - Replacement infrastructure for peers, orderers, and CouchDB instances.

**Steps (per peer)**:

1. **Prepare environment**
   - Recreate peer containers using the standard `network.sh up createChannel -c amlchannel -ca` path, or an equivalent IaC‑driven deployment.
   - Stop the affected peer container to avoid writes during restore.
2. **Place snapshot in ledger path**
   - Copy the chosen snapshot archive and its `.sha256` file into the dev network root.
   - Verify integrity:
     ```bash
     shasum -a 256 -c backups/<channel>/<org-name>/snapshot-*.tgz.sha256
     ```
   - Extract the archive into the peer volume so that contents land under:
     - `/var/hyperledger/production/snapshots/completed/<channel>/<blockNumber>/...`
3. **Restart peer and reconcile**
   - Restart the peer container.
   - Allow Fabric to reconcile to the snapshot and re‑sync from the orderer.
4. **Restore CouchDB (if used)**
   - For each relevant CouchDB DB:
     - Import from the JSON export (or restore from a volume snapshot).
   - Ensure channel height and state are consistent.
5. **Validate**
   - Use `setGlobals` for the restored org and run:
     ```bash
     peer channel getinfo -c amlchannel
     peer channel list
     ```
   - Run a basic chaincode query (for the primary registry/ledger chaincode once deployed).
6. **Record evidence**
   - Append a **restore event** entry to `infra/ledger-snapshots.log` with:
     - Timestamp, org, channel, height, archive used, operator, approvals.
   - Capture console logs and validations in `infra/README.md` under the DR section.

### 8. DR Rehearsal & Approvals

- **Rehearsal schedule**:
  - **Quarterly** DR exercise targeting:
    - At least one peer org per rehearsal (rotating between BankA, BankB, ConsortiumOps, RegulatorObserver).
    - At least one scenario where a fresh environment is bootstrapped from snapshots and CouchDB exports.
- **Approvals**:
  - Each rehearsal and any live restore require:
    - Security Lead approval.
    - Relevant consortium member approvals (e.g. BankA/BankB data owners).
  - Evidence (approvals, commands, outputs) are recorded in:
    - `infra/README.md` (summary).
    - `infra/ledger-snapshots.log` (structured log).


