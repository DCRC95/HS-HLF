# ModelRegistry Contract Specification

**Author:** Week 3-4 Implementation  
**Date:** 2025-11-28  
**Purpose:** Contract specification for ModelRegistry (phase_1_plan_details.md:27-34, 55-64)

## Overview

The ModelRegistry contract records model hash, version, training parameters, and approval signatures on the `model-governance` channel.

## Channel & Endorsement

- **Channel:** model-governance
- **Organizations:** BankA, BankB, ConsortiumOps
- **Endorsement Policy:** `AND('BankAMSP.peer', 'BankBMSP.peer')`
- **Requirement:** phase_1_plan_details.md:27-34

## Contract Methods

### registerModel

Registers a new model version with hash, training parameters, and approval signature.

**Parameters:**
- `modelId` (string): Model identifier (3-64 alphanumeric chars)
- `version` (string): Semantic version (major.minor.patch)
- `hash` (string): SHA256 hash of model artifact (64 hex chars)
- `parameters` (string): JSON string of training parameters
- `signature` (string): Base64 encoded approval signature

**Validation:**
- Model ID format validation
- Version monotonicity (must be greater than latest version)
- Hash format validation (SHA256)
- Signature format validation
- Parameters must be non-empty JSON object

**Endorsement:** Requires BankA AND BankB (enforced at chaincode definition)

**Events:** Emits `ModelRegistered` event

### approveModel

Records approval signature for a model version from a bank.

**Parameters:**
- `modelId` (string): Model identifier
- `version` (string): Version string
- `signature` (string): Base64 encoded approval signature

**Validation:**
- Model version must exist
- Approver must be BankA or BankB
- Cannot approve twice from same MSP

**Endorsement:** Requires BankA AND BankB (enforced at chaincode definition)

**Events:** Emits `ModelApproved` event

### getModel

Retrieves model information including hash, parameters, and approval signatures.

**Parameters:**
- `modelId` (string): Model identifier
- `version` (string): Version string

**Returns:** Model record with all metadata

### listModels

Lists all versions of a model.

**Parameters:**
- `modelId` (string): Model identifier

**Returns:** Array of version strings (sorted)

## Data Models

### Model Record

```json
{
  "modelId": "string",
  "version": "string",
  "hash": "string",
  "parameters": {},
  "signature": "string",
  "submitterMSP": "string",
  "submitterId": "string",
  "timestamp": "ISO8601",
  "approvals": [
    {
      "mspId": "string",
      "signature": "string",
      "timestamp": "ISO8601"
    }
  ]
}
```

## Design Decisions

1. **Version Monotonicity:** Enforced to prevent version conflicts
2. **N-of-M Endorsements:** Both banks must approve (requirement: phase_1_plan_details.md:31)
3. **Composite Keys:** Used for efficient querying (`MODEL:<modelId>:<version>`)
4. **Index Structure:** Maintains version list per model for fast listing

## References

- Phase 1 Plan: `phase_1_plan_details.md:27-34, 55-64`
- Channel Config: `configtx/configtx.yaml` (ModelGovernanceChannel)
- Endorsement Policy: `docs/policy_updates/week3-4/endorsement_policies.md`

