# Phase 1 Execution Plan: Consortium-Ready Foundations

This revision aligns Phase 1 with the requirements of a regulated AML intelligence consortium: pragmatic Hyperledger Fabric architecture, integration hooks for federated learning, robust security controls, and defensible model validation.

---

## Part A: Hyperledger Fabric Consortium Prototype

### 1. Objectives
- Deliver a proof-of-concept Fabric network that mirrors future consortium operations (banks, regulator observers, model registry services).
- Demonstrate end-to-end flow: federated model updates notarised on Fabric, suspicious wallet intelligence shared via private data collections, regulator read-only access.
- Establish operational practices (identity management, monitoring, CI/CD) that scale into Phase 2 pilots.
- Validate analyst-facing interaction patterns and UX artefacts to ensure human-in-the-loop adoption.

### 2. Architecture Blueprint
- **Network Topology**
  - Ordering service: RAFT cluster (3 nodes) hosted across consortium cloud regions for fault tolerance.
  - Organizations: `BankA`, `BankB`, `ConsortiumOps`, `RegulatorObserver`. Each owns at least two peers (endorser + ledger replica).
  - Channels:
    - `model-governance`: Banks + ConsortiumOps; holds chaincode for model registry and contribution ledger.
    - `sar-audit`: Banks + RegulatorObserver; uses private data collections for SAR hashes and metadata.
    - `ops-monitoring`: ConsortiumOps only; aggregates health metrics and chaincode deployment approvals.
- **Identity & MSP**
  - Fabric CA per organization issuing TLS/signing certs; enforce short-lived certificates and automated rotation.
  - MSP definitions include client OU separation (peers, admins, application users, regulator auditors).
  - Hardware-backed key storage (HSM or cloud KMS) for ordering nodes and critical peers.
- **Chaincode Modules**
  - `ModelRegistry` (Node.js): records model hash, version, training parameters, approval signatures.
  - `ContributionLedger` (Node.js): logs federated model updates, secure-aggregation proofs, differential privacy budgets.
  - `SARAnchor` (Go or Node.js): stores encrypted references/hashes to SAR payloads, tracks submission timestamps, regulator acknowledgement.
  - Access control rules (fabric-contract API + endorsement policies) enforcing N-of-M bank approvals before registry updates.
- **Integration Points**
  - Federated learning coordinator (TensorFlow Federated/PySyft) signs update attestations and submits to `ContributionLedger`.
  - Hacksleuths analytics push suspicious wallet/entity events to `model-governance` channel; banks pull via Fabric SDK for local alert enrichment.
  - Regulator observer applications consume events via Fabric Gateway in read-only mode with filtered blocks.

### 3. Tooling & Infrastructure
- **Runtime & Orchestration**
  - Docker Compose for developer environment; plan Helm charts/Kubernetes manifests for pilot readiness.
  - Fabric Operations Console or Ansible playbooks for lifecycle management and monitoring.
  - Prometheus + Grafana for peer/orderer metrics; Loki/ELK for log aggregation; integrate with consortium SIEM.
- **Development Stack**
  - Node.js LTS for chaincode SDK and Gateway client; Go 1.20+ optional for performance-sensitive modules.
  - Fabric Gateway SDK (Node.js) for application services and federated coordinator integration.
  - GitOps pipeline (GitHub Actions/GitLab CI) to package chaincode, sign artifacts, deploy via automation.
- **Security Baseline**
  - Mutual TLS everywhere; enforce Fabric ACLs for channel access, chaincode invocation, and event listeners.
  - Container hardening (minimal base images, runtime scanning), secrets management via HashiCorp Vault or cloud equivalents.
  - Backup/DR strategy: periodic ledger snapshots, state database backups, orderer block archival validated through hash checks.
- **UX & Integration Toolkit**
  - Low-code prototyping tools (Figma, Balsamiq) for dashboard and workflow mockups.
  - Fabric Gateway API specifications for consuming alerts and SAR metadata inside bank case-management systems.
  - UX research plan capturing analyst personas, workflow mapping, and feedback loops from compliance teams.

### 4. Implementation Steps
1. **Week 1–2 Foundations**
   - Stand up dev cluster using Fabric test network as reference; replace crypto material with Fabric CA issuance.
   - Document MSP hierarchy, certificate rotation process, and ledger snapshot policy.
   - Kick off analyst workflow discovery sessions and create initial persona definitions.
2. **Week 3–4 Channel & Chaincode Setup**
   - Create consortium channels, define endorsement policies, and configure private data collections with collection-level policies.
   - Scaffold chaincode repositories with unit tests, linting, and CI packaging.
   - Draft analyst UX storyboards showing alert ingestion, investigative steps, and SAR initiation.
3. **Week 5–6 Integration Hooks**
   - Implement Fabric client for federated coordinator (secure gRPC or REST) to submit update attestations.
   - Configure event listeners feeding Hacksleuths analytics pipeline and regulator dashboards.
   - Build functional prototype (API or lightweight dashboard) that surfaces consortium alerts to analyst workflow; gather feedback from pilot banks.
4. **Week 7–8 Security & Observability**
   - Deploy monitoring stack, configure alert thresholds (peer down, endorsement failure, chaincode errors).
   - Run basic resilience tests: peer failover, orderer restart, certificate revocation workflow.
5. **Week 9–10 Consortium Demo**
   - Execute simulated federated training round with synthetic AML data; notarise model version, record contributions, and publish suspicious wallet event.
   - Submit synthetic SAR metadata through `SARAnchor` chaincode and demonstrate regulator read-only access.
   - Conduct analyst usability walkthrough; document feedback, required refinements, and adoption risks.
6. **Week 11–12 Review & Hardening**
   - Audit chaincode access logs, validate MSP compliance, document playbooks, and prep for external pen test scheduling.
   - Finalise UX artefacts (personas, wireframes, API specs) and align change requests with Phase 2 backlog.

### 5. Reference Material
- Hyperledger Fabric Docs (Operations, CA, Private Data Collections, Gateway SDK).
- Hyperledger Labs projects relevant to model provenance (e.g., Blockchain Automation Framework).
- Consortium security standards: NIST CSF, ISO 27001, MAS TRM for alignment checks.
- UX and AML workflow references: ACAMS typology guides, bank case-management integration patterns, FATF guidance on human oversight of AML systems.

---

## Part B: Word Brutality Index (WBI) Validation Program

### 1. Objectives
- Produce a validation dossier proving WBI’s predictive utility, robustness, and fairness for regulator and consortium adoption.
- Establish governance for ongoing recalibration and integration into federated models.

### 2. Experimental Design
- **Dataset Construction**
  - Assemble labelled incident corpus (>=300 hacks) with severity outcomes (loss amounts, regulatory actions, typology categories).
  - Document data provenance, cleaning steps, and licensing; store hashes on Fabric `model-governance` channel.
- **Backtesting Protocol**
  - Split data into temporal folds; compute metrics (ROC-AUC, precision/recall at defined thresholds, calibration curves).
  - Compare WBI-driven prioritisation against baseline heuristics (e.g., loss-based scoring, keyword counts).
- **Robustness & Bias Analysis**
  - Evaluate sensitivity to adversarial wording changes and language variance; run perturbation tests.
  - Measure fairness across regions/actor types; report statistical parity/false-negative differences.
- **Human-in-the-loop Evaluation**
  - Engage AML analysts to score sample incidents; measure inter-rater reliability against WBI outputs (Cohen’s kappa).
  - Capture qualitative feedback to refine lexicon weighting.

### 3. Tooling & Workflow
- Python, Pandas, NumPy, scikit-learn, Jupyter for analysis.
- MLflow or Weights & Biases for experiment tracking; log experiment metadata to Fabric `ModelRegistry`.
- Automated report generation (Jupyter Book or Sphinx) with reproducible notebooks archived in consortium repo.

### 4. Peer Review & Governance
- Convene external advisory panel (academic, RegTech, former FIU experts); provide methodology package and anonymised datasets.
- Track review comments, required changes, and resolutions; notarise final approvals on Fabric for audit traceability.
- Define change-management policy: trigger thresholds for retraining, approval workflow, and versioning semantics aligned with consortium MLOps.

### 5. Communication & Visualisation
- Develop dashboards translating WBI scores into risk tiers with explanations (top linguistic drivers).
- Provide API schema for banks to ingest WBI outputs with context (confidence intervals, contributing factors).
- Produce executive summary and compliance briefing tying WBI validation to AML regulatory expectations.

---

## Part C: Consortium Operating Model & Decentralisation Roadmap

### 1. Consortium Term Sheet (Phase 1 Deliverable)
- **Cost Model**
  - Define baseline budget for core infrastructure, security, and ongoing operations.
  - Propose tiered membership fees (e.g., based on transaction volume or institution size) and cost-sharing for enhancements.
  - Include financing options (grants, regulator sponsorship, strategic investors) and reserve fund policy.
- **Intellectual Property**
  - Establish ownership of federated global models, chaincode modules, and analytics outputs.
  - Outline licensing terms back to members and policies for derivative works.
- **Liability & Risk Sharing**
  - Define liability caps, indemnification clauses, and loss-sharing mechanisms if global models miss significant events.
  - Document incident response obligations, regulator notification duties, and dispute resolution procedures.
- **Membership Lifecycle**
  - Onboarding requirements (due diligence, technical readiness, legal agreements) and associated costs.
  - Offboarding process, data retention/withdrawal rules, and obligations to maintain historical logs.
- **Governance**
  - Draft committee structure (steering, technical, compliance, regulatory advisory) with voting rights and escalation paths.
  - Align with phased decentralisation roadmap and the regulatory engagement plan.
  - Document expected governance participation commitments (time and resource contributions) per member to set transparent expectations.

### 2. Phased Decentralisation Strategy
- **Phase 1 (Pilot)**
  - Product company acts as trusted coordinator managing ordering service and federated aggregator.
  - Fabric used for notarisation, provenance, and access auditing; governance relatively centralised.
  - Document API/service boundaries to allow future delegation of responsibilities.
- **Phase 2 (Growth)**
  - Subset of banks and regulator observers operate distributed RAFT orderers and share MSP administration.
  - Endorsement policies evolve to reflect multi-party control; trusted coordinator role shifts to facilitation.
  - Introduce consortium voting on chaincode upgrades and model deployment approvals.
- **Phase 3 (Maturity)**
  - Fully distributed governance with rotating operations committee, automated compliance checks, and self-service onboarding flows.
  - Integration with additional ledgers (CBDC nodes, cross-border regulators) under harmonised policies.
- **Transition Hooks**
  - Define technical and contractual preconditions to move between phases (audit completions, membership thresholds, SLA adherence).
  - Maintain change logs on Fabric to prove compliance with evolving governance.

### 3. Performance & Scalability Benchmarking
- **Metrics**
  - Model update registration TPS and end-to-end latency (submission to notarisation).
  - SAR anchoring latency and throughput under concurrent submissions.
  - Resource utilisation on member infrastructure (CPU, memory, storage, bandwidth during training rounds and chaincode invocations).
  - Network resilience (failover recovery time, catch-up performance for lagging peers).
  - Cold-start performance metrics noting expected limited uplift with initial pilot participants versus projected gains as membership scales.
- **Test Plan**
  - Synthetic workload generator to simulate varying numbers of member contributions (5, 20, 50 banks).
  - Stress tests combining federated learning rounds with SAR anchoring bursts to evaluate contention.
  - Document instrumentation (Prometheus metrics, custom telemetry) and thresholds for acceptable performance.
- **Reporting**
  - Produce Phase 1 performance report summarising results, bottlenecks, and capacity planning recommendations.
  - Communicate cold-start expectations to stakeholders, emphasising validation of secure collaboration in Phase 1 and growth-driven performance in later phases.
  - Use findings to update Phase 2 scaling roadmap and inform consortium term-sheet commitments.

---

## Deliverables & Success Criteria
- Fabric consortium prototype with documented architecture, security controls, and demonstrable federated-model workflow.
- Monitoring, logging, and DR playbooks reviewed by security lead; remediation plan for identified gaps.
- Analyst workflow artefacts (personas, wireframes, API specs) validated with pilot institutions and linked to adoption assumptions.
- Performance benchmarking report covering TPS, latency, and infrastructure load, signed off by consortium engineering lead.
- Consortium Term Sheet outlining cost model, IP ownership, liability framework, onboarding/offboarding process, and phased decentralisation roadmap.
- WBI validation report with statistical evidence, peer-review sign-off, and governance charter ready for regulator review.
- Updated risk register reflecting prototype learnings, with mitigation owners tracked against Phase 1 timeline.
- Threat modelling documentation incorporating nation-state adversaries and cold-start assumptions, reviewed with security governance.
