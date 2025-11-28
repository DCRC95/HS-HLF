# Dev Deployment Guide - Week 3-4 Chaincode

**Author:** Week 3-4 Implementation  
**Date:** 2025-11-28  
**Purpose:** Dev deployment guide for chaincode modules (phase_1_plan_details.md:62)

## Prerequisites

1. Network must be running: `./network.sh up`
2. Channels must be created (model-governance, sar-audit)
3. Fabric binaries in PATH (peer, configtxgen)
4. Node.js >= 18.0.0

## Deployment Steps

### 1. ModelRegistry Chaincode

**Channel:** model-governance  
**Endorsement Policy:** `AND('BankAMSP.peer', 'BankBMSP.peer')`

```bash
cd fabric-dev-network
./chaincode/model-registry/scripts/deploy.sh
```

**Expected Output:**
- Chaincode packaged
- Installed on BankA, BankB, ConsortiumOps peers
- Approved by all orgs
- Committed to model-governance channel

### 2. ContributionLedger Chaincode

**Channel:** model-governance  
**Endorsement Policy:** `AND('BankAMSP.peer', 'BankBMSP.peer')`

```bash
# Similar deployment script (to be created)
cd fabric-dev-network
./chaincode/contribution-ledger/scripts/deploy.sh
```

### 3. SARAnchor Chaincode

**Channel:** sar-audit  
**Endorsement Policy:** `OR('BankAMSP.peer', 'BankBMSP.peer')`  
**Private Collections:** sarHashes, sarMetadata, sensitiveAlerts

```bash
# Similar deployment script with collection config
cd fabric-dev-network
./chaincode/sar-anchor/scripts/deploy.sh \
  --collections-config chaincode/SARAnchor/collections/sar_collections_config.json
```

## Smoke Tests

### ModelRegistry

```bash
# Register a model (requires BankA AND BankB endorsement)
setGlobals 1
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.orderer.example.com \
  -C model-governance \
  -n model-registry \
  --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
  --peerAddresses localhost:9051 --tlsRootCertFiles $PEER0_ORG2_CA \
  -c '{"function":"registerModel","Args":["aml-model-v1","1.0.0","hash123...","{}","sig"]}' \
  --tls --cafile $ORDERER_CA

# Query model
peer chaincode query \
  -C model-governance \
  -n model-registry \
  -c '{"function":"getModel","Args":["aml-model-v1","1.0.0"]}'
```

### SARAnchor

```bash
# Anchor SAR (BankA OR BankB can submit)
setGlobals 1
peer chaincode invoke \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.orderer.example.com \
  -C sar-audit \
  -n sar-anchor \
  --peerAddresses localhost:7051 --tlsRootCertFiles $PEER0_ORG1_CA \
  -c '{"function":"anchorSar","Args":["sar-001","hash123...","{}","2025-11-28T12:00:00Z"]}' \
  --tls --cafile $ORDERER_CA

# Query SAR metadata (regulator can read)
setGlobals 4
peer chaincode query \
  -C sar-audit \
  -n sar-anchor \
  -c '{"function":"getSarMetadata","Args":["sar-001"]}'
```

## Transaction IDs

All transaction IDs are logged in:
- `logs/week3-4_chaincode.log`
- Deployment script output

## Channel Config Blocks

Channel configuration blocks are referenced in:
- `channel-artifacts/<channel>.block`
- Block numbers recorded in deployment logs

## Troubleshooting

### Chaincode Installation Fails - npm/husky Errors
**Symptom:** `npm error command failed command sh -c husky install` during Docker build  
**Root Cause:** `"prepare": "husky install"` script in package.json runs during npm install but requires .git directory  
**Solution:** ✅ Fixed - Removed prepare script from all chaincode package.json files:
- `chaincode/model-registry/package.json`
- `chaincode/contribution-ledger/package.json`
- `chaincode/sar-anchor/package.json`

**Note:** Husky is for git hooks and not needed in production chaincode containers.

### Chaincode Installation Fails - Package Path
- Verify chaincode path exists
- Check package format
- Ensure packaging from chaincode root directory (not src subdirectory) to include package.json

### Chaincode Installation Fails - General
- Check peer logs: `docker logs peer0.banka.example.com`
- Verify Docker build completes successfully
- Check npm dependencies are installed

### Approval Fails
- Verify org admin certificates
- Check endorsement policy format
- Ensure all required orgs are in channel

### Commit Fails
- Verify all orgs have approved
- Check peer connectivity
- Verify channel exists

## References

- Phase 1 Plan: `phase_1_plan_details.md:62`
- Channel Configuration: `configtx/configtx.yaml`
- Endorsement Policies: `docs/policy_updates/week3-4/endorsement_policies.md`

