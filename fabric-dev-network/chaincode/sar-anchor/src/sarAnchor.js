/**
 * SARAnchor Chaincode Contract
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: SAR anchor contract implementation (phase_1_plan_details.md:27-34, 55-64)
 * Channel: sar-audit
 * Endorsement Policy: OR('BankAMSP.peer', 'BankBMSP.peer')
 * Private Collections: sarHashes, sarMetadata, sensitiveAlerts
 */

const { Contract } = require('fabric-contract-api');

/**
 * Validates SAR ID format
 */
function validateSarId(sarId) {
  return sarId && typeof sarId === 'string' && /^[a-zA-Z0-9_-]{3,64}$/.test(sarId);
}

/**
 * Validates SHA256 hash format
 */
function validateHash(hash) {
  return hash && typeof hash === 'string' && /^[a-fA-F0-9]{64}$/.test(hash);
}

/**
 * Creates SAR key
 */
function createSarKey(sarId) {
  return `SAR:${sarId}`;
}

/**
 * Creates submitter index key
 */
function createSubmitterIndexKey(submitterId) {
  return `SUBMITTER_INDEX:${submitterId}`;
}

class SARAnchor extends Contract {
  async initLedger(_ctx) {
    // eslint-disable-next-line no-console
    console.info('SARAnchor chaincode initialized');
  }

  /**
   * Anchor SAR metadata with hash reference
   * Channel: sar-audit
   * Endorsement: OR('BankAMSP.peer', 'BankBMSP.peer') - either bank can submit
   * Private Data: Writes to sarHashes and sarMetadata collections
   * @param {Context} ctx - Transaction context
   * @param {string} sarId - SAR identifier
   * @param {string} hash - SHA256 hash of SAR payload
   * @param {string} metadata - JSON string of SAR metadata
   * @param {string} timestamp - ISO timestamp string
   * @returns {object} SAR record
   */
  async anchorSar(ctx, sarId, hash, metadata, timestamp) {
    // Validation
    if (!validateSarId(sarId)) {
      throw new Error('Invalid SAR ID format');
    }
    if (!validateHash(hash)) {
      throw new Error('Invalid hash format (expected SHA256)');
    }

    let meta;
    try {
      meta = JSON.parse(metadata);
    } catch (e) {
      throw new Error('Invalid metadata JSON format');
    }

    // Validate timestamp
    const ts = timestamp || new Date().toISOString();
    if (isNaN(Date.parse(ts))) {
      throw new Error('Invalid timestamp format');
    }

    // Get submitter information
    const submitterMSP = ctx.clientIdentity.getMSPID();
    const submitterId = ctx.clientIdentity.getID();

    // Validate submitter is BankA or BankB
    if (submitterMSP !== 'BankAMSP' && submitterMSP !== 'BankBMSP') {
      throw new Error('Only BankA or BankB can submit SARs');
    }

    // Check if SAR already exists
    const sarKey = createSarKey(sarId);
    const existing = await ctx.stub.getState(sarKey);
    if (existing && existing.length > 0) {
      throw new Error(`SAR ${sarId} already exists`);
    }

    // Create SAR record (public state - minimal info)
    const sarRecord = {
      sarId,
      submitterMSP,
      submitterId,
      timestamp: ts,
      acknowledged: false,
    };

    // Save public SAR record
    await ctx.stub.putState(sarKey, Buffer.from(JSON.stringify(sarRecord)));

    // Write hash to private collection (sarHashes - banks only)
    const hashData = {
      sarId,
      hash,
      timestamp: ts,
    };
    await ctx.stub.putPrivateData('sarHashes', sarId, Buffer.from(JSON.stringify(hashData)));

    // Write metadata to private collection (sarMetadata - banks write, regulator read)
    const metadataData = {
      sarId,
      metadata: meta,
      timestamp: ts,
    };
    await ctx.stub.putPrivateData('sarMetadata', sarId, Buffer.from(JSON.stringify(metadataData)));

    // Update submitter index
    await this._updateSubmitterIndex(ctx, submitterId, sarId);

    // Emit event
    ctx.stub.setEvent('SARAnchored', Buffer.from(JSON.stringify(sarRecord)));

    return sarRecord;
  }

  /**
   * Acknowledge SAR submission (regulator read-only operation)
   * Channel: sar-audit
   * Endorsement: OR('BankAMSP.peer', 'BankBMSP.peer') - but only regulator can acknowledge
   * @param {Context} ctx - Transaction context
   * @param {string} sarId - SAR identifier
   * @param {string} regulatorId - Regulator identifier
   * @param {string} acknowledgement - Acknowledgement message
   * @returns {object} Updated SAR record
   */
  async acknowledgeSar(ctx, sarId, regulatorId, acknowledgement) {
    if (!validateSarId(sarId)) {
      throw new Error('Invalid SAR ID format');
    }

    // Get existing SAR
    const sarKey = createSarKey(sarId);
    const existing = await ctx.stub.getState(sarKey);
    if (!existing || existing.length === 0) {
      throw new Error(`SAR ${sarId} does not exist`);
    }

    const sarRecord = JSON.parse(existing.toString());

    // Validate caller is RegulatorObserver
    const callerMSP = ctx.clientIdentity.getMSPID();
    if (callerMSP !== 'RegulatorObserverMSP') {
      throw new Error('Only RegulatorObserver can acknowledge SARs');
    }

    // Update acknowledgement
    sarRecord.acknowledged = true;
    sarRecord.acknowledgement = {
      regulatorId,
      acknowledgement,
      timestamp: new Date().toISOString(),
    };

    // Save updated SAR record
    await ctx.stub.putState(sarKey, Buffer.from(JSON.stringify(sarRecord)));

    // Emit event
    ctx.stub.setEvent('SARAcknowledged', Buffer.from(JSON.stringify(sarRecord)));

    return sarRecord;
  }

  /**
   * Get SAR hash (banks only via private data)
   * Channel: sar-audit
   * Private Data: Reads from sarHashes collection
   */
  async getSarHash(ctx, sarId) {
    if (!validateSarId(sarId)) {
      throw new Error('Invalid SAR ID format');
    }

    // Validate caller is BankA or BankB
    const callerMSP = ctx.clientIdentity.getMSPID();
    if (callerMSP !== 'BankAMSP' && callerMSP !== 'BankBMSP') {
      throw new Error('Only BankA or BankB can read SAR hashes');
    }

    const hashBytes = await ctx.stub.getPrivateData('sarHashes', sarId);
    if (!hashBytes || hashBytes.length === 0) {
      throw new Error(`SAR hash for ${sarId} does not exist`);
    }

    return JSON.parse(hashBytes.toString());
  }

  /**
   * Get SAR metadata (banks and regulator can read)
   * Channel: sar-audit
   * Private Data: Reads from sarMetadata collection
   */
  async getSarMetadata(ctx, sarId) {
    if (!validateSarId(sarId)) {
      throw new Error('Invalid SAR ID format');
    }

    // Validate caller is BankA, BankB, or RegulatorObserver
    const callerMSP = ctx.clientIdentity.getMSPID();
    if (
      callerMSP !== 'BankAMSP' &&
      callerMSP !== 'BankBMSP' &&
      callerMSP !== 'RegulatorObserverMSP'
    ) {
      throw new Error('Only BankA, BankB, or RegulatorObserver can read SAR metadata');
    }

    const metadataBytes = await ctx.stub.getPrivateData('sarMetadata', sarId);
    if (!metadataBytes || metadataBytes.length === 0) {
      throw new Error(`SAR metadata for ${sarId} does not exist`);
    }

    return JSON.parse(metadataBytes.toString());
  }

  /**
   * List SARs submitted by a specific bank
   * Channel: sar-audit
   */
  async listSars(ctx, submitterId) {
    const indexKey = createSubmitterIndexKey(submitterId);
    const indexBytes = await ctx.stub.getState(indexKey);

    if (!indexBytes || indexBytes.length === 0) {
      return [];
    }

    const index = JSON.parse(indexBytes.toString());
    const sars = [];

    for (const sarId of index.sarIds || []) {
      const sarKey = createSarKey(sarId);
      const sarBytes = await ctx.stub.getState(sarKey);
      if (sarBytes && sarBytes.length > 0) {
        sars.push(JSON.parse(sarBytes.toString()));
      }
    }

    return sars;
  }

  /**
   * Update submitter index (internal helper)
   * @private
   */
  async _updateSubmitterIndex(ctx, submitterId, sarId) {
    const indexKey = createSubmitterIndexKey(submitterId);
    const indexBytes = await ctx.stub.getState(indexKey);

    let index;
    if (!indexBytes || indexBytes.length === 0) {
      index = { submitterId, sarIds: [] };
    } else {
      index = JSON.parse(indexBytes.toString());
    }

    if (!index.sarIds.includes(sarId)) {
      index.sarIds.push(sarId);
    }

    await ctx.stub.putState(indexKey, Buffer.from(JSON.stringify(index)));
  }
}

module.exports = SARAnchor;

