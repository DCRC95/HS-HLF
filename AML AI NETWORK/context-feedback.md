# Context: AML AI Network Assessment

## Product Whitepaper — Strengths
- Demonstrates an end-to-end investigative pipeline that unifies web scraping, NLP, machine learning, and graph analytics, showing a realistic workflow regulators understand.
- Provides quantitative scope (232 incidents, 13k transactions, $11.8B losses) that helps frame market impact and positions the product as data-rich.
- Clear attribution focus on DPRK actors with clustering, WBI scoring, and SAR automation claims helps differentiate from generic AML analytics.
- Strong operational detail (deduplication logic, sentiment/WBI methodology, graph hub detection) signals engineering depth and reproducibility intent.
- Anchoring datasets on-chain (Ethereum Sepolia) underscores tamper-evidence and auditability, aligning with compliance narratives.

## Product Whitepaper — Risks & Gaps
- Reliance on scraped OSINT plus offshore leak matching lacks explanation of legal rights to process and share that data; regulators will scrutinize provenance and privacy.
- Word Brutality Index (WBI) methodology, while novel, lacks validation proof and could be challenged as subjective or biased in risk scoring.
- Claims of 94.1% SAR validation success lack experimental design details; without benchmarks, confidence intervals, or third-party validation they may sound aspirational rather than demonstrable.
- Storing sensitive intelligence on a public testnet conflicts with confidentiality requirements for SAR-related data; needs a privacy-preserving or permissioned alternative.
- Bridge attack coverage is strong, but operational response (takedown guidance, wallet monitoring SLAs, alerting workflows) is thin, which could worry institutional buyers.
- Limited discussion of adversarial resilience (model poisoning, false positives, investigator feedback loops) leaves gaps in explainability and accountability expectations from supervisors.

## Federated AML AI Network — Strengths
- Correctly identifies the core pain point (cross-institution visibility) and articulates how federated learning unlocks collective intelligence without raw data exchange.
- Implementation outline covers lifecycle (model design, coordination, privacy tech, governance, integration) with practical nods to MPC, differential privacy, and incentive levers.
- Market narrative references real precedents (Consilient) and regulatory appetite, which supports commercial viability discussions.
- Thoughtful privacy mitigations (permissioned ledgers, off-chain encrypted storage, TEE/ZKP options) show awareness of SAR secrecy obligations.

## Federated AML AI Network — Risks & Gaps
- Threat model for collusion or data/model poisoning is under-specified; needs commitment to secure aggregation, differential privacy budgets, and participant vetting protocols.
- Governance description lacks clarity on liability, audit rights, and dispute resolution—critical for consortium setups under FATF, GDPR, and bank secrecy regimes.
- Technical architecture oscillates between smart-contract aggregation and central servers without analysing throughput, consensus latency, or rollback procedures.
- Incentive and reputation systems could expose sensitive supervisory signals; needs clearer policy on what metadata may be shared and how regulators consume it.
- Integration path omits how legacy AML case managers consume federated outputs, how alerts map to SAR obligations, and how human investigators remain in the loop.
- No roadmap for certification, external assurance, or regulator sandbox engagement—key for earning trust before production deployment.

## Hyperledger Fabric Considerations
- Replace public-chain anchoring with Fabric channels to segregate regulator, bank, and investigative views; use private data collections for SAR payloads and hashes for auditability.
- Leverage Fabric’s endorsement policies to encode contribution thresholds (e.g., require N-of-M bank signatures before model updates are accepted) to mitigate poisoning.
- Integrate federated-learning coordinator off-chain (e.g., TensorFlow Federated) with Fabric chaincode acting as notarisation, model version registry, and incentive ledger.
- Adopt Fabric CA for identity management, mapping to bank-issued certificates and regulator observers; align MSP roles with legal accountability.
- Design for interoperability by exposing Fabric events to legacy AML case management systems and to any Ethereum-based analytics modules retained from the whitepaper stack.
- Run early POC in a regulator sandbox or innovation hub to validate privacy controls, consent management, and incident response before scaling membership.

## Immediate Next Questions
- What legal basis (contracts, consent, data minimisation) underpins OSINT/offshore data ingestion, and how will it translate when moving to Fabric?
- Which regulators or FIUs are target launch partners, and how will they access or supervise the Fabric network?
- How will the product evidence model explainability and investigator accountability when federated outputs differ from legacy alerts?
