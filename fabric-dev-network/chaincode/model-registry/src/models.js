/**
 * Data Models and Validation for ModelRegistry
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Data models and validation rules (phase_1_plan_details.md:27-34)
 */

/**
 * Validates model ID format
 * @param {string} modelId - Model identifier
 * @returns {boolean} True if valid
 */
function validateModelId(modelId) {
  if (!modelId || typeof modelId !== 'string') {
    return false;
  }
  // Model ID should be alphanumeric with hyphens/underscores, 3-64 chars
  return /^[a-zA-Z0-9_-]{3,64}$/.test(modelId);
}

/**
 * Validates version format (semantic versioning)
 * @param {string} version - Version string
 * @returns {boolean} True if valid
 */
function validateVersion(version) {
  if (!version || typeof version !== 'string') {
    return false;
  }
  // Semantic versioning: major.minor.patch
  return /^\d+\.\d+\.\d+$/.test(version);
}

/**
 * Validates SHA256 hash format
 * @param {string} hash - Hash string
 * @returns {boolean} True if valid
 */
function validateHash(hash) {
  if (!hash || typeof hash !== 'string') {
    return false;
  }
  // SHA256 is 64 hex characters
  return /^[a-fA-F0-9]{64}$/.test(hash);
}

/**
 * Validates signature format
 * @param {string} signature - Signature string
 * @returns {boolean} True if valid
 */
function validateSignature(signature) {
  if (!signature || typeof signature !== 'string') {
    return false;
  }
  // Base64 encoded signature
  return /^[A-Za-z0-9+/=]+$/.test(signature) && signature.length > 0;
}

/**
 * Validates training parameters structure
 * @param {object} parameters - Training parameters
 * @returns {boolean} True if valid
 */
function validateParameters(parameters) {
  if (!parameters || typeof parameters !== 'object') {
    return false;
  }
  // Must have at least one parameter
  return Object.keys(parameters).length > 0;
}

/**
 * Compares two version strings
 * @param {string} v1 - Version 1
 * @param {string} v2 - Version 2
 * @returns {number} -1 if v1 < v2, 0 if equal, 1 if v1 > v2
 */
function compareVersions(v1, v2) {
  const parts1 = v1.split('.').map(Number);
  const parts2 = v2.split('.').map(Number);

  for (let i = 0; i < Math.max(parts1.length, parts2.length); i++) {
    const part1 = parts1[i] || 0;
    const part2 = parts2[i] || 0;
    if (part1 < part2) return -1;
    if (part1 > part2) return 1;
  }
  return 0;
}

/**
 * Creates a composite key for model version
 * @param {string} modelId - Model identifier
 * @param {string} version - Version string
 * @returns {string} Composite key
 */
function createModelKey(modelId, version) {
  return `MODEL:${modelId}:${version}`;
}

/**
 * Creates a key for model index (all versions)
 * @param {string} modelId - Model identifier
 * @returns {string} Index key
 */
function createModelIndexKey(modelId) {
  return `MODEL_INDEX:${modelId}`;
}

module.exports = {
  validateModelId,
  validateVersion,
  validateHash,
  validateSignature,
  validateParameters,
  compareVersions,
  createModelKey,
  createModelIndexKey,
};

