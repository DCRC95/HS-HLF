# Weeks 1–2 Developer Playbook

Phase 1 of the Federated AML AI Network aims to build a regulator-grade Hyperledger Fabric prototype that anchors federated learning updates, SAR metadata, and analyst workflows while establishing governance, legal, and UX foundations for the consortium (`consortium_context_overview.md:55-64`; `phase_1_plan_details.md:7-78`). Weeks 1–2 focus on bootstrapping the Fabric dev environment with CA-issued MSPs, codifying ledger snapshot/DR policies, kickstarting data-rights/DPIA work, and capturing analyst personas so subsequent workstreams (channel configuration, chaincode scaffolding, UX storyboards) rest on hardened infrastructure and validated requirements. This document breaks that fortnight into actionable tasks so any contributor or automation agent can reproduce the setup, maintain compliance traceability, and feed outputs into the broader 12-week execution plan.

---

## Oversight & Tooling Snapshot
- **Ownership:** Fabric Platform Lead (infra/security), Compliance & Governance Lead (legal/data inventory), UX/Analyst Lead (personas/workflows) reporting weekly to the programme manager per `phase_1_plan_details.md:55-63`.
- **Toolchain:** Hyperledger Fabric v2.5 binaries, Fabric CA, Docker/Docker Compose, Go/Node.js SDKs, Git-based Infra-as-Code (Ansible/Terraform), Vault or cloud KMS, collaboration suites (Notion, Confluence, Miro/Figma, secure video recording).

---

## Week 1 – Foundations

1. **Bootstrap Fabric Dev Cluster**
   - Clone Fabric samples, copy `test-network`, and replace cryptogen artefacts by spinning up Fabric CA servers for each org (`fabric-ca-server start` per org, enroll via `fabric-ca-client`).
   - Run `./network.sh up createChannel -c temp` to sanity-check binaries, then tear down.
   - Document every CLI invocation, Docker change, and env var in `/infra/README.md`; commit to repo for reproducibility.

   **Detailed Breakdown**
   1. Install Fabric prerequisites (Docker >= 20.x, Docker Compose, Go, Node.js, jq) and export `PATH` entries so `configtxgen`, `cryptogen`, and `fabric-ca-client` resolve.
   2. Clone the samples repo: `git clone https://github.com/hyperledger/fabric-samples.git` and check out the tag matching your binary version (e.g., `git checkout v2.5.5`).
   3. Copy the baseline network: `cp -R fabric-samples/test-network ./fabric-dev-network`; this becomes the working directory for customisation.
   4. Stop any running containers: `./network.sh down` (from within the copied directory) to ensure a clean slate before swapping crypto material.
   5. Edit `docker/docker-compose-ca.yaml` to reflect organisation names (`BankA`, `BankB`, `ConsortiumOps`, `RegulatorObserver`) and configure Fabric CA server environment variables (CA name, TLS cert/key paths, CSR hosts).
   6. Launch CA containers: `docker-compose -f docker/docker-compose-ca.yaml up -d` and verify logs with `docker logs ca_banka`.
   7. Register/enroll identities per org using `fabric-ca-client`. Example:
      ```bash
      export FABRIC_CA_CLIENT_HOME=${PWD}/organizations/peerOrganizations/banka.example.com/
      fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-banka --csr.hosts "peer0.banka.example.com,localhost"
      fabric-ca-client register --id.name peer0 --id.secret peer0pw --id.type peer
      fabric-ca-client enroll -u https://peer0:peer0pw@localhost:7054 --caname ca-banka --csr.hosts "peer0.banka.example.com,localhost" -M ${FABRIC_CA_CLIENT_HOME}/peers/peer0.banka.example.com/msp
      ```
   8. Place generated MSP material under `organizations/peerOrganizations/<org>/msp` and `tlsca`; repeat for orderer orgs.
   9. Update `configtx.yaml` to reference the CA-issued MSPs and anchor peers; run `configtxgen` sanity checks to ensure profiles compile.
   10. Verify binaries by creating a temporary channel: `./network.sh up createChannel -c temp` and inspect logs for peer/orderer startup success; follow with `./network.sh down`.
   11. For every CLI command or configuration tweak, append entries to `/infra/README.md` (command, purpose, expected output) so other engineers can replay the process.
   12. Commit changes (including README updates and CA configs) to the repo, ensuring sensitive keys remain excluded or stored in secure secrets management.

2. **Define Org Structure & MSP Configs**
   - Draft `orgs.yaml` listing `BankA`, `BankB`, `ConsortiumOps`, `RegulatorObserver` with peers/admins/application users + OU labels.
   - Issue certs through Fabric CA for each OU, populate `configtx.yaml` with MSP IDs and anchor peers, export MSP bundles to a restricted branch.
   - Verify ACL separation by running `peer channel list` under each MSP identity.

   **Detailed Breakdown**
   1. Create `orgs.yaml` (or similar manifest) capturing each organisation’s domain, peer count, orderer responsibility, and OU structure (peer/admin/client/auditor).
   2. Update Fabric CA server configs to reflect OU attributes via CSR settings (e.g., `FABRIC_CA_SERVER_CSR_NAMES`).
   3. For each org, register admin and user identities (`fabric-ca-client register --id.name admin --id.attrs "hf.Registrar.Roles=*,hf.Registrar.Attributes=*"`), then enroll to create MSP folders.
   4. Populate `configtx.yaml`’s `Organizations` section with MSP IDs, admin certs, and anchor peer definitions referencing the CA-issued certs.
   5. Run `configtxgen -printOrg BankAMSP > organizations/peerOrganizations/banka.example.com/configtx.yaml` to ensure definitions serialize correctly.
   6. Export MSP bundles (without private keys) into encrypted archives (`tar --exclude *_sk -czf banka-msp.tar.gz organizations/peerOrganizations/banka.example.com/msp`) and store them in a restricted repository or secret store.
   7. Switch CLI context (`export CORE_PEER_LOCALMSPID=BankAMSP; export CORE_PEER_MSPCONFIGPATH=...`) and execute `peer channel list` to confirm role-based access is respected for each org.

3. **Ledger Snapshot & Backup Policy**
   - Set RPO/RTO targets, decide snapshot cadence (daily peer snapshot, weekly CouchDB backup) and encrypted storage (e.g., S3 with lifecycle policies).
   - Script capture (`peer node snapshot`, `tar czf snapshot-$DATE.tgz`) and SHA256 validation logging.
   - Store the procedure in `/docs/dr/ledger-snapshot.md`, route to Security Lead for approval.

   **Detailed Breakdown**
   1. Engage business continuity stakeholders to agree on acceptable RPO/RTO (e.g., 15 min recovery point, 1 hr recovery time) and document rationale.
   2. Choose storage targets (cloud bucket, on-prem NAS) with encryption at rest and retention policies aligned with compliance rules.
   3. Write scripts (bash or Python) that iterate over peers, execute `peer node snapshot save --channelID <channel> --snapshotPath /backups/<channel>/<date>` and package outputs.
   4. For CouchDB state, run `curl http://couchdb:5984/$DB/_all_docs?include_docs=true` exports or use `couchbackup` tool to create weekly dumps.
   5. Generate SHA256 hashes for every archive (`shasum -a 256 snapshot-*.tgz > snapshot-*.sha256`) and store alongside the backup metadata.
   6. Define restore procedures (how to reimport snapshots, rebootstrap peers/orderers) and include test frequency (e.g., quarterly DR rehearsals).
   7. Compile the policy and scripts into `/docs/dr/ledger-snapshot.md`, obtain Security Lead approval, and register the document in the compliance tracker.

4. **Data Inventory & DPIA Scoping**
   - Build a catalog (spreadsheet/Notion) for OSINT, offshore, and member datasets with lawful basis, jurisdiction, retention, and sensitivity fields.
   - Flag DPIA-required items, assign Legal owners, and link processing activities to controls outlined in `deployment-considerations.md:22-37`.

   **Detailed Breakdown**
   1. Set up a centralized data inventory (Notion database, spreadsheet, or GRC tool) with columns: Dataset name, Source, Owner, Data subjects, Lawful basis, Jurisdiction, Retention, Sensitivity level, Sharing scope.
   2. Populate entries for each OSINT corpus, offshore leak dataset, and anticipated member-contributed data; capture provenance and licensing info.
   3. Map each dataset to regulatory obligations (GDPR articles, bank secrecy laws, SAR confidentiality) using `execution_plan.md:21-25` as reference.
   4. Identify processing activities likely to require DPIAs (e.g., cross-border transfers, large-scale monitoring) and note triggering criteria.
   5. Assign Legal/Compliance owners to draft DPIA sections, including risk analysis, mitigations (differential privacy, pseudonymisation), and residual risk acceptance.
   6. Record dependencies (e.g., need for Standard Contractual Clauses) and target completion dates; integrate status into the program tracker.

5. **Analyst Persona Interviews**
   - Schedule at least three interviews per institution (AML investigator, SAR reviewer, compliance lead); prepare question guides on alert triage, explainability, integration needs.
   - Record (with consent), transcribe, and synthesize into persona cards capturing goals, tooling, blockers.
   - Publish personas in UX workspace and highlight open questions for subsequent sprints.

   **Detailed Breakdown**
   1. Coordinate with member institutions to identify representative analysts (front-line investigator, senior compliance officer, SAR reviewer) and secure interview windows.
   2. Draft interview guides covering day-to-day workflows, alert pain points, required evidence for SARs, explainability expectations, and existing tooling integrations.
   3. Conduct sessions via secure video conference; record audio (with consent) and take structured notes tagging key themes (e.g., “false-positive fatigue”, “case management integration”).
   4. Transcribe recordings (manual or automated), highlight quotes that inform UX requirements, and anonymize sensitive references.
   5. Build persona cards summarizing demographics, goals, frustrations, preferred tools, KPIs, and adoption risks; include photos/icons for clarity.
   6. Share personas in the UX documentation hub, solicit feedback from stakeholders, and log open questions or feature requests into the product backlog.

---

## Week 2 – Hardening & Documentation

1. **Cluster Hardening (TLS + KMS)**
   - Configure Fabric CA for short-lived TLS certs, write renewal scripts, and test revocation via `fabric-ca-client revoke`.
   - Integrate Vault or cloud KMS: store CA/orderer keys centrally, enable auto-unseal, and update Compose files to mount HSM/KMS clients.
   - Document procedures and incident response steps in security runbooks.

2. **Automate Network Bring-Up**
   - Convert manual steps into Ansible playbooks or bash scripts provisioning containers, enrolling identities, and launching peers/orderers in one command.
   - Parameterise configs for staging vs. prod environments; validate by repeated teardown/up cycles.
   - Commit scripts to `/infra`, add CI job to lint/test them.

3. **Complete MSP Documentation**
   - Produce CA hierarchy diagrams, OU mappings, certificate lifecycle timelines, and access-control matrices per role.
   - Review with Compliance for audit readiness and archive in the secured documentation repository.

4. **Cold-Start Expectation Briefing**
   - Collect baseline metrics (false-positive rates, SAR throughput) and define Phase 1 success vs. future performance targets.
   - Draft comms deck covering objectives, limitations, and stakeholder update cadence; align with PMO/Comms teams.
   - Schedule briefing for Week 3 steering meeting.

5. **Journey Maps & UX Mockups**
   - Translate persona insights into journey maps from alert ingestion to SAR filing, highlighting integration and explainability touchpoints.
   - Build low-fidelity mockups in Figma/Balsamiq for analyst interfaces and API handoffs.
   - Store artefacts for Week 3 storyboard sprint and log unresolved UX questions in the backlog.

---

## Outputs & Acceptance Criteria
- Operational Fabric dev cluster with CA-issued MSPs, TLS hardening, Vault/KMS integration, and documented automation scripts.
- Approved ledger snapshot/backup procedure and security runbooks.
- Data inventory + DPIA outline with assigned legal owners.
- Analyst persona pack plus documented journey maps feeding UX backlog.
- Cold-start expectation briefing ready for steering committee review.
