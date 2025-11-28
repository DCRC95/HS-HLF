# Chaincode Naming Reference

**Last Updated:** 2025-11-28 16:57 UTC

## Quick Reference

| Chaincode | Channel | Name | Status | Notes |
|-----------|---------|------|--------|-------|
| ModelRegistry | model-governance | `model-registry` | ✅ Operational | CaaS deployment |
| ContributionLedger | model-governance | `contribution-ledger` | ✅ Operational | CaaS deployment |
| SARAnchor | sar-audit | `sar-anchor-v2` | ✅ Operational | CaaS deployment (see note below) |

## Important: SARAnchor Uses `sar-anchor-v2` Name

**The SARAnchor chaincode is deployed as `sar-anchor-v2`, not `sar-anchor`.**

### Why?

The `sar-anchor` name has stale private data state in the channel ledger from a previous failed deployment. This prevents using the original name.

### Impact

- **Applications:** Must reference `sar-anchor-v2` when invoking chaincode
- **Scripts:** Update any scripts that reference `sar-anchor` to use `sar-anchor-v2`
- **Documentation:** All references should note the `-v2` suffix

### Example Usage

```bash
# Correct - use sar-anchor-v2
peer chaincode invoke \
  -C sar-audit \
  -n sar-anchor-v2 \
  -c '{"function":"anchorSar","Args":[...]}'

# Incorrect - sar-anchor will not work
peer chaincode invoke \
  -C sar-audit \
  -n sar-anchor \
  -c '{"function":"anchorSar","Args":[...]}'
```

### Future Options

1. **Continue using `sar-anchor-v2`** (Recommended - no disruption)
2. **Recreate sar-audit channel** (Would allow using `sar-anchor` but requires full redeployment)

## Detailed Documentation

- **SARAnchor Naming:** `chaincode/sar-anchor/README_NAMING.md`
- **Deployment Status:** `docs/caas_deployment_progress.md`
- **Handoff Context:** `AML AI NETWORK/week3-4_agent_handoff.md`

