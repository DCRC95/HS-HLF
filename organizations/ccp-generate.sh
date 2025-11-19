#!/usr/bin/env bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

# BankA (ORG=1)
ORG=1
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/banka.example.com/tlsca/tlsca.banka.example.com-cert.pem
CAPEM=organizations/peerOrganizations/banka.example.com/ca/ca.banka.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/banka.example.com/connection-banka.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/banka.example.com/connection-banka.yaml

# BankB (ORG=2)
ORG=2
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/bankb.example.com/tlsca/tlsca.bankb.example.com-cert.pem
CAPEM=organizations/peerOrganizations/bankb.example.com/ca/ca.bankb.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/bankb.example.com/connection-bankb.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/bankb.example.com/connection-bankb.yaml

# ConsortiumOps (ORG=3)
ORG=3
P0PORT=11051
CAPORT=10054
PEERPEM=organizations/peerOrganizations/consortiumops.example.com/tlsca/tlsca.consortiumops.example.com-cert.pem
CAPEM=organizations/peerOrganizations/consortiumops.example.com/ca/ca.consortiumops.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/consortiumops.example.com/connection-consortiumops.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/consortiumops.example.com/connection-consortiumops.yaml

# RegulatorObserver (ORG=4)
ORG=4
P0PORT=12051
CAPORT=11054
PEERPEM=organizations/peerOrganizations/regulatorobserver.example.com/tlsca/tlsca.regulatorobserver.example.com-cert.pem
CAPEM=organizations/peerOrganizations/regulatorobserver.example.com/ca/ca.regulatorobserver.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/regulatorobserver.example.com/connection-regulatorobserver.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/regulatorobserver.example.com/connection-regulatorobserver.yaml
