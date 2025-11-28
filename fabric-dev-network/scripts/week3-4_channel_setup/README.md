# Week 3-4 Channel Setup Scripts

**Author:** Week 3-4 Implementation  
**Date:** 2025-11-28  
**Purpose:** Scripts for implementing Week 3-4 "Channels & Policies" sprint tasks

## Overview

This directory contains scripts for:
1. Verifying MSP material for all organizations
2. Generating channel artifacts (model-governance, sar-audit, ops-monitoring)
3. Creating channels and joining peers
4. Configuring endorsement and ACL policies
5. Documenting all changes

## Scripts

### `verify_msp.sh`
Verifies MSP material for all organizations including:
- Certificate chains (admin, CA, TLS CA)
- OU separation configuration
- Anchor peer configuration
- Peer and orderer certificates

**Usage:**
```bash
./scripts/week3-4_channel_setup/verify_msp.sh
```

**Output:**
- `logs/msp_audit_week3.md` - Detailed MSP audit report
- `logs/week3-4_channels.log` - Execution log

### `generate_channels.sh`
Generates channel genesis blocks and creation transactions for:
- `model-governance` - Banks + ConsortiumOps
- `sar-audit` - Banks + RegulatorObserver
- `ops-monitoring` - ConsortiumOps only

**Usage:**
```bash
./scripts/week3-4_channel_setup/generate_channels.sh
```

**Prerequisites:**
- Network must be up (orderer running)
- `configtxgen` must be in PATH
- `configtx/configtx.yaml` must contain channel profiles

**Output:**
- `artifacts/channels/week3-4/*.block` - Channel genesis blocks
- `artifacts/channels/week3-4/*.tx` - Channel creation transactions
- `artifacts/channels/week3-4/*.metadata.json` - Channel metadata

### `create_and_join_channels.sh`
Creates channels and joins peers:
- Creates channels from ConsortiumOps admin
- Joins appropriate peers to each channel
- Updates anchor peers

**Usage:**
```bash
./scripts/week3-4_channel_setup/create_and_join_channels.sh
```

**Prerequisites:**
- Network must be up (orderer and peers running)
- Channel artifacts must be generated first
- `peer` CLI must be in PATH

**Output:**
- Channel creation and join logs in `logs/week3-4_channels.log`

### `configure_policies.sh`
Documents endorsement and ACL policies:
- ModelRegistry: Requires BankA AND BankB endorsements
- ContributionLedger: Requires BankA AND BankB endorsements
- SARAnchor: Requires BankA OR BankB endorsements, RegulatorObserver read-only

**Usage:**
```bash
./scripts/week3-4_channel_setup/configure_policies.sh
```

**Output:**
- `docs/policy_updates/week3-4/endorsement_policies.md`
- `docs/policy_updates/week3-4/policy_changes.json`

## Execution Order

1. **Verify MSPs:**
   ```bash
   ./scripts/week3-4_channel_setup/verify_msp.sh
   ```

2. **Generate Channel Artifacts:**
   ```bash
   ./scripts/week3-4_channel_setup/generate_channels.sh
   ```

3. **Create Channels and Join Peers:**
   ```bash
   ./scripts/week3-4_channel_setup/create_and_join_channels.sh
   ```

4. **Configure Policies:**
   ```bash
   ./scripts/week3-4_channel_setup/configure_policies.sh
   ```

## Master Script

Run all steps in sequence:
```bash
./scripts/week3-4_channel_setup/setup_all_channels.sh
```

## Private Data Collections

Private data collection configurations are stored in:
- `chaincode/SARAnchor/collections/sar_collections_config.json`

Collections defined:
- `sarHashes` - SAR hash references (banks only)
- `sarMetadata` - SAR metadata (banks + regulator read)
- `sensitiveAlerts` - Sensitive alert payloads (banks only, 365 day TTL)

## Notes

- All scripts log to `logs/week3-4_channels.log`
- All artifacts are stored in `artifacts/channels/week3-4/`
- Policy documentation is in `docs/policy_updates/week3-4/`
- Actual endorsement policies are applied during chaincode definition
- ACL policies are enforced at channel configuration level

## Troubleshooting

### Channel creation fails
- Ensure orderer is running: `docker ps | grep orderer`
- Check orderer logs: `docker logs orderer.example.com`
- Verify channel transaction exists: `ls -l artifacts/channels/week3-4/*.tx`

### Peer join fails
- Ensure peer is running: `docker ps | grep peer`
- Check peer logs: `docker logs peer0.banka.example.com`
- Verify channel block exists: `ls -l artifacts/channels/week3-4/*.block`

### Configtxgen errors
- Verify FABRIC_CFG_PATH points to configtx directory
- Check configtx.yaml syntax: `configtxgen -printOrg BankAMSP`
- Ensure all MSP directories exist

