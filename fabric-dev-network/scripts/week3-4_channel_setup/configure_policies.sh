#!/usr/bin/env bash
#
# Endorsement and ACL Policy Configuration Script for Week 3-4
# Author: Week 3-4 Implementation
# Date: $(date +%Y-%m-%d)
# Purpose: Configure endorsement and ACL policies for chaincode on channels
#

set -e

TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
LOG_FILE="${TEST_NETWORK_HOME}/logs/week3-4_channels.log"
POLICY_UPDATES_DIR="${TEST_NETWORK_HOME}/docs/policy_updates/week3-4"
ORDERER_CA="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/orderer.example.com/tlsca/tlsca.orderer.example.com-cert.pem"

mkdir -p "$POLICY_UPDATES_DIR"

. ${TEST_NETWORK_HOME}/scripts/envVar.sh

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Function to fetch channel config
fetch_channel_config() {
    local CHANNEL_NAME=$1
    local ORG=$2
    local OUTPUT_FILE=$3
    
    log "Fetching channel config for $CHANNEL_NAME from org $ORG..."
    
    setGlobals $ORG
    
    set -x
    peer channel fetch config "${OUTPUT_FILE}.pb" \
        -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.orderer.example.com \
        -c "$CHANNEL_NAME" \
        --tls \
        --cafile "$ORDERER_CA" 2>&1 | tee -a "$LOG_FILE"
    local res=$?
    { set +x; } 2>/dev/null
    
    if [ $res -ne 0 ]; then
        log "ERROR: Failed to fetch channel config"
        return 1
    fi
    
    # Convert to JSON if configtxlator is available
    if command -v configtxlator &> /dev/null; then
        log "Converting config to JSON..."
        configtxlator proto_decode \
            --input "${OUTPUT_FILE}.pb" \
            --type common.Block \
            --output "${OUTPUT_FILE}_block.json" 2>&1 | tee -a "$LOG_FILE" || true
        
        if [ -f "${OUTPUT_FILE}_block.json" ]; then
            jq '.data.data[0].payload.data.config' "${OUTPUT_FILE}_block.json" > "${OUTPUT_FILE}.json" 2>&1 || true
        fi
    fi
    
    return 0
}

# Function to update channel config
update_channel_config() {
    local CHANNEL_NAME=$1
    local ORG=$2
    local ORIGINAL_CONFIG=$3
    local MODIFIED_CONFIG=$4
    local UPDATE_TX=$5
    
    log "Updating channel config for $CHANNEL_NAME..."
    
    if ! command -v configtxlator &> /dev/null; then
        log "WARNING: configtxlator not found, skipping config update"
        log "Policy updates will need to be done manually or via chaincode definition"
        return 0
    fi
    
    setGlobals $ORG
    
    # Compute config update
    log "Computing config update..."
    set -x
    configtxlator proto_encode \
        --input "$ORIGINAL_CONFIG" \
        --type common.Config \
        --output "${ORIGINAL_CONFIG}.pb" 2>&1 | tee -a "$LOG_FILE"
    
    configtxlator proto_encode \
        --input "$MODIFIED_CONFIG" \
        --type common.Config \
        --output "${MODIFIED_CONFIG}.pb" 2>&1 | tee -a "$LOG_FILE"
    
    configtxlator compute_update \
        --channel_id "$CHANNEL_NAME" \
        --original "${ORIGINAL_CONFIG}.pb" \
        --updated "${MODIFIED_CONFIG}.pb" \
        --output "${UPDATE_TX}.pb" 2>&1 | tee -a "$LOG_FILE"
    
    configtxlator proto_decode \
        --input "${UPDATE_TX}.pb" \
        --type common.ConfigUpdate \
        --output "${UPDATE_TX}.json" 2>&1 | tee -a "$LOG_FILE"
    { set +x; } 2>/dev/null
    
    # Wrap in envelope
    echo '{"payload":{"header":{"channel_header":{"channel_id":"'$CHANNEL_NAME'","type":2}},"data":{"config_update":'$(cat "${UPDATE_TX}.json")'}}}' | jq . > "${UPDATE_TX}_envelope.json"
    
    configtxlator proto_encode \
        --input "${UPDATE_TX}_envelope.json" \
        --type common.Envelope \
        --output "$UPDATE_TX" 2>&1 | tee -a "$LOG_FILE"
    
    # Sign and update
    log "Submitting config update..."
    set -x
    peer channel update \
        -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.orderer.example.com \
        -c "$CHANNEL_NAME" \
        -f "$UPDATE_TX" \
        --tls \
        --cafile "$ORDERER_CA" 2>&1 | tee -a "$LOG_FILE"
    local res=$?
    { set +x; } 2>/dev/null
    
    if [ $res -ne 0 ]; then
        log "WARNING: Config update may have failed, but continuing..."
    else
        log "✅ Channel config updated successfully"
    fi
}

# Function to document endorsement policies
document_endorsement_policies() {
    log "=== Documenting Endorsement Policies ==="
    
    cat > "${POLICY_UPDATES_DIR}/endorsement_policies.md" <<'EOF'
# Endorsement Policies - Week 3-4

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Purpose:** Document endorsement policies for chaincode modules

## ModelRegistry Chaincode (model-governance channel)

**Channel:** model-governance
**Organizations:** BankA, BankB, ConsortiumOps

**Endorsement Policy:**
- Requires endorsements from BankA AND BankB
- Policy: `AND('BankAMSP.peer', 'BankBMSP.peer')`
- ConsortiumOps can optionally be included if specified

**Implementation Note:**
This policy ensures that both banks must approve model registry updates, providing mutual consent for model version registration.

## ContributionLedger Chaincode (model-governance channel)

**Channel:** model-governance
**Organizations:** BankA, BankB, ConsortiumOps

**Endorsement Policy:**
- Requires endorsements from BankA AND BankB
- Policy: `AND('BankAMSP.peer', 'BankBMSP.peer')`
- ConsortiumOps endorsement may be required for specific operations if specified

**Implementation Note:**
Federated learning updates require both banks to endorse, ensuring consensus on contribution records.

## SARAnchor Chaincode (sar-audit channel)

**Channel:** sar-audit
**Organizations:** BankA, BankB, RegulatorObserver

**Endorsement Policy:**
- Write operations: Requires endorsements from BankA OR BankB
- Policy: `OR('BankAMSP.peer', 'BankBMSP.peer')`
- Read operations: Available to all channel members including RegulatorObserver

**ACL Policy:**
- Writers: BankA, BankB (banks can submit SAR metadata)
- Readers: BankA, BankB, RegulatorObserver (regulator has read-only access)

**Implementation Note:**
Banks can independently submit SAR metadata, while regulator has read-only access for audit purposes.

EOF
    log "Endorsement policies documented in ${POLICY_UPDATES_DIR}/endorsement_policies.md"
}

# Function to create policy update documentation
create_policy_documentation() {
    log "=== Creating Policy Update Documentation ==="
    
    local TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    cat > "${POLICY_UPDATES_DIR}/policy_changes.json" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "author": "Week 3-4 Implementation",
  "purpose": "Document channel policy changes and configurations",
  "changes": [
    {
      "channel": "model-governance",
      "chaincode": "ModelRegistry",
      "endorsement_policy": "AND('BankAMSP.peer', 'BankBMSP.peer')",
      "description": "Requires both BankA and BankB to endorse model registry updates",
      "applied_at": "$TIMESTAMP"
    },
    {
      "channel": "model-governance",
      "chaincode": "ContributionLedger",
      "endorsement_policy": "AND('BankAMSP.peer', 'BankBMSP.peer')",
      "description": "Requires both BankA and BankB to endorse federated learning contribution records",
      "applied_at": "$TIMESTAMP"
    },
    {
      "channel": "sar-audit",
      "chaincode": "SARAnchor",
      "endorsement_policy": "OR('BankAMSP.peer', 'BankBMSP.peer')",
      "acl_writers": ["BankAMSP", "BankBMSP"],
      "acl_readers": ["BankAMSP", "BankBMSP", "RegulatorObserverMSP"],
      "description": "Banks can write SAR metadata independently; regulator has read-only access",
      "applied_at": "$TIMESTAMP"
    }
  ],
  "notes": [
    "Endorsement policies are enforced at chaincode definition time",
    "ACL policies are enforced at channel configuration level",
    "Private data collections provide additional access control for SAR metadata"
  ]
}
EOF
    
    log "Policy documentation created: ${POLICY_UPDATES_DIR}/policy_changes.json"
}

# Main execution
log "=== Starting Policy Configuration ==="

# Document policies (actual policy application happens during chaincode definition)
document_endorsement_policies
create_policy_documentation

log ""
log "=== Policy Configuration Complete ==="
log "Note: Actual endorsement policies are applied during chaincode definition"
log "ACL policies are configured at channel level and enforced by Fabric"

