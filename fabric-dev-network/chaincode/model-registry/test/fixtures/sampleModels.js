/**
 * Test Fixtures for ModelRegistry
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Test data fixtures (phase_1_plan_details.md:62)
 */

module.exports = {
  validModel: {
    modelId: 'aml-model-v1',
    version: '1.0.0',
    hash: 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    parameters: {
      learningRate: 0.001,
      batchSize: 32,
      epochs: 100,
    },
    signature: 'dGVzdF9zaWduYXR1cmU=',
  },

  validModelV2: {
    modelId: 'aml-model-v1',
    version: '1.0.1',
    hash: 'b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef12345678',
    parameters: {
      learningRate: 0.001,
      batchSize: 32,
      epochs: 100,
    },
    signature: 'dGVzdF9zaWduYXR1cmUy',
  },

  invalidModelId: {
    modelId: 'ab', // Too short
    version: '1.0.0',
    hash: 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    parameters: {},
    signature: 'dGVzdF9zaWduYXR1cmU=',
  },

  invalidVersion: {
    modelId: 'aml-model-v1',
    version: 'invalid',
    hash: 'a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456',
    parameters: {},
    signature: 'dGVzdF9zaWduYXR1cmU=',
  },

  invalidHash: {
    modelId: 'aml-model-v1',
    version: '1.0.0',
    hash: 'invalid-hash',
    parameters: {},
    signature: 'dGVzdF9zaWduYXR1cmU=',
  },
};

