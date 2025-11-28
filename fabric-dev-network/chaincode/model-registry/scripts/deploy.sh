#!/usr/bin/env bash
#
# ModelRegistry Chaincode Deployment Script
# Author: Week 3-4 Implementation
# Date: 2025-11-28
# Purpose: Deploy ModelRegistry chaincode to dev network (phase_1_plan_details.md:62)
#

set -e

TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
LOG_FILE="${TEST_NETWORK_HOME}/logs/week3-4_chaincode.log"
CHAINCODE_NAME="model-registry"
CHAINCODE_VERSION="1.0"
CHANNEL_NAME="model-governance"
ENDORSEMENT_POLICY="AND('BankAMSP.peer', 'BankBMSP.peer')"

. ${TEST_NETWORK_HOME}/scripts/envVar.sh

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== Deploying ModelRegistry Chaincode ==="

# Package chaincode
log "Packaging chaincode..."
setGlobals 1
peer lifecycle chaincode package ${CHAINCODE_NAME}.tar.gz \
  --path ${TEST_NETWORK_HOME}/chaincode/${CHAINCODE_NAME}/src \
  --lang node \
  --label ${CHAINCODE_NAME}_${CHAINCODE_VERSION} 2>&1 | tee -a "$LOG_FILE"

# Install on all peers
for org in 1 2 3; do
    log "Installing on org $org..."
    setGlobals $org
    peer lifecycle chaincode install ${CHAINCODE_NAME}.tar.gz 2>&1 | tee -a "$LOG_FILE"
done

# Get package ID
setGlobals 1
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled 2>&1 | grep -oP "${CHAINCODE_NAME}_${CHAINCODE_VERSION}:\K[^\s]+" | head -1)
log "Package ID: $PACKAGE_ID"

# Approve for all orgs
for org in 1 2 3; do
    log "Approving for org $org..."
    setGlobals $org
    peer lifecycle chaincode approveformyorg \
      -o localhost:7050 \
      --ordererTLSHostnameOverride orderer.orderer.example.com \
      --channelID $CHANNEL_NAME \
      --name $CHAINCODE_NAME \
      --version $CHAINCODE_VERSION \
      --package-id $PACKAGE_ID \
      --sequence 1 \
      --tls \
      --cafile "$ORDERER_CA" \
      --signature-policy "$ENDORSEMENT_POLICY" 2>&1 | tee -a "$LOG_FILE"
done

# Commit chaincode definition
log "Committing chaincode definition..."
setGlobals 1
peer lifecycle chaincode commit \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.orderer.example.com \
  --channelID $CHANNEL_NAME \
  --name $CHAINCODE_NAME \
  --version $CHAINCODE_VERSION \
  --sequence 1 \
  --tls \
  --cafile "$ORDERER_CA" \
  --peerAddresses localhost:7051 \
  --tlsRootCertFiles "$PEER0_ORG1_CA" \
  --peerAddresses localhost:9051 \
  --tlsRootCertFiles "$PEER0_ORG2_CA" \
  --peerAddresses localhost:11051 \
  --tlsRootCertFiles "$PEER0_ORG3_CA" \
  --signature-policy "$ENDORSEMENT_POLICY" 2>&1 | tee -a "$LOG_FILE"

log "✅ ModelRegistry chaincode deployed successfully"

