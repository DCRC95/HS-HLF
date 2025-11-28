# Orderer Consensus Issue: Certificate Mismatch

**Date:** 2025-11-28  
**Issue:** Orderer reports "Found myself in 0 channels" - certificate mismatch in EtcdRaft consenter configuration  
**Status:** Root cause identified, solution documented

## Problem

After regenerating the orderer TLS certificate to include both `orderer.example.com` and `orderer.orderer.example.com`, the orderer cannot recognize itself in channel configurations because:

1. **Channel genesis blocks** have the **old certificate** embedded in the EtcdRaft consenter configuration
2. **Orderer's current certificate** is the **new certificate** (with both hostnames)
3. **EtcdRaft identifies orderers by certificate** - if certificates don't match, orderer doesn't recognize itself
4. Result: "Found myself in 0 channels out of 4" and "channel is not serviced by me"

## Root Cause

- Orderer TLS certificate was regenerated to fix hostname mismatch
- New certificate hash doesn't match old certificate in channel configurations
- Orderer reads channel blocks from disk, sees old certificate, doesn't match its own
- EtcdRaft consensus layer rejects all requests because orderer doesn't recognize itself

## Solution Options

### Option 1: Regenerate Channel Genesis Blocks (Recommended for Dev)
Since channels are empty (no chaincode deployed):

1. **Regenerate channel transactions** with new certificate:
   ```bash
   # configtx.yaml already points to correct certificate path
   configtxgen -profile ModelGovernanceChannel -outputCreateChannelTx artifacts/channels/week3-4/model-governance.tx -channelID model-governance
   configtxgen -profile SARAuditChannel -outputCreateChannelTx artifacts/channels/week3-4/sar-audit.tx -channelID sar-audit
   configtxgen -profile OpsMonitoringChannel -outputCreateChannelTx artifacts/channels/week3-4/ops-monitoring.tx -channelID ops-monitoring
   ```

2. **Delete channel data from orderer**:
   ```bash
   docker stop orderer.example.com
   docker exec orderer.example.com rm -rf /var/hyperledger/production/orderer/chains/model-governance
   docker exec orderer.example.com rm -rf /var/hyperledger/production/orderer/chains/sar-audit
   docker exec orderer.example.com rm -rf /var/hyperledger/production/orderer/chains/ops-monitoring
   ```

3. **Recreate channels** using new genesis blocks:
   ```bash
   ./scripts/week3-4_channel_setup/create_and_join_channels.sh
   ```

4. **Restart orderer** - it will initialize from new genesis blocks

### Option 2: Update Channel Configuration (Complex)
Update EtcdRaft consenter configuration in existing channels:
- Requires config update transaction
- Orderer won't accept update because it doesn't recognize itself (chicken-and-egg)
- Would need to use orderer admin API or manual intervention

### Option 3: Revert Certificate Change (Not Recommended)
- Revert to old certificate
- Loses the permanent fix for hostname mismatch
- Would need to fix hostname issue differently

## Current Status

- ✅ Orderer certificate includes both hostnames (permanent fix)
- ✅ Channel Endpoints updated to correct address
- ❌ EtcdRaft consenter config still has old certificate
- ❌ Orderer cannot service channels

## Next Steps

**Recommended:** Regenerate channel genesis blocks and recreate channels (Option 1). This is cleanest for dev environment since channels are empty.

**Note:** This issue only affects channels created before the certificate was regenerated. Future channels will work correctly because configtx.yaml points to the correct certificate.

