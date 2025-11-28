/**
 * Test Fixtures for SARAnchor
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Test data fixtures (phase_1_plan_details.md:62)
 */

module.exports = {
  validSar: {
    sarId: 'sar-2025-001',
    hash: 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    metadata: {
      submissionDate: '2025-11-28',
      amount: 10000,
      currency: 'USD',
      entityType: 'individual',
    },
    timestamp: '2025-11-28T12:00:00Z',
  },

  invalidSarId: {
    sarId: 'ab',
    hash: 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    metadata: {},
    timestamp: '2025-11-28T12:00:00Z',
  },
};

