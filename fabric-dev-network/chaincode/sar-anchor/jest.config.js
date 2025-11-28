/**
 * Jest configuration for SARAnchor chaincode tests
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Test configuration for SARAnchor chaincode (phase_1_plan_details.md:62)
 */
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: '../../reports/tests/week3-4_chaincode/sar-anchor/coverage',
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

