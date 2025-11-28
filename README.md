# Fabric Dev Workspace Overview

This repository captures everything needed to maintain the regulator‑grade
Hyperledger Fabric network that underpins the AML AI Network programme. It is
intended as the primary onboarding reference for other agents or contributors.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `fabric-dev-network/` | Customised copy of Fabric's `test-network`, extended to five orgs (BankA, BankB, ConsortiumOps, RegulatorObserver, OrdererOrg). All scripts, configs, and chaincode live here. |
| `AML AI NETWORK/` | Programme documentation (playbooks, deployment considerations, personas, etc.). Review `week3-4_agent_handoff.md` for latest implementation status. |
| `context.md` | High-level brief that explains the current phase, goals, constraints, and evidence expectations. |
| `overview.txt` | Scratchpad/notes from earlier planning. |

> Fabric binaries (`fabric-dev-network/fabric-samples/bin`) are committed so
> agents do not need to re-install them for basic tasks.

## Preconditions

```bash
cd fabric-dev-network
export PATH="${PWD}/fabric-samples/bin:${PATH}"
export FABRIC_CFG_PATH="${PWD}/configtx"
```

Run those exports *once per shell* before invoking any Fabric CLI command.

## Network Bring-up (5-org topology)

1. Ensure Docker is running.
2. From `fabric-dev-network/`:

   ```bash
   docker-compose -f compose/compose-test-net.yaml up -d
   ```

   - Uses CA-issued MSP material already stored under
     `organizations/peerOrganizations/*`.
   - Starts all 5 organizations: BankA, BankB, ConsortiumOps, RegulatorObserver, OrdererOrg
   - All CAs, peers, and orderer containers will start

3. Enroll identities (if not already enrolled):

   ```bash
   ./organizations/fabric-ca/registerEnroll.sh all
   ```

4. Create channels (Week 3-4 implementation):

   The network uses three channels:
   - **model-governance** - BankA, BankB, ConsortiumOps (ModelRegistry, ContributionLedger chaincodes)
   - **sar-audit** - BankA, BankB, RegulatorObserver (SARAnchor chaincode)
   - **ops-monitoring** - ConsortiumOps only

   Channel artifacts are pre-generated in `artifacts/channels/week3-4/`. To join peers:

   ```bash
   export PATH="${PWD}/fabric-samples/bin:${PATH}"
   export FABRIC_CFG_PATH="${PWD}/fabric-samples/config"
   . scripts/envVar.sh

   # Join model-governance
   setGlobals 1 && peer channel join -b artifacts/channels/week3-4/model-governance.block
   setGlobals 2 && peer channel join -b artifacts/channels/week3-4/model-governance.block
   setGlobals 3 && peer channel join -b artifacts/channels/week3-4/model-governance.block

   # Join sar-audit
   setGlobals 1 && peer channel join -b artifacts/channels/week3-4/sar-audit.block
   setGlobals 2 && peer channel join -b artifacts/channels/week3-4/sar-audit.block
   setGlobals 4 && peer channel join -b artifacts/channels/week3-4/sar-audit.block

   # Join ops-monitoring
   setGlobals 3 && peer channel join -b artifacts/channels/week3-4/ops-monitoring.block
   ```

5. Verify channels (evidence step):

   ```bash
   for org in 1 2 3 4; do
     setGlobals $org
     peer channel list
   done
   ```

   Copy command outputs into `infra/README.md` when collecting evidence.

6. Tear down when finished:

   ```bash
   docker-compose -f compose/compose-test-net.yaml down
   ```

## Org Manifest & Evidence

- `fabric-dev-network/orgs.yaml` – single source of truth for org metadata,
  CA bindings, MSP archives, and configtx output locations.
- `infra/README.md` – living evidence log (MSP exports, channel proofs, etc.).
  Update it whenever you generate artefacts (configtxgen output, `peer channel
  list`, snapshots, etc.).

## Key Scripts

| Script | Description | Location |
| --- | --- | --- |
| `scripts/envVar.sh` | Maps org IDs to MSP IDs + localhost addresses (ensures peer CLI reaches the Docker peers). Use `setGlobals 1` for BankA, `setGlobals 2` for BankB, etc. | `fabric-dev-network/scripts/envVar.sh` |
| `organizations/fabric-ca/registerEnroll.sh` | Registers and enrolls identities for all organizations. Run with `all` argument to enroll all orgs. | `fabric-dev-network/organizations/fabric-ca/registerEnroll.sh` |
| `scripts/week3-4_channel_setup/setup_all_channels.sh` | Master script for Week 3-4 channel setup (creates all three channels). | `fabric-dev-network/scripts/week3-4_channel_setup/` |
| `scripts/createChannel.sh` | Generates channel block, joins orgs, sets anchor peers. | `fabric-dev-network/scripts/createChannel.sh` |
| `scripts/setAnchorPeer.sh` | Fetches channel config and applies anchor peer updates with correct TLS overrides. | `fabric-dev-network/scripts/setAnchorPeer.sh` |
| `scripts/snapshotLedger.sh` | Creates ledger snapshots for backup/DR purposes. | `fabric-dev-network/scripts/snapshotLedger.sh` |
| `scripts/dumpCouchDB.sh` | Exports CouchDB databases for backup. | `fabric-dev-network/scripts/dumpCouchDB.sh` |

## Backups & DR Artefacts

- **Snapshot helper**: `fabric-dev-network/scripts/snapshotLedger.sh`
  - Uses `peer snapshot submitrequest` and auto-detects the correct Docker volume (`compose_peer0.*` vs `peer0.*`).
  - Archives land under `fabric-dev-network/backups/<channel>/<org>/snapshot-<channel>-<org>-block<Block>-<ts>.tgz` with matching `.sha256`.
  - Logs every run to `fabric-dev-network/infra/ledger-snapshots.log`, including `height`, `block`, `archive`, `hash`, and `operator`.
- **CouchDB helper**: `fabric-dev-network/scripts/dumpCouchDB.sh`
  - Exports every database matching `<channel>_` (or an explicit comma-separated list) from the per-org CouchDB containers (`couchdb.<org>.example.com`) and stores the gzip+hash pair under `fabric-dev-network/backups/couchdb/<channel>/<org>/`.
  - Logs `op=couchdb-dump` entries to the same DR log with the CouchDB endpoint and operator ID.
- **Operator attribution**: both helpers honour `DR_OPERATOR=<name>` (fallback to `$USER`) so each archive/hash/log entry clearly identifies who executed the run.
- **Evidence trail**: keep `fabric-dev-network/backups/` (~112 KB for the current set) and the updated `fabric-dev-network/infra/README.md`/`infra/ledger-snapshots.log` in sync or mirror them to your regulated object store per policy.
- **Runtime reminder**: When testing is complete, run `docker-compose -f compose/compose-test-net.yaml down` before handing the environment back.

## Modifying the Network

1. Edit configs (`configtx/configtx.yaml`, `compose/compose-test-net.yaml`,
   CA configs under `organizations/fabric-ca/*`, etc.).
2. Regenerate org definitions if MSP structure changes:

   ```bash
   configtxgen -configPath configtx -printOrg BankAMSP \
     > organizations/peerOrganizations/banka.example.com/configtx.yaml
   # Repeat for BankBMSP, ConsortiumOpsMSP, RegulatorObserverMSP
   ```

3. Record commands + outputs inside `infra/README.md`.
4. Re-run network bring-up and channel join commands to validate.

## Git & Collaboration Notes

- `fabric-dev-network/` contents are tracked directly (no submodules) so every
  clone has the full network artefacts.
- `fabric-samples/` binaries are committed in `fabric-dev-network/fabric-samples/bin/` for convenience.
- Never commit private keys outside the CA directories already under version
  control; those directories are sanitised for auditors.

## Deployed Chaincodes (Week 3-4)

All chaincodes are deployed using **Chaincode-as-a-Service (CaaS)**:

| Chaincode | Channel | Status | Notes |
|-----------|---------|--------|-------|
| ModelRegistry | model-governance | ✅ Operational | Sequence 2, CaaS |
| ContributionLedger | model-governance | ✅ Operational | Sequence 2, CaaS |
| SARAnchor | sar-audit | ✅ Operational | Sequence 1, CaaS, deployed as `sar-anchor-v2` |

**Important:** SARAnchor is deployed as `sar-anchor-v2` (not `sar-anchor`) due to stale channel state. See `fabric-dev-network/chaincode/sar-anchor/README_NAMING.md` for details.

**Documentation:**
- Deployment status: `fabric-dev-network/docs/caas_deployment_progress.md`
- Smoke test results: `fabric-dev-network/docs/smoke_test_results.md`
- Chaincode naming reference: `fabric-dev-network/docs/chaincode_naming_reference.md`

## Need Help?

1. Read `context.md` for current objectives.
2. Review `AML AI NETWORK/week3-4_agent_handoff.md` for the latest implementation status.
3. Check `fabric-dev-network/docs/caas_deployment_progress.md` for chaincode deployment details.
4. Check `infra/README.md` to understand what evidence already exists.
5. When in doubt, keep the evidence trail updated and prefer extending existing
   patterns over introducing new tooling.

Happy hacking!

## Using Peer Commands

To use `peer` commands, set up the environment first:

```bash
cd fabric-dev-network
export PATH="${PWD}/fabric-samples/bin:${PATH}"
export FABRIC_CFG_PATH="${PWD}/fabric-samples/config"
. scripts/envVar.sh
```

Then use `setGlobals` to switch between organizations:
- `setGlobals 1` - BankA (BankAMSP)
- `setGlobals 2` - BankB (BankBMSP)
- `setGlobals 3` - ConsortiumOps (ConsortiumOpsMSP)
- `setGlobals 4` - RegulatorObserver (RegulatorObserverMSP)

Example:
```bash
setGlobals 1
peer channel list
peer lifecycle chaincode querycommitted --channelID model-governance
```

## Chaincode-as-a-service

All chaincodes in this network are deployed using **Chaincode-as-a-Service (CaaS)**. This means:
- Chaincode runs in separate Docker containers
- No Docker socket access required from peers
- Easier debugging and development
- Better suited for Kubernetes deployments

**Current Status:**
- ✅ All three chaincodes deployed as CaaS
- ✅ All CaaS containers running and operational
- ✅ See `fabric-dev-network/docs/caas_deployment_progress.md` for details

To learn more about CaaS, see the [tutorial](./CHAINCODE_AS_A_SERVICE_TUTORIAL.md). It is expected that this will move to augment the tutorial in the [Hyperledger Fabric ReadTheDocs](https://hyperledger-fabric.readthedocs.io/en/release-2.4/cc_service.html)


## Podman Support

*Note - podman support should be considered experimental but the following has been reported to work with podman 4.1.1 on Mac. If you wish to use podman a LinuxVM is recommended.*

To use podman instead of docker, set the `CONTAINER_CLI` environment variable:

```bash
export CONTAINER_CLI=podman
docker-compose -f compose/compose-test-net.yaml up -d
```

Note: CaaS chaincode deployment works with podman since it doesn't require Docker socket access. 


