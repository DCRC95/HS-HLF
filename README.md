# Fabric Dev Workspace Overview

This repository captures everything needed to maintain the regulator‑grade
Hyperledger Fabric network that underpins the AML AI Network programme. It is
intended as the primary onboarding reference for other agents or contributors.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `fabric-dev-network/` | Customised copy of Fabric’s `test-network`, extended to four peer orgs (BankA, BankB, ConsortiumOps, RegulatorObserver) plus the orderer org. All scripts and configs live here. |
| `AML AI NETWORK/` | Programme documentation (playbooks, deployment considerations, personas, etc.). Always review `week1_2.md` before making infra changes. |
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

## Network Bring-up (4-org topology)

1. Ensure Docker is running.
2. From `fabric-dev-network/`:

   ```bash
   ./network.sh up createChannel -c amlchannel -ca
   ```

   - Uses CA-issued MSP material already stored under
     `organizations/peerOrganizations/*`.
   - Creates channel `amlchannel` with all four peer orgs.
   - Sets anchor peers according to `configtx/configtx.yaml`.

3. Verify each org can see the channel (evidence step):

   ```bash
   export PATH="${PWD}/fabric-samples/bin:${PATH}"
   export FABRIC_CFG_PATH="${PWD}/fabric-samples/config"
   . scripts/envVar.sh

   for org in 1 2 3 4; do
     setGlobals $org
     peer channel list
   done
   ```

   Copy command outputs into `infra/README.md` when collecting evidence.

4. Tear down when finished:

   ```bash
   ./network.sh down
   ```

## Org Manifest & Evidence

- `fabric-dev-network/orgs.yaml` – single source of truth for org metadata,
  CA bindings, MSP archives, and configtx output locations.
- `infra/README.md` – living evidence log (MSP exports, channel proofs, etc.).
  Update it whenever you generate artefacts (configtxgen output, `peer channel
  list`, snapshots, etc.).

## Key Scripts

| Script | Description |
| --- | --- |
| `network.sh` | Orchestrates bring-up/down, channel creation, chaincode deployment. |
| `scripts/createChannel.sh` | Generates channel block, joins all four orgs, sets anchor peers. |
| `scripts/envVar.sh` | Maps org IDs to MSP IDs + localhost addresses (ensures peer CLI reaches the Docker peers). |
| `scripts/setAnchorPeer.sh` | Fetches channel config and applies anchor peer updates with correct TLS overrides. |

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
- **Runtime reminder**: The CouchDB-enabled network is often left running for validation. When testing is complete, run `./network.sh down` (expect the current warning about `peer0.consortiumops`; see `Fixes.md` for context) before handing the environment back.

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
4. Re-run `./network.sh up createChannel -c amlchannel -ca` to validate.

## Git & Collaboration Notes

- `fabric-dev-network/` contents are tracked directly (no submodules) so every
  clone has the full network artefacts.
- `fabric-samples/` is ignored – if it is required, run
  `./fabric-dev-network/install-fabric.sh` to download upstream samples/binaries.
- Never commit private keys outside the CA directories already under version
  control; those directories are sanitised for auditors.

## Need Help?

1. Read `context.md` for current objectives.
2. Review `AML AI NETWORK/week1_2.md` for the active playbook.
3. Check `infra/README.md` to understand what evidence already exists.
4. When in doubt, keep the evidence trail updated and prefer extending existing
   patterns over introducing new tooling.

Happy hacking!

# Running the test network

You can use the `./network.sh` script to stand up a simple Fabric test network. The test network has two peer organizations with one peer each and a single node raft ordering service. You can also use the `./network.sh` script to create channels and deploy chaincode. For more information, see [Using the Fabric test network](https://hyperledger-fabric.readthedocs.io/en/latest/test_network.html). The test network is being introduced in Fabric v2.0 as the long term replacement for the `first-network` sample.

If you are planning to run the test network with consensus type BFT then please pass `-bft` flag as input to the `network.sh` script when creating the channel. This sample also supports the use of consensus type BFT and CA together.
That is to create a network use:
```bash
./network.sh up -bft
```

To create a channel use:

```bash
./network.sh createChannel -bft
```

To restart a running network use:

```bash
./network.sh restart -bft
```

Note that running the createChannel command will start the network, if it is not already running.

Before you can deploy the test network, you need to follow the instructions to [Install the Samples, Binaries and Docker Images](https://hyperledger-fabric.readthedocs.io/en/latest/install.html) in the Hyperledger Fabric documentation.

## Using the Peer commands

The `setOrgEnv.sh` script can be used to set up the environment variables for the organizations, this will help to be able to use the `peer` commands directly.

First, ensure that the peer binaries are on your path, and the Fabric Config path is set assuming that you're in the `test-network` directory.

```bash
 export PATH=$PATH:$(realpath ../bin)
 export FABRIC_CFG_PATH=$(realpath ../config)
```

You can then set up the environment variables for each organization. The `./setOrgEnv.sh` command is designed to be run as follows.

```bash
export $(./setOrgEnv.sh Org2 | xargs)
```

(Note bash v4 is required for the scripts.)

You will now be able to run the `peer` commands in the context of Org2. If a different command prompt, you can run the same command with Org1 instead.
The `setOrgEnv` script outputs a series of `<name>=<value>` strings. These can then be fed into the export command for your current shell.

## Chaincode-as-a-service

To learn more about how to use the improvements to the Chaincode-as-a-service please see this [tutorial](./test-network/../CHAINCODE_AS_A_SERVICE_TUTORIAL.md). It is expected that this will move to augment the tutorial in the [Hyperledger Fabric ReadTheDocs](https://hyperledger-fabric.readthedocs.io/en/release-2.4/cc_service.html)


## Podman

*Note - podman support should be considered experimental but the following has been reported to work with podman 4.1.1 on Mac. If you wish to use podman a LinuxVM is recommended.*

Fabric's `install-fabric.sh` script has been enhanced to support using `podman` to pull down images and tag them rather than docker. The images are the same, just pulled differently. Simply specify the 'podman' argument when running the `install-fabric.sh` script. 

Similarly, the `network.sh` script has been enhanced so that it can use `podman` and `podman-compose` instead of docker. Just set the environment variable `CONTAINER_CLI` to `podman` before running the `network.sh` script:

```bash
CONTAINER_CLI=podman ./network.sh up
````

As there is no Docker-Daemon when using podman, only the `./network.sh deployCCAAS` command will work. Following the Chaincode-as-a-service Tutorial above should work. 


