# Phase 1 Execution Plan — Federated AML AI Network

## Phase Goal
Establish the regulatory, technical, and organisational foundations required to launch a permissioned Hyperledger Fabric pilot that ingests anonymised AML intelligence, coordinates federated model updates, and produces regulator-acceptable audit artefacts.

## Key Outcomes
- Approved consortium governance framework with regulator engagement plan.
- Validated data-processing/legal basis for all OSINT and institution-contributed datasets.
- Reference architecture for Hyperledger Fabric network, identity model, and integration touchpoints.
- Prototype federated learning workflow connected to Fabric for notarisation and model version control.
- Readiness report and gating checklist for Phase 2 (pilot deployment).

## Workstreams & Activities

### 1. Governance & Regulatory Alignment
- Draft consortium charter covering membership criteria, liability allocation, dispute resolution, and onboarding flow.
- Map applicable regulations (FATF, GDPR, bank secrecy, SAR confidentiality) to operational controls; get legal sign-off.
- Engage lead regulators/FIUs to secure pilot support; align on sandbox participation and supervisory access model.
- Define compliance playbook: audit trail retention, incident response, escalation paths, and reporting obligations.

### 2. Data Rights & Privacy Foundations
- Catalogue data sources (scraped OSINT, offshore leaks, member transaction data) and document consent/usage rights.
- Build data-classification matrix (public, confidential, SAR-restricted) with handling policies and retention limits.
- Design pseudonymisation/differential privacy strategy for federated gradients and shared metadata.
- Draft data-sharing agreements/SCCs for pilot members; review cross-border transfer implications.

### 3. Hyperledger Fabric Architecture & Infrastructure
- Produce architecture diagram covering orderers, peer nodes, channels, private data collections, and CA hierarchy.
- Define Membership Service Provider (MSP) structure aligning with banking identities and regulator observer nodes.
- Specify chaincode modules: model registry, contribution logging, incentive/reputation ledger, SAR hash anchoring.
- Select hosting model (cloud/on-prem mix), sizing assumptions, and CI/CD pipeline for chaincode deployment.

### 4. Federated Learning Integration (Phase 1 Prototype)
- Choose baseline AML model (e.g., anomaly detection GNN or transaction risk classifier) and define evaluation metrics.
- Implement secure aggregation prototype (TensorFlow Federated or PySyft) with differential privacy options.
- Integrate Fabric chaincode for model version notarisation and contribution attestations.
- Run dry-run simulations with synthetic datasets to validate convergence, latency, and poisoning resilience.

### 5. Pilot Operations & Change Management
- Identify initial member institutions and regulators for pilot; assign executive sponsors and technical leads.
- Draft onboarding checklist (infrastructure prerequisites, security controls, penetration testing requirements).
- Develop investigator/user workflow mapping: alerts, case management handoffs, SAR drafting integration.
- Create Phase 1 training plan (federated learning basics, Fabric operations, compliance controls).

### 6. Program Management & Quality Assurance
- Establish steering committee cadence, decision gates, and KPI dashboard (model precision/recall, latency, compliance audits).
- Define documentation standards (architectural runbooks, data catalogs, threat models).
- Build risk register (data leakage, poisoning, availability) with mitigation actions and owners.
- Plan independent review/assurance (third-party security audit or regulator tech assessment) before Phase 2.

## Timeline (12 Weeks)
- **Weeks 1–2:** Kickoff, stakeholder alignment, regulatory outreach initiation, data inventory; assign owners to mitigation actions and embed tracking in project plan.
- **Weeks 3–4:** Draft governance charter, legal review of data rights, architecture first pass; update risk register with owner commitments and reporting cadence.
- **Weeks 5–6:** Fabric environment design, MSP prototype, federated learning stack selection, synthetic data prep.
- **Weeks 7–8:** Secure aggregation prototype, chaincode scaffolding, privacy impact assessment draft.
- **Weeks 9–10:** Integrated dry-run (Fabric + federated workflow), compliance playbook finalisation, onboarding kit; verify mitigation progress against assigned owners.
- **Weeks 11–12:** Independent gap review, refine risk register, compile readiness report and Phase 2 proposal; capture mitigation status and handoff plan for Phase 2.

## Dependencies
- Legal counsel availability for rapid review cycles.
- Access to representative synthetic/obfuscated AML datasets for testing.
- Commitment from at least two financial institutions and one regulator for pilot preparation.
- Cloud/on-prem resources provisioned according to security guidelines.

## Risks & Mitigations
- **Regulatory hesitation:** Mitigate with early sandbox proposals, transparency on privacy controls, and regulator observer nodes.
- **Data rights challenges:** Maintain living data inventory, secure MOUs with data contributors, deploy automated redaction where required.
- **Model poisoning/poisoned contributions:** Implement differential privacy, secure aggregation, contribution weighting, and anomaly detection on updates.
- **Operational complexity:** Deliver incremental prototypes, invest in training, and document runbooks for Fabric and federated ops.

## Phase 1 Exit Criteria
- Signed-off governance charter and legal frameworks.
- Approved Fabric architecture and security design reviewed by independent assessor.
- Demonstrated federated learning prototype notarised on Fabric with acceptable performance benchmarks.
- Completed risk assessment with mitigation owners and action timelines.
- Phase 2 plan endorsed by steering committee and pilot stakeholders.
