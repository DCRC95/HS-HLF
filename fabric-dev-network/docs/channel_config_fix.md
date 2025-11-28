# Channel Configuration Fix: Orderer Address Mismatch

**Date:** 2025-11-28  
**Issue:** Channel configuration has wrong orderer address, preventing chaincode deployment  
**Status:** Fix in progress

## Problem

Channels were created with orderer address `orderer.example.com:7050`, but the TLS certificate is for `orderer.orderer.example.com`. This causes:
- Peer block delivery service fails TLS handshake
- Chaincode approval transactions timeout (can't confirm receipt)
- `checkcommitreadiness` shows all approvals as `false`

## Root Cause

- `configtx.yaml` had `Addresses: - orderer.example.com:7050` in `OrdererDefaults`
- Orderer certificate only includes `orderer.orderer.example.com` and `localhost` in SAN
- Existing channels have wrong address embedded in their genesis blocks

## Fix Applied

1. ✅ Updated `configtx/configtx.yaml` to use `orderer.orderer.example.com:7050`
2. ✅ Regenerated channel transaction files with correct address

## Next Steps

### Option 1: Update Channel Configuration (Recommended for Production)
Update existing channel configurations to use correct orderer address:

```bash
# Fetch current config
peer channel fetch config config_block.pb -o localhost:7050 --ordererTLSHostnameOverride orderer.orderer.example.com -c model-governance --tls --cafile "$ORDERER_CA"

# Convert to JSON, update orderer address, compute update, submit
# (Full process requires configtxlator and channel config update transaction)
```

### Option 2: Recreate Channels (Simpler for Dev)
Since channels are empty (no chaincode deployed), can recreate:

```bash
# Delete old channel blocks (they'll be regenerated)
rm artifacts/channels/week3-4/*.block

# Recreate channels using updated transactions
./scripts/week3-4_channel_setup/create_and_join_channels.sh
```

### Option 3: Add orderer.example.com to Certificate
Regenerate orderer certificate to include both hostnames in SAN.

## Current Status

- ✅ Configtx.yaml updated
- ✅ Channel transactions regenerated  
- ⏳ Need to update existing channel configs or recreate channels
- ⏳ Chaincode deployment blocked until fix applied

