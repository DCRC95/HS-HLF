/**
 * Jest configuration for ContributionLedger chaincode tests
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Test configuration for ContributionLedger chaincode (phase_1_plan_details.md:62)
 */
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: '../../reports/tests/week3-4_chaincode/contribution-ledger/coverage',
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/index.js',
  ],
  testMatch: [
    '**/test/**/*.test.js',
  ],
  coverageReporters: ['text', 'lcov', 'html', 'json'],
  verbose: true,
};

