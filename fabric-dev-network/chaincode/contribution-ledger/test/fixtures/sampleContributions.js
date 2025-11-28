/**
 * Test Fixtures for ContributionLedger
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Test data fixtures (phase_1_plan_details.md:62)
 */

module.exports = {
  validContribution: {
    roundId: 'round-001',
    contributorId: 'bank-a-contributor-1',
    updateHash: 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    aggregationProof: {
      method: 'secure-aggregation',
      proof: 'proof-data',
    },
    privacyBudget: '0.5',
  },

  invalidRoundId: {
    roundId: 'ab',
    contributorId: 'contributor-1',
    updateHash: 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    aggregationProof: {},
    privacyBudget: '0.5',
  },

  negativePrivacyBudget: {
    roundId: 'round-001',
    contributorId: 'contributor-1',
    updateHash: 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    aggregationProof: {},
    privacyBudget: '-0.5',
  },
};

