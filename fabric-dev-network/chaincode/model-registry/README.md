# ModelRegistry Chaincode

**Author:** Week 3-4 Implementation  
**Date:** 2025-11-28  
**Purpose:** Model registry chaincode for AML AI Network  
**Requirements:** phase_1_plan_details.md:27-34, 55-64

## Overview

The ModelRegistry chaincode records model hash, version, training parameters, and approval signatures on the `model-governance` channel. It enforces N-of-M bank endorsements before registry updates.

## Channel & Endorsement Policy

- **Channel:** `model-governance`
- **Organizations:** BankA, BankB, ConsortiumOps
- **Endorsement Policy:** `AND('BankAMSP.peer', 'BankBMSP.peer')`
- **Private Collections:** None (standard channel policies)

## Contract Methods

### `registerModel(modelId, version, hash, parameters, signature)`
Registers a new model version with hash, training parameters, and approval signature.

**Validation:**
- Model ID format validation
- Version monotonicity check
- Hash format validation (SHA256)
- Signature verification

### `approveModel(modelId, version, approverMSP, signature)`
Records approval signature for a model version from a bank.

**Validation:**
- Model version must exist
- Approver must be BankA or BankB
- Signature must be valid

### `getModel(modelId, version)`
Retrieves model information including hash, parameters, and approval signatures.

### `listModels(modelId)`
Lists all versions of a model.

## Development

### Prerequisites
- Node.js >= 18.0.0
- npm >= 9.0.0

### Installation
```bash
npm install
```

### Testing
```bash
npm test
npm run test:watch
```

### Linting
```bash
npm run lint
npm run lint:fix
```

### Formatting
```bash
npm run format
```

## Project Structure

```
model-registry/
├── src/
│   ├── index.js           # Chaincode entry point
│   ├── modelRegistry.js   # Main contract class
│   └── models.js          # Data models and validation
├── test/
│   ├── fixtures/          # Test fixtures
│   └── modelRegistry.test.js
├── scripts/               # Deployment scripts
├── package.json
├── jest.config.js
├── .eslintrc.json
├── .prettierrc
└── README.md
```

## References

- Phase 1 Plan: `phase_1_plan_details.md:27-34, 55-64`
- Channel Configuration: `configtx/configtx.yaml` (ModelGovernanceChannel)
- Endorsement Policies: `docs/policy_updates/week3-4/endorsement_policies.md`

