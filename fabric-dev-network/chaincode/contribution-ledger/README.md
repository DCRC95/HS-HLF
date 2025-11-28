# ContributionLedger Chaincode

**Author:** Week 3-4 Implementation  
**Date:** 2025-11-28  
**Purpose:** Contribution ledger chaincode for AML AI Network  
**Requirements:** phase_1_plan_details.md:27-34, 55-64

## Overview

The ContributionLedger chaincode logs federated model updates, secure-aggregation proofs, and differential privacy budgets on the `model-governance` channel. It records contributions from federated learning rounds.

## Channel & Endorsement Policy

- **Channel:** `model-governance`
- **Organizations:** BankA, BankB, ConsortiumOps
- **Endorsement Policy:** `AND('BankAMSP.peer', 'BankBMSP.peer')`
- **Private Collections:** None (standard channel policies)

## Contract Methods

### `logContribution(roundId, contributorId, updateHash, aggregationProof, privacyBudget)`
Logs a federated learning contribution with update hash, aggregation proof, and privacy budget.

**Validation:**
- Round ID format validation
- Contributor ID validation
- Update hash format (SHA256)
- Aggregation proof structure
- Privacy budget validation (non-negative)

### `getContribution(roundId, contributorId)`
Retrieves a specific contribution record.

### `listContributions(roundId)`
Lists all contributions for a federated learning round.

### `getRoundSummary(roundId)`
Gets summary statistics for a federated learning round.

## Development

See ModelRegistry README for development setup instructions.

## References

- Phase 1 Plan: `phase_1_plan_details.md:27-34, 55-64`
- Channel Configuration: `configtx/configtx.yaml` (ModelGovernanceChannel)
- Endorsement Policies: `docs/policy_updates/week3-4/endorsement_policies.md`

