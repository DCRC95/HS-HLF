# AML AI Consortium – Phase 1 Context & Current Focus

## Source Documents
- `phase_1_plan_details.md`: Phase 1 objectives, architecture, tooling, governance milestones.
- `consortium_context_overview.md`: strategic vision, current Hacksleuths stack, phased roadmap, risk posture.
- `deployment-considerations.md`: legal, privacy, security, operational, and funding lenses plus required controls.
- `week1_2.md`: fortnight playbook covering MSP work, DR policy, DPIA scoping, analyst personas.
- `execution_plan.md`, `phase_1_plan_details.md`, `phase1_evaluation_addendum.md`: supporting checkpoints and evaluation notes.

## Context Highlights
### Mission & Architecture
- Build a regulator-grade Fabric consortium so banks + regulators can co-detect laundering typologies while keeping raw data local.
- Phase 1 proves the topology: RAFT orderer set, orgs (`BankA`, `BankB`, `ConsortiumOps`, `RegulatorObserver`), three channels (`model-governance`, `sar-audit`, `ops-monitoring`), Fabric CAs with NodeOU controls, and chaincode modules (`ModelRegistry`, `ContributionLedger`, `SARAnchor`).
- Hacksleuths pipeline already ingests OSINT/offshore leaks, applies NLP (WBI) + graph analytics, and drafts SARs; these feed the chaincode+FL flows.

### Compliance & Risk Drivers
- Deployment considerations emphasize multi-jurisdiction legal opinions, DPIAs, regulator sandbox engagement, explainability tooling, and PET safeguards.
- Security posture mandates mutual TLS, HSM/KMS for critical keys, incident response playbooks, monitoring stack, and verifiable DR strategy.
- Commercial workstreams focus on cost-sharing, KPI reporting, and regulator sponsorship to justify consortium participation.

### Week 1–2 Achievements
- Fabric dev network cloned from `test-network`, CAs stood up, MSPs/NodeOUs generated, `configtx.yaml` finalized with anchor peers.
- CA-issued MSPs exported + hashed, CLI context validated across orgs, and evidence logged in `fabric-dev-network/infra/README.md`.
- Org manifest (`orgs.yaml`) documents MSP IDs, CA bindings, archive paths, and CLI proofs.

## Current Assignment – Step 3: Ledger Snapshot & Backup Policy
With Week 1–2 Item 2 complete, we now execute Item 3 from `week1_2.md:54-67`. Deliverables:

1. **Business Continuity Targets**
   - Confirm consortium-wide RPO (e.g., 15 min) and RTO (e.g., 1 hr) referencing legal/ops expectations in `deployment-considerations.md`.
   - Document rationale + owners inside `/docs/dr/ledger-snapshot.md`.

2. **Storage Strategy**
   - Primary: encrypted S3 bucket (Object Lock, lifecycle tiers) for daily ledger snapshots + weekly CouchDB dumps.
   - Secondary: on-prem or Vault-managed offline storage for dual control. Capture retention windows, encryption keys/KMS aliases, and access policies.

3. **Snapshot Automation**
   - Script `peer node snapshot save --channelID <channel> --snapshotPath /backups/<channel>/<org>/<timestamp>` for each peer.
   - Immediately `tar -czf snapshot-<channel>-<org>-<ts>.tgz …` and log metadata (org, block height, ts, operator).

4. **CouchDB Dumps**
   - Weekly `curl http://couchdb:5984/$DB/_all_docs?include_docs=true` (or `couchbackup`) per peer DB; compress + tag with channel/org.

5. **Integrity Hashing**
   - Run `shasum -a 256 <archive> > <archive>.sha256`; store hashes with the archives and append entries to the DR log.

6. **Restore Runbook**
   - Document decrypt → hash-verify → place snapshot under `ledgersData/snapshots/<channel>/<height>` → restart peer/orderer → resync CouchDB → validate channel height + chaincode query.
   - Include quarterly DR rehearsal schedule + approval checkpoints for the Security Lead.

7. **Documentation & Evidence**
   - Author `/docs/dr/ledger-snapshot.md` with policy, automation steps, restore guide, approvals.
   - Update `fabric-dev-network/infra/README.md` with commands/tests, hash outputs, storage locations, pending approvals.

Hand this brief to any tech agent so they understand Phase 1 context and the precise next actions for Step 3.
