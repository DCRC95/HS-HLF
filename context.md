1. High‑Level Perspective
Goal: Build a regulator‑grade Hyperledger Fabric network as the trust anchor for a Federated AML AI Network. This network will record:
Federated learning updates
SAR (Suspicious Activity Report) metadata
Analyst workflow events
…while satisfying regulator/compliance expectations (traceability, DPIA, personas, DR, etc.).
Phase focus: We are currently in Phase 1, Weeks 1–2, which are about:
Standing up a CA‑issued MSP based Fabric dev network.
Hardening MSP structure (OUs, TLS, anchor peers).
Preparing for downstream tracks: ledger snapshot/DR, DPIA, data inventory, personas.
Your job is to keep everything aligned with that compliance‑driven, regulator‑grade perspective while working primarily in the fabric-dev-network repo and referring to the AML AI NETWORK documentation.
2. Documentation You MUST Read First
Read these in this order to understand intent and constraints:
AML AI NETWORK/week1_2.md
This is the Weeks 1–2 Developer Playbook.
It defines the steps (1–7) we are implementing now.
Pay particular attention to:
Step 1: Org manifest (orgs.yaml concept – even if the file has been deleted, the idea still matters).
Step 2: Org structure & MSP configs.
Steps 3–7: Ledger snapshot plan, DPIA, personas, and “evidence on disk” requirements.
AML AI NETWORK/consortium_context_overview.md and phase_1_plan_details.md
Explain the consortium structure (banks, regulator, ops org).
Explain how this Fabric network fits into the wider 12‑week AML AI programme.
AML AI NETWORK/deployment-considerations.md and AML AI NETWORK/execution_plan.md
Capture regulatory and operational constraints, including:
Data residency and jurisdiction concerns.
Expectations for audit trails and DR.
fabric-dev-network/README.md
Explains how this environment is derived from fabric-samples/test-network.
Clarifies local conventions and deviations from upstream test network patterns.
Hyperledger Fabric sample docs under fabric-dev-network/fabric-samples/ (skim)
Especially:
fabric-samples/test-network/ (the original two‑org network).
fabric-samples/test-network/configtx/configtx.yaml and scripts for reference patterns.
3. Current Technical State (What’s Already Done)
Repositories & Roots
Project root: /Users/rhys/fabric-dev/fabric-dev-network
We cloned/borrowed from fabric-samples/test-network but are now customising it for:
BankA (BankAMSP)
BankB (BankBMSP)
ConsortiumOps (ConsortiumOpsMSP)
RegulatorObserver (RegulatorObserverMSP)
OrdererOrg (OrdererMSP)
Certificate Authorities (CAs)
compose/compose-ca.yaml now defines four peer CAs + one orderer CA:
ca_banka, ca_bankb, ca_consortiumops, ca_regulatorobserver, ca_orderer.
Each CA has:
Updated fabric-ca-server-config.yaml under organizations/fabric-ca/<org>/:
Correct ca.name.
London jurisdiction metadata (C=GB, ST=London, L=London).
OU names reflecting roles (BankA, BankB, ConsortiumOps, RegulatorObserver, OrdererOrg).
CSR names/hosts that align with our Fabric hostnames (peer0., orderer., CA services).
MSPs (Organisation Material)
Using Fabric CA (not cryptogen) as the canonical source of MSP material:
network.config has CRYPTO="fabric-ca".
A custom register/enrol script existed and was used to:
Enrol CA admins and register:
Peers (peer0, peer1 where applicable),
user1 client,
*admin and auditor1 identities.
Enrol MSP and TLS material for:
organizations/peerOrganizations/banka.example.com/...
organizations/peerOrganizations/bankb.example.com/...
organizations/peerOrganizations/consortiumops.example.com/...
organizations/peerOrganizations/regulatorobserver.example.com/...
organizations/ordererOrganizations/orderer.example.com/...
Write NodeOUs configs under each org’s msp/config.yaml so certs are role‑aware.
> Note: The original script file may have been removed by the user, but the MSP directories and structure it generated are the desired target state.
Channel Configuration (configtx/configtx.yaml)
Organisations section defines all five orgs with MSP IDs and MSPDir pointing to the CA‑issued directories.
Each peer org has AnchorPeers:
BankA → peer0.banka.example.com:7051
BankB → peer0.bankb.example.com:9051
ConsortiumOps → peer0.consortiumops.example.com:11051
RegulatorObserver → peer0.regulatorobserver.example.com:12051
Profiles:
FiveOrgOrdererGenesis: system channel genesis profile (etcdraft, uses OrdererOrg + all peers).
FiveOrgApplicationChannel: application channel profile with the four peer orgs.
ChannelUsingRaft (added for compatibility with scripts):
Etcdraft orderer consenter uses the TLS cert at
../organizations/ordererOrganizations/orderer.example.com/orderers/orderer.orderer.example.com/tls/server.crt.
Application section includes the four peer orgs.
Sanity checks:
configtxgen -printOrg <OrgMSP> has been run for each peer org and the YAML output is stored under:
organizations/peerOrganizations/<org>.example.com/configtx.yaml.
MSP Archive Exports
We created private‑key‑free MSP tarballs under infra/msp-archives/:
banka-msp.tar.gz
bankb-msp.tar.gz
consortiumops-msp.tar.gz
regulatorobserver-msp.tar.gz
orderer-msp.tar.gz
infra/README.md records these as Step 6 evidence.
Org Manifest (orgs.yaml)
There was a detailed orgs.yaml capturing:
Org names, MSP IDs, domains.
CA services, CSR hosts/names.
Peer counts and planned anchor peers.
MSP source locations and MSP archives under infra/msp-archives/.
The user has since removed this file content, but the concept is still required by the playbook:
You should treat an org manifest as a single source of truth for:
Org inventory
CA bindings
Trust bundle (MSP) locations
Evidence pointers (e.g. where MSP archives / configtx printouts live)
4. Realignment Work in Progress
We have started adapting the runtime network (originally 2‑org test network) to the 4‑org AML network.
Environment vars (scripts/envVar.sh)
setGlobals now maps numeric org ids to the new MSPs:
1 → BankAMSP, admin at banka.example.com.
2 → BankBMSP, admin at bankb.example.com.
3 → ConsortiumOpsMSP, admin at consortiumops.example.com.
4 → RegulatorObserverMSP, admin at regulatorobserver.example.com.
TLS CA environment variables (PEER0_ORG*_CA, ORDERER_CA) now point at:
organizations/ordererOrganizations/orderer.example.com/tlsca/tlsca.orderer.example.com-cert.pem
organizations/peerOrganizations/<org>.example.com/tlsca/tlsca.<org>.example.com-cert.pem
Anchor‑peer update script (scripts/setAnchorPeer.sh)
For anchor‑peer updates, we now map ORG numeric id to the correct host/port:
1 → peer0.banka.example.com:7051
2 → peer0.bankb.example.com:9051
3 → peer0.consortiumops.example.com:11051
4 → peer0.regulatorobserver.example.com:12051
Compose files
compose/compose-test-net.yaml updated:
Orderer service mounts the CA‑issued orderer MSP/TLS:
../organizations/ordererOrganizations/orderer.example.com/orderers/orderer.orderer.example.com/...
Peer services:
peer0.banka.example.com (CORE_PEER_LOCALMSPID=BankAMSP)
peer0.bankb.example.com (CORE_PEER_LOCALMSPID=BankBMSP)
compose/docker/docker-compose-test-net.yaml:
Adjusted sidecar entries so Docker peers match the new service names (peer0.banka.*, peer0.bankb.*).
network.sh alignment
PATH now prepends the local fabric-samples/bin inside this project, so peer, configtxgen, etc. come from the right place.
The prereq check now only ensures that peer is in PATH (no dependency on an external ../config directory).
CRYPTO is switched to Fabric CA when -ca is given, and network.config defaults CRYPTO to fabric-ca.
5. What Still Needs To Be Done
You should treat these as the next concrete tasks:
Stabilise the 4‑org network bring‑up path
Confirm ./network.sh up createChannel -c amlchannel -ca:
Uses the new ChannelUsingRaft profile and configtx/configtx.yaml.
Does NOT regenerate MSPs with cryptogen (we want to keep the CA‑issued MSP hierarchy).
Ensure that createOrgs() is either:
Respecting existing CA‑issued MSPs, or
Using a script equivalent to our previous CA enrol script to regenerate them consistently, not re‑introducing org1/org2 layout.
Finalise runtime env mapping
Audit and, if needed, adjust:
Any remaining references to org1, org2, or example.com in:
scripts/envVar.sh
scripts/setAnchorPeer.sh
scripts/orderer*.sh
compose/compose-test-net.yaml and compose/docker/docker-compose-test-net.yaml
The runtime network should be fully coherent with:
MSP IDs: BankAMSP, BankBMSP, ConsortiumOpsMSP, RegulatorObserverMSP, OrdererMSP.
Domains: banka.example.com, bankb.example.com, consortiumops.example.com, regulatorobserver.example.com, orderer.example.com.
peer channel list evidence for each MSP
Once the network is up and amlchannel exists:
For each org, set env via setGlobals or a small helper equivalent:
BankA (ORG=1), BankB (2), ConsortiumOps (3), RegulatorObserver (4).
Run peer channel list and store:
Commands run.
Outputs (or logs) for each MSP context.
Append this evidence to infra/README.md as part of Step 2 / Step 7 proof.
Re‑instantiate / re‑design orgs.yaml
Recreate a manifest file (name can vary, but orgs.yaml is fine) that:
Reflects current orgs, CAs, MSPDirs, anchor peers.
References:
infra/msp-archives/*.tar.gz.
organizations/peerOrganizations/*/configtx.yaml.
Any future ledger snapshot and DPIA artefacts, when created.
The idea is not to re‑introduce deleted content verbatim, but to:
Keep a concise, machine‑parseable inventory for automation and auditors.
Keep alignment with Week 1–2 wider goals
When you move on:
Ledger snapshot & DR policy (Step 3):
Add scripts/docs under something like docs/dr/ledger-snapshot.md.
DPIA / data inventory (Step 4):
This is more about external documentation/tools but should refer back to MSP / trust boundaries documented here.
Personas & UX (Step 5+ in week1_2.md):
Not infra work, but rely on the traceability we’re establishing now.
6. Constraints & Practices to Observe
The user’s preferences / constraints:
Do not touch .env files or override env without explicit permission.
Prefer Fabric CA over cryptogen going forward; don’t regress to cryptogen unless explicitly instructed.
Don’t introduce new technologies or patterns if the existing pattern can be extended.
Keep code clean, DRY, and simple. Avoid duplicating patterns; reuse fabric-samples conventions where possible.
No mock / fake data in dev/prod paths; mocking is only acceptable in tests.
Think across environments: dev, test, prod. Even if we’re in dev, avoid assumptions that would break in higher environments.
Document everything meaningful in repo‑tracked markdown:
CA commands.
Network bring‑up commands/flags.
Locations of artefacts used as audit evidence.
If you follow this context, you should be able to:
Understand why the network is being reshaped away from Org1/Org2 to BankA/BankB/ConsortiumOps/RegObserver.
See which steps of the Week 1–2 playbook are already satisfied (CAs, MSPs, configtx, MSP archives).
Focus your next work on the smallest set of changes required to:
Make network.sh up createChannel -c amlchannel -ca truly 4‑org aware.
Capture peer channel list evidence for each MSP.
Re‑establish a clean orgs.yaml/manifest as the single source of truth.
