#!/usr/bin/env bash
#
# Channel Creation and Peer Join Script for Week 3-4
# Author: Week 3-4 Implementation
# Date: $(date +%Y-%m-%d)
# Purpose: Create channels and join peers for model-governance, sar-audit, ops-monitoring
#

set -e

TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
LOG_FILE="${TEST_NETWORK_HOME}/logs/week3-4_channels.log"
ARTIFACTS_DIR="${TEST_NETWORK_HOME}/artifacts/channels/week3-4"
ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/orderer.example.com/tlsca/tlsca.orderer.example.com-cert.pem"
MAX_RETRY=5
DELAY=3

# Set up PATH for Fabric binaries
export PATH=${TEST_NETWORK_HOME}/fabric-samples/bin:${TEST_NETWORK_HOME}/../bin:${PWD}/../bin:$PATH
export FABRIC_CFG_PATH="${TEST_NETWORK_HOME}/configtx"

# Source utility functions
. ${TEST_NETWORK_HOME}/scripts/envVar.sh

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Function to create channel
create_channel() {
    local CHANNEL_NAME=$1
    local CREATOR_ORG=$2
    local TX_FILE="${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx"
    local BLOCK_FILE="${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"
    
    log "=== Creating channel: $CHANNEL_NAME ==="
    log "  Creator org: $CREATOR_ORG"
    log "  Transaction file: $TX_FILE"
    
    if [ ! -f "$TX_FILE" ]; then
        log "ERROR: Channel transaction not found: $TX_FILE"
        log "Please run generate_channels.sh first"
        exit 1
    fi
    
    setGlobals $CREATOR_ORG
    
    log "  Creating channel from ConsortiumOps admin..."
    set -x
    peer channel create \
        -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.orderer.example.com \
        -c "$CHANNEL_NAME" \
        -f "$TX_FILE" \
        --tls \
        --cafile "$ORDERER_CA" \
        --outputBlock "$BLOCK_FILE" 2>&1 | tee -a "$LOG_FILE"
    local res=$?
    { set +x; } 2>/dev/null
    
    if [ $res -ne 0 ]; then
        log "  ERROR: Channel creation failed for $CHANNEL_NAME"
        exit 1
    fi
    
    log "  ✅ Channel $CHANNEL_NAME created successfully"
    
    # Get channel info
    if [ -f "$BLOCK_FILE" ]; then
        local BLOCK_SIZE=$(stat -f%z "$BLOCK_FILE" 2>/dev/null || stat -c%s "$BLOCK_FILE" 2>/dev/null)
        local BLOCK_HASH=$(shasum -a 256 "$BLOCK_FILE" | awk '{print $1}')
        log "  Block size: $BLOCK_SIZE bytes"
        log "  Block SHA256: $BLOCK_HASH"
    fi
}

# Function to generate channel creation transaction
generate_channel_tx() {
    local CHANNEL_NAME=$1
    local PROFILE_NAME=$2
    
    log "Generating channel creation transaction for: $CHANNEL_NAME"
    
    export FABRIC_CFG_PATH="${TEST_NETWORK_HOME}/configtx"
    
    set -x
    configtxgen \
        -profile "$PROFILE_NAME" \
        -outputCreateChannelTx "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" \
        -channelID "$CHANNEL_NAME" \
        -configPath "${TEST_NETWORK_HOME}/configtx" 2>&1 | tee -a "$LOG_FILE"
    local res=$?
    { set +x; } 2>/dev/null
    
    if [ $res -ne 0 ]; then
        log "ERROR: Failed to generate channel transaction for $CHANNEL_NAME"
        exit 1
    fi
    
    if [ -f "${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx" ]; then
        log "  ✅ Channel transaction generated: ${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx"
    else
        log "  ❌ ERROR: Channel transaction file not created"
        exit 1
    fi
}

# Function to join peer to channel
join_peer_to_channel() {
    local ORG=$1
    local CHANNEL_NAME=$2
    local BLOCK_FILE="${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"
    
    log "  Joining org $ORG to channel $CHANNEL_NAME..."
    
    setGlobals $ORG
    
    local rc=1
    local COUNTER=1
    
    while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
        sleep $DELAY
        set -x
        peer channel join \
            -b "$BLOCK_FILE" \
            --tls \
            --cafile "$ORDERER_CA" 2>&1 | tee -a "$LOG_FILE"
        rc=$?
        { set +x; } 2>/dev/null
        COUNTER=$(expr $COUNTER + 1)
    done
    
    if [ $rc -ne 0 ]; then
        log "  ❌ ERROR: Failed to join org $ORG to channel $CHANNEL_NAME after $MAX_RETRY attempts"
        exit 1
    fi
    
    local org_name=""
    case $ORG in
        1) org_name="BankA" ;;
        2) org_name="BankB" ;;
        3) org_name="ConsortiumOps" ;;
        4) org_name="RegulatorObserver" ;;
        *) org_name="org${ORG}" ;;
    esac
    
    log "  ✅ $org_name peer joined channel $CHANNEL_NAME"
    
    # Get channel info
    set -x
    peer channel getinfo -c "$CHANNEL_NAME" 2>&1 | tee -a "$LOG_FILE"
    { set +x; } 2>/dev/null
}

# Function to update anchor peer
update_anchor_peer() {
    local ORG=$1
    local CHANNEL_NAME=$2
    
    log "  Updating anchor peer for org $ORG on channel $CHANNEL_NAME..."
    
    setGlobals $ORG
    
    # Generate anchor peer update transaction
    local ANCHOR_TX="${ARTIFACTS_DIR}/${CORE_PEER_LOCALMSPID}anchors_${CHANNEL_NAME}.tx"
    
    export FABRIC_CFG_PATH="${TEST_NETWORK_HOME}/configtx"
    
    set -x
    configtxgen \
        -profile "${CHANNEL_NAME}Profile" \
        -outputAnchorPeersUpdate "$ANCHOR_TX" \
        -channelID "$CHANNEL_NAME" \
        -asOrg "${CORE_PEER_LOCALMSPID}" \
        -configPath "${TEST_NETWORK_HOME}/configtx" 2>&1 | tee -a "$LOG_FILE" || true
    { set +x; } 2>/dev/null
    
    # If configtxgen profile doesn't exist, use the setAnchorPeer script
    if [ ! -f "$ANCHOR_TX" ]; then
        log "  Using setAnchorPeer script for anchor peer update..."
        CHANNEL_NAME="$CHANNEL_NAME" . ${TEST_NETWORK_HOME}/scripts/setAnchorPeer.sh $ORG 2>&1 | tee -a "$LOG_FILE" || {
            log "  ⚠️  WARNING: Anchor peer update may have failed, continuing..."
        }
    else
        set -x
        peer channel update \
            -o localhost:7050 \
            --ordererTLSHostnameOverride orderer.orderer.example.com \
            -c "$CHANNEL_NAME" \
            -f "$ANCHOR_TX" \
            --tls \
            --cafile "$ORDERER_CA" 2>&1 | tee -a "$LOG_FILE"
        local res=$?
        { set +x; } 2>/dev/null
        
        if [ $res -ne 0 ]; then
            log "  ⚠️  WARNING: Anchor peer update failed, but continuing..."
        else
            log "  ✅ Anchor peer updated for org $ORG"
        fi
    fi
}

# Main execution
log "=== Starting Channel Creation and Peer Join Process ==="

# Channel transactions should already be generated by generate_channels.sh
# If not, generate them here
if [ ! -f "${ARTIFACTS_DIR}/model-governance.tx" ]; then
    log ""
    log "=== Generating Channel Transactions ==="
    generate_channel_tx "model-governance" "ModelGovernanceChannel"
    generate_channel_tx "sar-audit" "SARAuditChannel"
    generate_channel_tx "ops-monitoring" "OpsMonitoringChannel"
else
    log "Channel transactions already exist, skipping generation"
fi

# Create channels (from ConsortiumOps admin)
log ""
log "=== Creating Channels ==="
create_channel "model-governance" 3
create_channel "sar-audit" 3
create_channel "ops-monitoring" 3

# Join peers to model-governance channel (BankA, BankB, ConsortiumOps)
log ""
log "=== Joining Peers to model-governance Channel ==="
join_peer_to_channel 1 "model-governance"
join_peer_to_channel 2 "model-governance"
join_peer_to_channel 3 "model-governance"

# Update anchor peers for model-governance
log ""
log "=== Updating Anchor Peers for model-governance Channel ==="
update_anchor_peer 1 "model-governance"
update_anchor_peer 2 "model-governance"
update_anchor_peer 3 "model-governance"

# Join peers to sar-audit channel (BankA, BankB, RegulatorObserver)
log ""
log "=== Joining Peers to sar-audit Channel ==="
join_peer_to_channel 1 "sar-audit"
join_peer_to_channel 2 "sar-audit"
join_peer_to_channel 4 "sar-audit"

# Update anchor peers for sar-audit
log ""
log "=== Updating Anchor Peers for sar-audit Channel ==="
update_anchor_peer 1 "sar-audit"
update_anchor_peer 2 "sar-audit"
update_anchor_peer 4 "sar-audit"

# Join peers to ops-monitoring channel (ConsortiumOps only)
log ""
log "=== Joining Peers to ops-monitoring Channel ==="
join_peer_to_channel 3 "ops-monitoring"

# Update anchor peer for ops-monitoring
log ""
log "=== Updating Anchor Peer for ops-monitoring Channel ==="
update_anchor_peer 3 "ops-monitoring"

log ""
log "=== Channel Creation and Peer Join Process Complete ==="
log "All channels created and peers joined successfully"

