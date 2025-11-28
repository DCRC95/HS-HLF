#!/usr/bin/env bash
#
# MSP Verification Script for Week 3-4 Channel Setup
# Author: Week 3-4 Implementation
# Date: $(date +%Y-%m-%d)
# Purpose: Verify MSP material for all organizations (cert chains, OU separation, anchor peers)
#

set -e

TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
LOG_FILE="${TEST_NETWORK_HOME}/logs/week3-4_channels.log"
AUDIT_FILE="${TEST_NETWORK_HOME}/logs/msp_audit_week3.md"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$AUDIT_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_audit() {
    echo "$*" >> "$AUDIT_FILE"
}

log "=== Starting MSP Verification ==="
log_audit "# MSP Audit Report - Week 3"
log_audit ""
log_audit "**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
log_audit "**Purpose:** Verify MSP material for all organizations (cert chains, OU separation, anchor peers)"
log_audit ""

ORGS=(
    "BankA:banka.example.com:BankAMSP"
    "BankB:bankb.example.com:BankBMSP"
    "ConsortiumOps:consortiumops.example.com:ConsortiumOpsMSP"
    "RegulatorObserver:regulatorobserver.example.com:RegulatorObserverMSP"
)

for org_info in "${ORGS[@]}"; do
    IFS=':' read -r org_name org_domain msp_id <<< "$org_info"
    log "Verifying MSP for $org_name ($msp_id)"
    log_audit "## $org_name ($msp_id)"
    log_audit ""
    
    MSP_DIR="${TEST_NETWORK_HOME}/organizations/peerOrganizations/${org_domain}/msp"
    
    if [ ! -d "$MSP_DIR" ]; then
        log "ERROR: MSP directory not found: $MSP_DIR"
        log_audit "**Status:** ❌ FAILED - MSP directory not found"
        log_audit ""
        continue
    fi
    
    log_audit "**MSP Directory:** \`$MSP_DIR\`"
    log_audit ""
    
    # Verify admincerts
    log "  Checking admincerts..."
    ADMIN_CERTS_DIR="${MSP_DIR}/admincerts"
    if [ -d "$ADMIN_CERTS_DIR" ] && [ "$(ls -A $ADMIN_CERTS_DIR 2>/dev/null)" ]; then
        ADMIN_CERT_COUNT=$(find "$ADMIN_CERTS_DIR" -name "*.pem" | wc -l | tr -d ' ')
        log "    Found $ADMIN_CERT_COUNT admin certificate(s)"
        log_audit "- **Admin Certificates:** $ADMIN_CERT_COUNT found"
        
        # Verify certificate validity
        for cert in "$ADMIN_CERTS_DIR"/*.pem; do
            if [ -f "$cert" ]; then
                if openssl x509 -in "$cert" -noout -text > /dev/null 2>&1; then
                    SUBJECT=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//')
                    EXPIRY=$(openssl x509 -in "$cert" -noout -enddate 2>/dev/null | sed 's/notAfter=//')
                    log "      Valid cert: $SUBJECT (expires: $EXPIRY)"
                else
                    log "      ERROR: Invalid certificate format: $cert"
                    log_audit "  - ❌ Invalid certificate: \`$cert\`"
                fi
            fi
        done
    else
        log "    WARNING: No admin certificates found"
        log_audit "- **Admin Certificates:** ⚠️ WARNING - None found"
    fi
    
    # Verify cacerts
    log "  Checking cacerts..."
    CA_CERTS_DIR="${MSP_DIR}/cacerts"
    if [ -d "$CA_CERTS_DIR" ] && [ "$(ls -A $CA_CERTS_DIR 2>/dev/null)" ]; then
        CA_CERT_COUNT=$(find "$CA_CERTS_DIR" -name "*.pem" | wc -l | tr -d ' ')
        log "    Found $CA_CERT_COUNT CA certificate(s)"
        log_audit "- **CA Certificates:** $CA_CERT_COUNT found"
        
        for cert in "$CA_CERTS_DIR"/*.pem; do
            if [ -f "$cert" ]; then
                if openssl x509 -in "$cert" -noout -text > /dev/null 2>&1; then
                    SUBJECT=$(openssl x509 -in "$cert" -noout -subject 2>/dev/null | sed 's/subject=//')
                    log "      CA cert: $SUBJECT"
                fi
            fi
        done
    else
        log "    ERROR: No CA certificates found"
        log_audit "- **CA Certificates:** ❌ ERROR - None found"
    fi
    
    # Verify tlscacerts
    log "  Checking tlscacerts..."
    TLS_CA_CERTS_DIR="${MSP_DIR}/tlscacerts"
    if [ -d "$TLS_CA_CERTS_DIR" ] && [ "$(ls -A $TLS_CA_CERTS_DIR 2>/dev/null)" ]; then
        TLS_CA_CERT_COUNT=$(find "$TLS_CA_CERTS_DIR" -name "*.pem" | wc -l | tr -d ' ')
        log "    Found $TLS_CA_CERT_COUNT TLS CA certificate(s)"
        log_audit "- **TLS CA Certificates:** $TLS_CA_CERT_COUNT found"
    else
        log "    WARNING: No TLS CA certificates found"
        log_audit "- **TLS CA Certificates:** ⚠️ WARNING - None found"
    fi
    
    # Verify OU separation in config.yaml
    log "  Checking OU separation..."
    CONFIG_YAML="${MSP_DIR}/config.yaml"
    if [ -f "$CONFIG_YAML" ]; then
        log "    Found config.yaml"
        log_audit "- **Config.yaml:** ✅ Present"
        
        # Check for OU definitions
        if grep -q "OrganizationalUnitIdentifiers" "$CONFIG_YAML"; then
            OU_COUNT=$(grep -c "Certificate:" "$CONFIG_YAML" || echo "0")
            log "    Found OU definitions in config.yaml"
            log_audit "- **OU Separation:** ✅ Configured ($OU_COUNT OU(s) defined)"
            
            # Extract OU details
            log_audit ""
            log_audit "  OU Details:"
            while IFS= read -r line; do
                if [[ "$line" =~ Certificate: ]] || [[ "$line" =~ OrganizationalUnitIdentifier: ]]; then
                    log_audit "    - $line"
                fi
            done < "$CONFIG_YAML" | head -20
        else
            log "    WARNING: No OU definitions found in config.yaml"
            log_audit "- **OU Separation:** ⚠️ WARNING - No OU definitions found"
        fi
    else
        log "    WARNING: config.yaml not found"
        log_audit "- **Config.yaml:** ⚠️ WARNING - Not found"
    fi
    
    # Verify peer certificates
    log "  Checking peer certificates..."
    PEERS_DIR="${TEST_NETWORK_HOME}/organizations/peerOrganizations/${org_domain}/peers"
    if [ -d "$PEERS_DIR" ]; then
        PEER_COUNT=$(find "$PEERS_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
        log "    Found $PEER_COUNT peer(s)"
        log_audit "- **Peers:** $PEER_COUNT found"
        
        for peer_dir in "$PEERS_DIR"/*/; do
            if [ -d "$peer_dir" ]; then
                peer_name=$(basename "$peer_dir")
                log "      Checking peer: $peer_name"
                
                # Check for TLS cert
                if [ -f "$peer_dir/tls/server.crt" ]; then
                    log "        TLS cert: ✅ Present"
                    log_audit "  - **$peer_name:** TLS cert ✅"
                else
                    log "        TLS cert: ❌ Missing"
                    log_audit "  - **$peer_name:** TLS cert ❌"
                fi
                
                # Check for MSP
                if [ -d "$peer_dir/msp" ]; then
                    log "        MSP: ✅ Present"
                else
                    log "        MSP: ❌ Missing"
                fi
            fi
        done
    else
        log "    WARNING: Peers directory not found"
        log_audit "- **Peers:** ⚠️ WARNING - Directory not found"
    fi
    
    # Verify anchor peer configuration in configtx.yaml
    log "  Checking anchor peer configuration..."
    CONFIGTX="${TEST_NETWORK_HOME}/configtx/configtx.yaml"
    if [ -f "$CONFIGTX" ]; then
        if grep -q "$msp_id" "$CONFIGTX" && grep -A 5 "$msp_id" "$CONFIGTX" | grep -q "AnchorPeers"; then
            ANCHOR_HOST=$(grep -A 10 "$msp_id" "$CONFIGTX" | grep -A 5 "AnchorPeers" | grep "Host:" | head -1 | awk '{print $2}' | tr -d '"')
            ANCHOR_PORT=$(grep -A 10 "$msp_id" "$CONFIGTX" | grep -A 5 "AnchorPeers" | grep "Port:" | head -1 | awk '{print $2}')
            log "    Anchor peer configured: $ANCHOR_HOST:$ANCHOR_PORT"
            log_audit "- **Anchor Peer:** ✅ Configured ($ANCHOR_HOST:$ANCHOR_PORT)"
        else
            log "    WARNING: Anchor peer not configured in configtx.yaml"
            log_audit "- **Anchor Peer:** ⚠️ WARNING - Not configured"
        fi
    fi
    
    log_audit ""
    log "  ✅ Verification complete for $org_name"
    log_audit "---"
    log_audit ""
done

# Verify orderer MSP
log "Verifying Orderer MSP"
log_audit "## OrdererOrg (OrdererMSP)"
log_audit ""

ORDERER_MSP_DIR="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/orderer.example.com/msp"
if [ -d "$ORDERER_MSP_DIR" ]; then
    log "  Orderer MSP directory found"
    log_audit "**MSP Directory:** \`$ORDERER_MSP_DIR\`"
    log_audit ""
    
    # Check orderer certificates
    ORDERER_DIR="${TEST_NETWORK_HOME}/organizations/ordererOrganizations/orderer.example.com/orderers"
    if [ -d "$ORDERER_DIR" ]; then
        ORDERER_COUNT=$(find "$ORDERER_DIR" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
        log "  Found $ORDERER_COUNT orderer(s)"
        log_audit "- **Orderers:** $ORDERER_COUNT found"
        
        for orderer_dir in "$ORDERER_DIR"/*/; do
            if [ -d "$orderer_dir" ]; then
                orderer_name=$(basename "$orderer_dir")
                log "    Checking orderer: $orderer_name"
                
                if [ -f "$orderer_dir/tls/server.crt" ]; then
                    log "      TLS cert: ✅ Present"
                    log_audit "  - **$orderer_name:** TLS cert ✅"
                else
                    log "      TLS cert: ❌ Missing"
                    log_audit "  - **$orderer_name:** TLS cert ❌"
                fi
            fi
        done
    fi
else
    log "  ERROR: Orderer MSP directory not found"
    log_audit "**Status:** ❌ FAILED - MSP directory not found"
fi

log_audit ""
log_audit "## Summary"
log_audit ""
log_audit "**Verification completed:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
log_audit ""
log "=== MSP Verification Complete ==="

