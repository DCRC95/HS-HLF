# Orderer Certificate Fix - Final Solution

## Problem Summary

The orderer cannot service any channels because:
1. The orderer's TLS certificate was updated to include `orderer.orderer.example.com`
2. The channel configurations (including system channel) still have the old certificate in the EtcdRaft consenter configuration
3. The orderer identifies itself by certificate, so it doesn't recognize itself as a consenter
4. This creates a circular dependency: we can't update channels because the orderer doesn't service them

## Root Cause

- Channels were created with `orderer.example.com` in the consenter certificate
- Orderer certificate was regenerated to include `orderer.orderer.example.com`
- Channel configurations still reference the old certificate
- Orderer cannot update channels because it doesn't recognize itself as a consenter

## Solution: Regenerate System Genesis Block

Since this is a development environment, the cleanest solution is to:

1. **Stop the network**
2. **Clear orderer channel data** (preserves certificates and MSP)
3. **Regenerate system genesis block** with the new certificate
4. **Regenerate channel genesis blocks** with the new certificate
5. **Restart the network**

## Implementation Steps

### Step 1: Stop Network
```bash
cd /Users/rhys/fabric-dev/fabric-dev-network
docker-compose -f compose/compose-test-net.yaml down
```

### Step 2: Clear Orderer Channel Data
```bash
# Remove only channel data, keep certificates
rm -rf system-genesis-block/genesis.block
# Orderer will recreate channel data on startup
```

### Step 3: Regenerate System Genesis Block
```bash
export PATH=${PWD}/fabric-samples/bin:${PWD}/../bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx

# Generate system genesis block with new certificate
configtxgen -profile FiveOrgOrdererGenesis -channelID system-channel -outputBlock system-genesis-block/genesis.block
```

### Step 4: Regenerate Channel Transactions
```bash
# Regenerate channel transactions (already done, but verify)
configtxgen -profile ModelGovernanceChannel -outputCreateChannelTx artifacts/channels/week3-4/model-governance.tx -channelID model-governance
configtxgen -profile SARAuditChannel -outputCreateChannelTx artifacts/channels/week3-4/sar-audit.tx -channelID sar-audit
configtxgen -profile OpsMonitoringChannel -outputCreateChannelTx artifacts/channels/week3-4/ops-monitoring.tx -channelID ops-monitoring
```

### Step 5: Restart Network
```bash
docker-compose -f compose/compose-test-net.yaml up -d
```

### Step 6: Recreate Channels
```bash
. scripts/envVar.sh
setGlobals 3
peer channel create -o localhost:7050 --ordererTLSHostnameOverride orderer.orderer.example.com -c model-governance -f artifacts/channels/week3-4/model-governance.tx --tls --cafile "$ORDERER_CA" --outputBlock artifacts/channels/week3-4/model-governance.block

# Join peers to channels (if needed)
# ... (standard channel join process)
```

## Why This Works

- System genesis block is regenerated with the **new certificate** in the consenter configuration
- When the orderer starts, it reads the system genesis block and recognizes itself
- Channels created from this point forward will have the correct certificate
- The orderer will be able to service all channels

## Permanent Fixes Already Applied

1. ✅ **Orderer Certificate**: Updated to include both `orderer.orderer.example.com` and `orderer.example.com` in SAN
2. ✅ **configtx.yaml**: Updated to use `orderer.orderer.example.com:7050`
3. ✅ **registerEnroll.sh**: Modified to include both hostnames in future enrollments

## Next Steps After Fix

1. Verify orderer recognizes itself: `docker logs orderer.example.com | grep "Found myself"`
2. Deploy ModelRegistry chaincode
3. Deploy ContributionLedger chaincode
4. Deploy SARAnchor chaincode
5. Run smoke tests

