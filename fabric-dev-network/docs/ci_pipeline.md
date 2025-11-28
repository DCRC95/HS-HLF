# CI Pipeline Documentation

**Author:** Week 3-4 Implementation  
**Date:** 2025-11-28  
**Purpose:** CI pipeline documentation (phase_1_plan_details.md:62, 73-77)

## Overview

CI pipelines for all three chaincode modules (ModelRegistry, ContributionLedger, SARAnchor) are configured using GitHub Actions. Each pipeline includes linting, testing, packaging, and SBOM generation.

## Pipeline Stages

### 1. Lint
- Runs ESLint on all source and test files
- Enforces code style and catches common errors
- Fails build on linting errors

### 2. Test
- Runs Jest test suite
- Generates coverage reports
- Uploads coverage to codecov (ModelRegistry)
- Archives test results as artifacts

### 3. Package
- Creates chaincode package (tar.gz)
- Generates SBOM (Software Bill of Materials) using Anchore
- Uploads packages and SBOMs to artifacts

## Workflow Files

- `.github/workflows/chaincode-model-registry.yml`
- `.github/workflows/chaincode-contribution-ledger.yml`
- `.github/workflows/chaincode-sar-anchor.yml`

## Artifacts

All artifacts are stored in:
- `artifacts/chaincode/<module>/`

Generated artifacts:
- Chaincode package: `<module>-<commit-sha>.tgz`
- SBOM: `<module>-sbom.json`

## Signing & Approval

Chaincode packages are signed during deployment using admin certificates. Approval signatures are captured in deployment logs.

## Logs

CI execution logs are available in:
- GitHub Actions workflow runs
- `logs/ci/week3-4_chaincode_ci.log` (deployment logs)

## References

- Phase 1 Plan: `phase_1_plan_details.md:62, 73-77`
- Chaincode Deployment: `docs/dev_deploy_week3-4.md`

