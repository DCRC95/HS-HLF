# Endorsement Policies - Week 3-4

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Purpose:** Document endorsement policies for chaincode modules

## ModelRegistry Chaincode (model-governance channel)

**Channel:** model-governance
**Organizations:** BankA, BankB, ConsortiumOps

**Endorsement Policy:**
- Requires endorsements from BankA AND BankB
- Policy: `AND('BankAMSP.peer', 'BankBMSP.peer')`
- ConsortiumOps can optionally be included if specified

**Implementation Note:**
This policy ensures that both banks must approve model registry updates, providing mutual consent for model version registration.

## ContributionLedger Chaincode (model-governance channel)

**Channel:** model-governance
**Organizations:** BankA, BankB, ConsortiumOps

**Endorsement Policy:**
- Requires endorsements from BankA AND BankB
- Policy: `AND('BankAMSP.peer', 'BankBMSP.peer')`
- ConsortiumOps endorsement may be required for specific operations if specified

**Implementation Note:**
Federated learning updates require both banks to endorse, ensuring consensus on contribution records.

## SARAnchor Chaincode (sar-audit channel)

**Channel:** sar-audit
**Organizations:** BankA, BankB, RegulatorObserver

**Endorsement Policy:**
- Write operations: Requires endorsements from BankA OR BankB
- Policy: `OR('BankAMSP.peer', 'BankBMSP.peer')`
- Read operations: Available to all channel members including RegulatorObserver

**ACL Policy:**
- Writers: BankA, BankB (banks can submit SAR metadata)
- Readers: BankA, BankB, RegulatorObserver (regulator has read-only access)

**Implementation Note:**
Banks can independently submit SAR metadata, while regulator has read-only access for audit purposes.

