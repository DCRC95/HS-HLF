# Consortium AML Network – Comprehensive Context

This document provides a shared understanding of the product vision, current capabilities, Phase 1 execution plan, governance model, risk posture, and long-term roadmap for the AML intelligence consortium. Use it as the reference point for engineering, data science, product, compliance, and commercial teams.

---

## 1. Strategic Vision
- **Mission:** Build a federated AML intelligence network that enables financial institutions and regulators to collaboratively detect complex money laundering typologies—especially those linked to state-sponsored actors—without sharing raw customer data.
- **Core Differentiators**
  - Combines open-source intelligence analytics (Hacksleuths pipeline) with federated learning and blockchain-backed provenance.
  - Provides regulator-grade auditability and explainability, meeting emerging AI governance requirements (EU AI Act, FATF).
  - Offers a phased decentralisation path, lowering adoption friction for initial members while charting a route to consortium-led operations.
- **End State:** A trusted network where banks, exchanges, and regulators share intelligence, co-train AML models, anchor SAR evidence, and continuously improve detection effectiveness with full legal and operational assurance.

---

## 2. Current Capabilities (Hacksleuths Stack)
- **Data Ingestion & Normalisation**
  - Scrapes and harmonises 232+ significant crypto incidents (2020–2025), covering 13,957 transactions and $11.8B in losses.
  - Ties incidents to 7,869 offshore entities via leak databases; identifies 4,713 suspicious wallets.
  - Maintains deduplication via URL hashing, SHA256 content fingerprints, and semantic matching to ensure clean corpora.
- **Word Brutality Index (WBI)**
  - NLP-based risk scoring derived from NRC VAD lexicon, capturing severity signals in incident reports.
  - Backtesting and robustness work (Phase 1 Part B) will validate predictive utility, fairness, and sensitivity to language manipulations.
- **Attribution & Graph Analytics**
  - TF-IDF, K-means, keyword scoring attribute 62.9% of DPRK incidents to APT38; emphasise bridge and ERC-20 vector patterns.
  - Graph analysis surfaces 29 high-connectivity hubs, 111 intermediary addresses, 1,372 critical paths.
  - Outputs currently anchored on Ethereum Sepolia for integrity; future migrations will use Hyperledger Fabric channels for confidentiality.
- **SAR Automation Prototype**
  - Generates draft SARs with 94.1% validation success (to be formally documented in Phase 1).
  - Provides templated outputs aligning with regulator requirements; anchors metadata for audit trails.

---

## 3. Target Architecture (Phase 1 Prototype)
- **Hyperledger Fabric Consortium Network**
  - **Organizations:** `BankA`, `BankB`, `ConsortiumOps`, `RegulatorObserver`.
  - **Channels:** `model-governance` (model registry, contribution ledger); `sar-audit` (SAR hashes via private data collections); `ops-monitoring` (operations telemetry).
  - **Ordering Service:** RAFT cluster (3 nodes) operated by trusted coordinator in Phase 1; evolves to distributed governance in later phases.
  - **Chaincode Modules:**
    - `ModelRegistry`: notarises model versions, parameters, approvals.
    - `ContributionLedger`: records federated updates, secure aggregation proofs, differential privacy budgets.
    - `SARAnchor`: stores encrypted references/hashes to SAR payloads plus timestamps and regulator acknowledgements.
  - **Identity & Security:** Fabric CAs per organisation, MSP with OU separation, short-lived cert rotation, HSM/KMS protection, mutual TLS, ACL controls, private data collections, ledger snapshot + DR policies.
- **Federated Learning Integration**
  - TensorFlow Federated / PySyft coordinator submits attested updates to Fabric.
  - Differential privacy, secure aggregation, anomaly detection guard against gradient leakage and poisoning.
  - Hooks for WBI scores, suspicious wallet intelligence, and explainability artefacts to be served via analyst APIs.
- **UX & Analyst Touchpoints**
  - Persona mapping, workflow analysis, dashboard/API prototypes showing consortium alerts, WBI explanations, and SAR workflow integration.
  - Feedback loops with pilot analysts to iterate on usability and ensure explainability.

---

## 4. Phase 1 Execution Plan (12 Weeks)
1. **Weeks 1–2:** Fabric dev cluster setup, MSP documentation, ledger snapshot policy, analyst persona interviews, cold-start expectation briefing.
2. **Weeks 3–4:** Channel creation, endorsement policies, chaincode scaffolding with CI, UX storyboards, governance participation commitments drafted.
3. **Weeks 5–6:** Federated coordinator client integration, event listeners for Hacksleuths/regulator dashboards, analyst dashboard/API prototype, data-quality schema definition.
4. **Weeks 7–8:** Monitoring stack deployment, resilience tests (peer/orderer failover, cert revocation), threat modelling workshop including nation-state scenarios.
5. **Weeks 9–10:** Simulated federated training + SAR anchoring demo, analyst usability walkthrough, preliminary performance benchmarking (TPS, latency, resource utilisation).
6. **Weeks 11–12:** Security audit prep, playbook documentation (kill switch, incident response, governance processes), WBI validation dossier assembly, steering committee readout with cold-start narrative.

**Deliverables:** Prototype network assets, security/DR runbooks, analyst UX artefacts, performance report, consortium term sheet, WBI validation report, updated risk register.

---

## 5. Consortium Term Sheet (Key Elements)
- **Cost Model:** Tiered membership fees by institution size/usage; shared infrastructure fund; options for regulator grants or strategic investment.
- **Intellectual Property:** Consortium owns global models/chaincode; members receive licences; derivatives managed via governance process.
- **Liability & Risk Sharing:** Caps and indemnities defined; incident response obligations; regulator notification protocols; kill-switch procedures.
- **Membership Lifecycle:** Onboarding requirements (technical, legal, security), offboarding terms, data retention rules, obligations to maintain historical logs.
- **Governance Participation:** Time/resource commitments from member legal, compliance, technical leads documented to set expectations on meeting cadence and workloads.
- **Phased Decentralisation Roadmap:** Pilot with trusted coordinator → growth with shared ordering/MSP → maturity with rotating operations committee and self-service onboarding.

---

## 6. Compliance & Governance Framework
- **Regulatory Alignment:** FATF Rec. 2 & 20, GDPR, bank secrecy laws, SAR confidentiality rules, EU AI Act readiness, US BSA, MiCA considerations.
- **Documentation:** Regulatory requirements matrix, DPIAs, data-sharing agreements (including SCCs), privacy impact assessments, AI governance evidence.
- **Regulator Engagement:** Observer nodes, sandbox participation, regular briefings, aim for no-objection letters; regulator dashboards built on Fabric Gateway.
- **Model Governance:** Fabric-based provenance for training runs, approvals, performance metrics; explainability artefacts accessible to analysts and regulators.
- **Training & Change Management:** Curriculum for analysts, risk officers, regulator observers covering consortium alerts, WBI interpretation, Fabric audit trails; training logs notarised on Fabric.

---

## 7. Risk Posture & Mitigations
- **Model Poisoning & Collusion:** Secure aggregation, differential privacy budgets, N-of-M endorsements, anomaly detection, red-team exercises, threat modelling updates.
- **Nation-State Adversaries:** Expanded threat model referencing DPRK retaliation; coordinated intelligence sharing (FS-ISAC, CERT partnerships); incident-response drills; protective monitoring.
- **Data Leakage & Privacy:** Private data collections, off-chain encrypted storage, geo-fenced deployments, HSM-managed keys, access logging, data minimisation policies.
- **Supply-Chain Security:** Signed container images, SBOM generation, dependency mirroring, periodic code audits, CI/CD guardrails.
- **Cold-Start Performance:** Stakeholder communications emphasise Phase 1 focus on process validation; metrics track baseline vs. projected gains as membership scales.
- **Governance Fatigue:** Transparent workload expectations; rotational committees; automation (e.g., governance dashboards) to reduce manual effort; value communication via KPI dashboards.
- **Operational Continuity:** Kill-switch playbooks, coordinator-only fallback mode, DR rehearsals, ledger snapshot recovery tests, regulator-directed isolation procedures.

---

## 8. Performance & Business Metrics
- **Technical Metrics:** Model update TPS, SAR anchoring latency, resource utilisation profiles, network resilience metrics, anomaly detection response times.
- **Business KPIs:** False-positive reduction estimates, cross-bank detection improvements, compliance-hours saved, infrastructure cost-sharing benefits, regulator satisfaction scores.
- **Reporting:** Phase 1 performance report summarising benchmarks, bottlenecks, capacity planning; executive dashboards aligning technical results with business value.
- **Cold-Start Narrative:** Document baseline metrics vs. target improvements, emphasising process validation and growth trajectory for investor/regulator briefings.

---

## 9. Change Management & Adoption
- **User Experience:** Iterative prototype feedback with analysts; highlight explainability (why an alert fired, WBI score drivers, multi-bank context).
- **Integration:** API/SDK documentation for embedding consortium alerts into legacy case-management systems; mapping to existing alert taxonomies.
- **Training:** Onboarding modules, refresher sessions, knowledge base, office hours; incorporate feedback into Phase 2 backlog.
- **Communication:** Regular stakeholder updates covering achievements, lessons, risk register status, upcoming milestones; manage expectations around cold start and phased decentralisation.

---

## 10. Roadmap Beyond Phase 1
- **Phase 2 (Growth) Priorities**
  - Onboard additional banks and regulators; transition to shared ordering service; expand feature library to multi-chain analytics (Bitcoin, L2s, CBDCs).
  - Enhance SAR automation, investigator collaboration tools, and municipality/regional channels.
  - Formalise third-party security audit, regulator sandbox milestones, AI governance certifications.
- **Phase 3 (Maturity) Goals**
  - Rotating operations governance, automated compliance checks, self-service onboarding, integration with international watchdogs.
  - Cross-consortium intelligence sharing (typology marketplaces, red-team exchange).
  - Monetisation models (compliance efficiency credits, shared analytics services) vetted by legal.

---

## 11. Responsibilities Snapshot (Phase 1)
- **ConsortiumOps:** Fabric infrastructure, data-quality services, monitoring, DR.
- **Security Engineering:** Threat modelling (including nation-state), supply-chain controls, security testing, kill-switch playbooks.
- **Data Science:** Federated learning integration, explainability artefacts, WBI validation, performance benchmarking.
- **Compliance & Legal:** Regulatory matrix, legal opinions, DPIAs, term sheet drafting, governance participation sourcing.
- **Product & UX:** Analyst personas, dashboards, workflow integration, change management.
- **PMO/Commercial:** Cold-start communications, KPI tracking, executive reporting, budget oversight.
- **Regulator Liaison:** Observer management, sandbox coordination, audit readiness.

---

## 12. Immediate Next Steps
1. Circulate this context document to all workstream leads and incorporate action items into the programme plan.
2. Update risk register with nation-state, cold-start, and governance workload items; assign owners and review weekly.
3. Finalise stakeholder communication plan (analysts, executives, regulators) covering Phase 1 milestones, expectations, and feedback loops.
4. Schedule steering committee session to confirm Phase 1 deliverables, governance commitments, and resource allocations.
