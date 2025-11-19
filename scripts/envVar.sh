#!/usr/bin/env bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This is a collection of bash functions used by different scripts

# imports
# test network home var targets to test-network folder
# the reason we use a var here is to accommodate scenarios
# where execution occurs from folders outside of default as $PWD, such as the test-network/addOrg3 folder.
# For setting environment variables, simple relative paths like ".." could lead to unintended references
# due to how they interact with FABRIC_CFG_PATH. It's advised to specify paths more explicitly,
# such as using "../${PWD}", to ensure that Fabric's environment variables are pointing to the correct paths.
TEST_NETWORK_HOME=${TEST_NETWORK_HOME:-${PWD}}
. ${TEST_NETWORK_HOME}/scripts/utils.sh

export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/orderer.example.com/tlsca/tlsca.orderer.example.com-cert.pem
export PEER0_ORG1_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/banka.example.com/tlsca/tlsca.banka.example.com-cert.pem
export PEER0_ORG2_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/bankb.example.com/tlsca/tlsca.bankb.example.com-cert.pem
export PEER0_ORG3_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/consortiumops.example.com/tlsca/tlsca.consortiumops.example.com-cert.pem
export PEER0_ORG4_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/regulatorobserver.example.com/tlsca/tlsca.regulatorobserver.example.com-cert.pem

# Set environment variables for the peer org
setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    # BankA
    export CORE_PEER_LOCALMSPID=BankAMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/banka.example.com/users/Admin@banka.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    # BankB
    export CORE_PEER_LOCALMSPID=BankBMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG2_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/bankb.example.com/users/Admin@bankb.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051
  elif [ $USING_ORG -eq 3 ]; then
    # ConsortiumOps
    export CORE_PEER_LOCALMSPID=ConsortiumOpsMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/consortiumops.example.com/users/Admin@consortiumops.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  elif [ $USING_ORG -eq 4 ]; then
    # RegulatorObserver
    export CORE_PEER_LOCALMSPID=RegulatorObserverMSP
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG4_CA
    export CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/regulatorobserver.example.com/users/Admin@regulatorobserver.example.com/msp
    export CORE_PEER_ADDRESS=localhost:12051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" = "true" ]; then
    env | grep CORE
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=()
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    # Map org number to peer name
    case $1 in
      1) PEER="peer0.banka.example.com" ;;
      2) PEER="peer0.bankb.example.com" ;;
      3) PEER="peer0.consortiumops.example.com" ;;
      4) PEER="peer0.regulatorobserver.example.com" ;;
      *) PEER="peer0.org$1" ;;
    esac
    ## Set peer addresses
    if [ -z "$PEERS" ]
    then
	PEERS="$PEER"
    else
	PEERS="$PEERS $PEER"
    fi
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" --peerAddresses $CORE_PEER_ADDRESS)
    ## Set path to TLS certificate
    CA=PEER0_ORG$1_CA
    TLSINFO=(--tlsRootCertFiles "${!CA}")
    PEER_CONN_PARMS=("${PEER_CONN_PARMS[@]}" "${TLSINFO[@]}")
    # shift by one to get to the next organization
    shift
  done
}

verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}
