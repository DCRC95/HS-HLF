# SARAnchor Chaincode

**Author:** Week 3-4 Implementation  
**Date:** 2025-11-28  
**Purpose:** SAR Anchor chaincode for AML AI Network  
**Requirements:** phase_1_plan_details.md:27-34, 55-64

## Overview

The SARAnchor chaincode stores encrypted references/hashes to SAR payloads, tracks submission timestamps, and regulator acknowledgements on the `sar-audit` channel. It uses private data collections for sensitive information.

## Channel & Endorsement Policy

- **Channel:** `sar-audit`
- **Organizations:** BankA, BankB, RegulatorObserver
- **Endorsement Policy:** `OR('BankAMSP.peer', 'BankBMSP.peer')`
- **Private Collections:** 
  - `sarHashes` - Banks only
  - `sarMetadata` - Banks write, Regulator read
  - `sensitiveAlerts` - Banks only, 365-day TTL

## Contract Methods

### `anchorSar(sarId, hash, metadata, timestamp)`
Anchors SAR metadata with hash reference. Writes to private data collections.

**Validation:**
- SAR ID format validation
- Hash format (SHA256)
- Timestamp validation
- Metadata structure validation

**Private Data:**
- Hash stored in `sarHashes` collection
- Metadata stored in `sarMetadata` collection

### `acknowledgeSar(sarId, regulatorId, acknowledgement)`
Records regulator acknowledgement of SAR submission.

**Validation:**
- SAR must exist
- Regulator must be RegulatorObserverMSP
- Read-only operation (no private data write)

### `getSarHash(sarId)`
Retrieves SAR hash (banks only via private data).

### `getSarMetadata(sarId)`
Retrieves SAR metadata (banks and regulator can read).

### `listSars(submitterId)`
Lists SARs submitted by a specific bank.

## Development

See ModelRegistry README for development setup instructions.

## References

- Phase 1 Plan: `phase_1_plan_details.md:27-34, 55-64`
- Channel Configuration: `configtx/configtx.yaml` (SARAuditChannel)
- Private Collections: `chaincode/SARAnchor/collections/sar_collections_config.json`
- Endorsement Policies: `docs/policy_updates/week3-4/endorsement_policies.md`

