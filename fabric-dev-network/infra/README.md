## MSP Hardening Evidence – 2025-11-19

### Anchor Peers & Org Definitions (Step 2.5 - Completed 2025-11-19)
- Updated `configtx/configtx.yaml` with anchor peers for `BankAMSP`, `BankBMSP`, `ConsortiumOpsMSP`, and `RegulatorObserverMSP`.
- Generated serialized org definitions using `configtxgen -printOrg` (Step 2.5):
  ```bash
  export PATH="${PWD}/fabric-samples/bin:${PATH}"
  export FABRIC_CFG_PATH="${PWD}/configtx"
  
  configtxgen -configPath configtx -printOrg BankAMSP \
    > organizations/peerOrganizations/banka.example.com/configtx.yaml
  configtxgen -configPath configtx -printOrg BankBMSP \
    > organizations/peerOrganizations/bankb.example.com/configtx.yaml
  configtxgen -configPath configtx -printOrg ConsortiumOpsMSP \
    > organizations/peerOrganizations/consortiumops.example.com/configtx.yaml
  configtxgen -configPath configtx -printOrg RegulatorObserverMSP \
    > organizations/peerOrganizations/regulatorobserver.example.com/configtx.yaml
  ```
  **Result**: All four org definition files generated successfully without errors:
  - `organizations/peerOrganizations/banka.example.com/configtx.yaml` (10KB)
  - `organizations/peerOrganizations/bankb.example.com/configtx.yaml` (10KB)
  - `organizations/peerOrganizations/consortiumops.example.com/configtx.yaml` (11KB)
  - `organizations/peerOrganizations/regulatorobserver.example.com/configtx.yaml` (11KB)
  
  **Status**: Step 2.5 complete. Week 1–2 Plan Item 2 marked as "done".

### MSP Archive Exports (Step 6)
- Stored sanitized tarballs (private keys excluded) under `infra/msp-archives/`:
  - `banka-msp.tar.gz`
  - `bankb-msp.tar.gz`
  - `consortiumops-msp.tar.gz`
  - `regulatorobserver-msp.tar.gz`
  - `orderer-msp.tar.gz`

### CLI Context / Peer Channel Evidence (2025-11-19)
- **Network Bring-Up**: Successfully executed `./network.sh up createChannel -c amlchannel -ca`
  - All 4 peer organisations (BankA, BankB, ConsortiumOps, RegulatorObserver) successfully joined channel `amlchannel`
  - Channel created using `ChannelUsingRaft` profile from `configtx/configtx.yaml`
  - All CA-issued MSPs properly enrolled and configured

- **Peer Channel List Evidence** (2025-11-19):
  ```bash
  export PATH=${PWD}/fabric-samples/bin:${PATH}
  export FABRIC_CFG_PATH=${PWD}/fabric-samples/config
  . scripts/envVar.sh
  
  # BankA (ORG=1)
  setGlobals 1
  peer channel list
  # Output: Channels peers has joined: amlchannel
  
  # BankB (ORG=2)
  setGlobals 2
  peer channel list
  # Output: Channels peers has joined: amlchannel
  
  # ConsortiumOps (ORG=3)
  setGlobals 3
  peer channel list
  # Output: Channels peers has joined: amlchannel
  
  # RegulatorObserver (ORG=4)
  setGlobals 4
  peer channel list
  # Output: Channels peers has joined: amlchannel
  ```
  
  **Result**: All four peer organisations can successfully list the `amlchannel`, confirming:
  - MSP context switching works correctly for all orgs
  - All peers have successfully joined the channel
  - Network is operational and ready for chaincode deployment

### Network Alignment Updates (2025-11-19)
- Updated `network.sh` to use 4-org CA registration functions
- Updated `createChannel.sh` to join all 4 peer orgs and set anchor peers
- Fixed `envVar.sh` to use localhost addresses for peer CLI commands
- Updated `compose-test-net.yaml` to include all 4 peer services
- Fixed `ccp-generate.sh` to generate connection profiles for all 4 orgs
- Fixed orderer TLS hostname references in `orderer.sh`, `setAnchorPeer.sh`, and `configUpdate.sh`

