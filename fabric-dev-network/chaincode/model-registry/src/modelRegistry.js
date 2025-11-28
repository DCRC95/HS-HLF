/**
 * ModelRegistry Chaincode Contract
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Model registry contract implementation (phase_1_plan_details.md:27-34, 55-64)
 * Channel: model-governance
 * Endorsement Policy: AND('BankAMSP.peer', 'BankBMSP.peer')
 */

const { Contract } = require('fabric-contract-api');
const {
  validateModelId,
  validateVersion,
  validateHash,
  validateSignature,
  validateParameters,
  compareVersions,
  createModelKey,
  createModelIndexKey,
} = require('./models');

class ModelRegistry extends Contract {
  /**
   * Initialize chaincode
   */
  async initLedger(_ctx) {
    // eslint-disable-next-line no-console
    console.info('ModelRegistry chaincode initialized');
  }

  /**
   * Register a new model version
   * Channel: model-governance
   * Endorsement: Requires BankA AND BankB (enforced at chaincode definition)
   * @param {Context} ctx - Transaction context
   * @param {string} modelId - Model identifier
   * @param {string} version - Version string (semantic versioning)
   * @param {string} hash - SHA256 hash of model artifact
   * @param {string} parameters - JSON string of training parameters
   * @param {string} signature - Approval signature (base64)
   * @returns {object} Registered model information
   */
  async registerModel(ctx, modelId, version, hash, parameters, signature) {
    // Validation
    if (!validateModelId(modelId)) {
      throw new Error('Invalid model ID format');
    }
    if (!validateVersion(version)) {
      throw new Error('Invalid version format (expected semantic versioning)');
    }
    if (!validateHash(hash)) {
      throw new Error('Invalid hash format (expected SHA256)');
    }
    if (!validateSignature(signature)) {
      throw new Error('Invalid signature format');
    }

    let params;
    try {
      params = JSON.parse(parameters);
    } catch (e) {
      throw new Error('Invalid parameters JSON format');
    }
    if (!validateParameters(params)) {
      throw new Error('Parameters must be a non-empty object');
    }

    // Check version monotonicity
    const existingVersions = await this._getModelVersions(ctx, modelId);
    if (existingVersions.length > 0) {
      const latestVersion = existingVersions[existingVersions.length - 1];
      if (compareVersions(version, latestVersion) <= 0) {
        throw new Error(
          `Version ${version} must be greater than latest version ${latestVersion}`
        );
      }
    }

    // Check if version already exists
    const modelKey = createModelKey(modelId, version);
    const existing = await ctx.stub.getState(modelKey);
    if (existing && existing.length > 0) {
      throw new Error(`Model ${modelId} version ${version} already exists`);
    }

    // Get submitter information
    const submitterMSP = ctx.clientIdentity.getMSPID();
    const submitterId = ctx.clientIdentity.getID();

    // Create model record
    const modelRecord = {
      modelId,
      version,
      hash,
      parameters: params,
      signature,
      submitterMSP,
      submitterId,
      timestamp: new Date().toISOString(),
      approvals: [
        {
          mspId: submitterMSP,
          signature,
          timestamp: new Date().toISOString(),
        },
      ],
    };

    // Save model record
    await ctx.stub.putState(modelKey, Buffer.from(JSON.stringify(modelRecord)));

    // Update model index
    await this._updateModelIndex(ctx, modelId, version);

    // Emit event
    ctx.stub.setEvent('ModelRegistered', Buffer.from(JSON.stringify(modelRecord)));

    return modelRecord;
  }

  /**
   * Approve a model version
   * Channel: model-governance
   * Endorsement: Requires BankA AND BankB (enforced at chaincode definition)
   * @param {Context} ctx - Transaction context
   * @param {string} modelId - Model identifier
   * @param {string} version - Version string
   * @param {string} signature - Approval signature (base64)
   * @returns {object} Updated model information
   */
  async approveModel(ctx, modelId, version, signature) {
    // Validation
    if (!validateModelId(modelId)) {
      throw new Error('Invalid model ID format');
    }
    if (!validateVersion(version)) {
      throw new Error('Invalid version format');
    }
    if (!validateSignature(signature)) {
      throw new Error('Invalid signature format');
    }

    // Get existing model
    const modelKey = createModelKey(modelId, version);
    const existing = await ctx.stub.getState(modelKey);
    if (!existing || existing.length === 0) {
      throw new Error(`Model ${modelId} version ${version} does not exist`);
    }

    const modelRecord = JSON.parse(existing.toString());

    // Get approver information
    const approverMSP = ctx.clientIdentity.getMSPID();
    // const approverId = ctx.clientIdentity.getID(); // Reserved for future use

    // Validate approver is BankA or BankB
    if (approverMSP !== 'BankAMSP' && approverMSP !== 'BankBMSP') {
      throw new Error('Only BankA or BankB can approve models');
    }

    // Check if already approved by this MSP
    const existingApproval = modelRecord.approvals.find(
      (a) => a.mspId === approverMSP
    );
    if (existingApproval) {
      throw new Error(`Model already approved by ${approverMSP}`);
    }

    // Add approval
    modelRecord.approvals.push({
      mspId: approverMSP,
      signature,
      timestamp: new Date().toISOString(),
    });

    // Save updated model record
    await ctx.stub.putState(modelKey, Buffer.from(JSON.stringify(modelRecord)));

    // Emit event
    ctx.stub.setEvent('ModelApproved', Buffer.from(JSON.stringify(modelRecord)));

    return modelRecord;
  }

  /**
   * Get model information
   * Channel: model-governance
   * @param {Context} ctx - Transaction context
   * @param {string} modelId - Model identifier
   * @param {string} version - Version string
   * @returns {object} Model information
   */
  async getModel(ctx, modelId, version) {
    if (!validateModelId(modelId)) {
      throw new Error('Invalid model ID format');
    }
    if (!validateVersion(version)) {
      throw new Error('Invalid version format');
    }

    const modelKey = createModelKey(modelId, version);
    const modelBytes = await ctx.stub.getState(modelKey);

    if (!modelBytes || modelBytes.length === 0) {
      throw new Error(`Model ${modelId} version ${version} does not exist`);
    }

    return JSON.parse(modelBytes.toString());
  }

  /**
   * List all versions of a model
   * Channel: model-governance
   * @param {Context} ctx - Transaction context
   * @param {string} modelId - Model identifier
   * @returns {string[]} Array of version strings
   */
  async listModels(ctx, modelId) {
    if (!validateModelId(modelId)) {
      throw new Error('Invalid model ID format');
    }

    const versions = await this._getModelVersions(ctx, modelId);
    return versions;
  }

  /**
   * Get all model versions (internal helper)
   * @private
   */
  async _getModelVersions(ctx, modelId) {
    const indexKey = createModelIndexKey(modelId);
    const indexBytes = await ctx.stub.getState(indexKey);

    if (!indexBytes || indexBytes.length === 0) {
      return [];
    }

    const index = JSON.parse(indexBytes.toString());
    return index.versions || [];
  }

  /**
   * Update model index (internal helper)
   * @private
   */
  async _updateModelIndex(ctx, modelId, version) {
    const indexKey = createModelIndexKey(modelId);
    const indexBytes = await ctx.stub.getState(indexKey);

    let index;
    if (!indexBytes || indexBytes.length === 0) {
      index = { modelId, versions: [] };
    } else {
      index = JSON.parse(indexBytes.toString());
    }

    if (!index.versions.includes(version)) {
      index.versions.push(version);
      // Sort versions
      index.versions.sort(compareVersions);
    }

    await ctx.stub.putState(indexKey, Buffer.from(JSON.stringify(index)));
  }
}

module.exports = ModelRegistry;

