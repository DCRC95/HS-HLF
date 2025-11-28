# SARAnchor Chaincode Naming

## Current Deployment Name: `sar-anchor-v2`

The SARAnchor chaincode is deployed and operational as **`sar-anchor-v2`** on the `sar-audit` channel.

## Why `sar-anchor-v2` Instead of `sar-anchor`?

The original `sar-anchor` name has **stale private data state** in the channel ledger from a previous failed deployment attempt. This stale state prevents deploying with the `sar-anchor` name.

### Error Encountered

When attempting to deploy as `sar-anchor`, the following error occurs:

```
Error: proposal failed with status: 500 - failed to invoke backing implementation of 'ApproveChaincodeDefinitionForMyOrg': 
could not fetch uncommitted definition: could not query metadata for namespace namespaces/sar-anchor#1: 
GET_STATE failed: transaction ID: ...: private data matching public hash version is not available. 
Public hash version = {BlockNum: 1, TxNum: 0}, Private data version = <nil>
```

### Root Cause

During a previous deployment attempt, chaincode with private data collections was partially deployed. The channel ledger contains metadata referencing private data that was never successfully committed, creating stale state that blocks future deployments with the same name.

### Solution

Using `sar-anchor-v2` as the chaincode name bypasses the stale state and allows successful deployment with all collections configured correctly.

## Current Status

- **Chaincode Name:** `sar-anchor-v2`
- **Channel:** `sar-audit`
- **Status:** ✅ Deployed and operational
- **Collections:** All three collections configured (sarHashes, sarMetadata, sensitiveAlerts)
- **Package ID:** `sar-anchor_1.0:bc7edc6d5cc1705a8de905264df0a2cc11bb3d5c44f0db9928a44b7fda9f7ef1`

## Usage

When invoking the SARAnchor chaincode, use the name `sar-anchor-v2`:

```bash
peer chaincode invoke \
  -C sar-audit \
  -n sar-anchor-v2 \
  ...
```

## Future Options

### Option 1: Continue Using `sar-anchor-v2` (Recommended)

- **Pros:** No disruption, chaincode is working
- **Cons:** Name doesn't match original design
- **Action:** Update all documentation and scripts to reference `sar-anchor-v2`

### Option 2: Recreate sar-audit Channel

- **Pros:** Can use original `sar-anchor` name
- **Cons:** 
  - Requires recreating the channel
  - All chaincodes on sar-audit channel must be redeployed
  - Loss of any existing channel state
- **Action:** 
  1. Stop network
  2. Delete sar-audit channel artifacts
  3. Recreate channel
  4. Redeploy all chaincodes

## Related Files

- Deployment documentation: `docs/caas_deployment_progress.md`
- Collections config: `collections/sar_collections_config.json`
- Connection config: `connection/connection.json`

## Date

- **Issue Discovered:** 2025-11-28
- **Workaround Implemented:** 2025-11-28
- **Documentation Updated:** 2025-11-28

