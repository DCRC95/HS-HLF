#!/usr/bin/env bash
#
# Channel Generation Script for Week 3-4 Channel Setup
# Author: Week 3-4 Implementation
# Date: $(date +%Y-%m-%d)
# Purpose: Generate channel artifacts for model-governance, sar-audit, ops-monitoring
#

set -e

TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
LOG_FILE="${TEST_NETWORK_HOME}/logs/week3-4_channels.log"
ARTIFACTS_DIR="${TEST_NETWORK_HOME}/artifacts/channels/week3-4"
CONFIGTX_DIR="${TEST_NETWORK_HOME}/configtx"

# Set up PATH for Fabric binaries (same as network.sh)
export PATH=${TEST_NETWORK_HOME}/fabric-samples/bin:${TEST_NETWORK_HOME}/../bin:${PWD}/../bin:$PATH
export FABRIC_CFG_PATH="$CONFIGTX_DIR"

# Ensure directories exist
mkdir -p "$ARTIFACTS_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== Starting Channel Artifact Generation ==="

# Verify configtxgen is available
if ! command -v configtxgen &> /dev/null; then
    log "ERROR: configtxgen not found in PATH"
    log "PATH: $PATH"
    log "Please ensure Fabric binaries are installed and in PATH"
    exit 1
fi

log "Using configtxgen: $(which configtxgen)"
log "FABRIC_CFG_PATH: $FABRIC_CFG_PATH"

# Function to generate channel genesis block
generate_channel_block() {
    local CHANNEL_NAME=$1
    local PROFILE_NAME=$2
    local CONSORTIUM=$3
    
    log "Generating genesis block for channel: $CHANNEL_NAME"
    log "  Profile: $PROFILE_NAME"
    log "  Consortium: $CONSORTIUM"
    
    local BLOCK_FILE="${ARTIFACTS_DIR}/${CHANNEL_NAME}.block"
    
    set -x
    configtxgen \
        -profile "$PROFILE_NAME" \
        -outputBlock "$BLOCK_FILE" \
        -channelID "$CHANNEL_NAME" \
        -configPath "$CONFIGTX_DIR" 2>&1 | tee -a "$LOG_FILE"
    local res=$?
    { set +x; } 2>/dev/null
    
    if [ $res -ne 0 ]; then
        log "ERROR: Failed to generate channel block for $CHANNEL_NAME"
        exit 1
    fi
    
    if [ -f "$BLOCK_FILE" ]; then
        local BLOCK_SIZE=$(stat -f%z "$BLOCK_FILE" 2>/dev/null || stat -c%s "$BLOCK_FILE" 2>/dev/null)
        local BLOCK_HASH=$(shasum -a 256 "$BLOCK_FILE" | awk '{print $1}')
        log "  ✅ Block generated: $BLOCK_FILE"
        log "  Size: $BLOCK_SIZE bytes"
        log "  SHA256: $BLOCK_HASH"
        
        # Save metadata
        cat > "${ARTIFACTS_DIR}/${CHANNEL_NAME}.metadata.json" <<EOF
{
  "channel_name": "$CHANNEL_NAME",
  "profile": "$PROFILE_NAME",
  "consortium": "$CONSORTIUM",
  "block_file": "$BLOCK_FILE",
  "block_size_bytes": $BLOCK_SIZE,
  "block_sha256": "$BLOCK_HASH",
  "generated_at": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
  "configtx_path": "$CONFIGTX_DIR"
}
EOF
        log "  Metadata saved: ${ARTIFACTS_DIR}/${CHANNEL_NAME}.metadata.json"
    else
        log "  ❌ ERROR: Block file not created"
        exit 1
    fi
}

# Generate channel creation transactions (not genesis blocks for application channels)
log ""
log "=== Generating Channel Creation Transactions ==="

# Note: For application channels, we generate creation transactions, not genesis blocks
# The genesis block is created when the channel is actually created via peer channel create

generate_channel_tx() {
    local CHANNEL_NAME=$1
    local PROFILE_NAME=$2
    
    log "Generating channel creation transaction for: $CHANNEL_NAME"
    log "  Profile: $PROFILE_NAME"
    
    local TX_FILE="${ARTIFACTS_DIR}/${CHANNEL_NAME}.tx"
    
    set -x
    configtxgen \
        -profile "$PROFILE_NAME" \
        -outputCreateChannelTx "$TX_FILE" \
        -channelID "$CHANNEL_NAME" \
        -configPath "$CONFIGTX_DIR" 2>&1 | tee -a "$LOG_FILE"
    local res=$?
    { set +x; } 2>/dev/null
    
    if [ $res -ne 0 ]; then
        log "ERROR: Failed to generate channel transaction for $CHANNEL_NAME"
        exit 1
    fi
    
    if [ -f "$TX_FILE" ]; then
        local TX_SIZE=$(stat -f%z "$TX_FILE" 2>/dev/null || stat -c%s "$TX_FILE" 2>/dev/null)
        local TX_HASH=$(shasum -a 256 "$TX_FILE" | awk '{print $1}')
        log "  ✅ Transaction generated: $TX_FILE"
        log "  Size: $TX_SIZE bytes"
        log "  SHA256: $TX_HASH"
        
        # Save metadata
        cat > "${ARTIFACTS_DIR}/${CHANNEL_NAME}.metadata.json" <<EOF
{
  "channel_name": "$CHANNEL_NAME",
  "profile": "$PROFILE_NAME",
  "consortium": "AMLConsortium",
  "tx_file": "$TX_FILE",
  "tx_size_bytes": $TX_SIZE,
  "tx_sha256": "$TX_HASH",
  "generated_at": "$(date -u +"%Y-%m-%d %H:%M:%S UTC")",
  "configtx_path": "$CONFIGTX_DIR",
  "note": "Genesis block will be created when channel is created via peer channel create"
}
EOF
        log "  Metadata saved: ${ARTIFACTS_DIR}/${CHANNEL_NAME}.metadata.json"
    else
        log "  ❌ ERROR: Transaction file not created"
        exit 1
    fi
}

# Generate model-governance channel transaction
# This channel includes: BankA, BankB, ConsortiumOps
log ""
log "=== Generating model-governance Channel Transaction ==="
generate_channel_tx "model-governance" "ModelGovernanceChannel"

# Generate sar-audit channel transaction
# This channel includes: BankA, BankB, RegulatorObserver
log ""
log "=== Generating sar-audit Channel Transaction ==="
generate_channel_tx "sar-audit" "SARAuditChannel"

# Generate ops-monitoring channel transaction
# This channel includes: ConsortiumOps only
log ""
log "=== Generating ops-monitoring Channel Transaction ==="
generate_channel_tx "ops-monitoring" "OpsMonitoringChannel"

log ""
log "=== Channel Artifact Generation Complete ==="
log "All artifacts saved to: $ARTIFACTS_DIR"
log ""
log "Generated files:"
ls -lh "$ARTIFACTS_DIR" | tee -a "$LOG_FILE"

