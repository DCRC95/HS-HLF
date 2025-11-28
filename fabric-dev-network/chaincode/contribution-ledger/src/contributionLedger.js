/**
 * ContributionLedger Chaincode Contract
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Contribution ledger contract implementation (phase_1_plan_details.md:27-34, 55-64)
 * Channel: model-governance
 * Endorsement Policy: AND('BankAMSP.peer', 'BankBMSP.peer')
 */

const { Contract } = require('fabric-contract-api');

/**
 * Validates round ID format
 */
function validateRoundId(roundId) {
  return roundId && typeof roundId === 'string' && /^[a-zA-Z0-9_-]{3,64}$/.test(roundId);
}

/**
 * Validates contributor ID format
 */
function validateContributorId(contributorId) {
  return contributorId && typeof contributorId === 'string' && contributorId.length > 0;
}

/**
 * Validates SHA256 hash format
 */
function validateHash(hash) {
  return hash && typeof hash === 'string' && /^[a-fA-F0-9]{64}$/.test(hash);
}

/**
 * Validates privacy budget (non-negative number)
 */
function validatePrivacyBudget(budget) {
  const num = parseFloat(budget);
  return !isNaN(num) && num >= 0;
}

/**
 * Creates contribution key
 */
function createContributionKey(roundId, contributorId) {
  return `CONTRIBUTION:${roundId}:${contributorId}`;
}

/**
 * Creates round index key
 */
function createRoundIndexKey(roundId) {
  return `ROUND_INDEX:${roundId}`;
}

class ContributionLedger extends Contract {
  async initLedger(_ctx) {
    // eslint-disable-next-line no-console
    console.info('ContributionLedger chaincode initialized');
  }

  /**
   * Log a federated learning contribution
   * Channel: model-governance
   * Endorsement: Requires BankA AND BankB (enforced at chaincode definition)
   * @param {Context} ctx - Transaction context
   * @param {string} roundId - Federated learning round identifier
   * @param {string} contributorId - Contributor identifier
   * @param {string} updateHash - SHA256 hash of model update
   * @param {string} aggregationProof - JSON string of aggregation proof
   * @param {string} privacyBudget - Differential privacy budget (number as string)
   * @returns {object} Contribution record
   */
  async logContribution(
    ctx,
    roundId,
    contributorId,
    updateHash,
    aggregationProof,
    privacyBudget
  ) {
    // Validation
    if (!validateRoundId(roundId)) {
      throw new Error('Invalid round ID format');
    }
    if (!validateContributorId(contributorId)) {
      throw new Error('Invalid contributor ID format');
    }
    if (!validateHash(updateHash)) {
      throw new Error('Invalid update hash format (expected SHA256)');
    }
    if (!validatePrivacyBudget(privacyBudget)) {
      throw new Error('Invalid privacy budget (must be non-negative number)');
    }

    let proof;
    try {
      proof = JSON.parse(aggregationProof);
    } catch (e) {
      throw new Error('Invalid aggregation proof JSON format');
    }

    // Check if contribution already exists
    const contributionKey = createContributionKey(roundId, contributorId);
    const existing = await ctx.stub.getState(contributionKey);
    if (existing && existing.length > 0) {
      throw new Error(
        `Contribution for round ${roundId} by ${contributorId} already exists`
      );
    }

    // Get submitter information
    const submitterMSP = ctx.clientIdentity.getMSPID();
    const submitterId = ctx.clientIdentity.getID();

    // Create contribution record
    const contribution = {
      roundId,
      contributorId,
      updateHash,
      aggregationProof: proof,
      privacyBudget: parseFloat(privacyBudget),
      submitterMSP,
      submitterId,
      timestamp: new Date().toISOString(),
    };

    // Save contribution
    await ctx.stub.putState(
      contributionKey,
      Buffer.from(JSON.stringify(contribution))
    );

    // Update round index
    await this._updateRoundIndex(ctx, roundId, contributorId);

    // Emit event
    ctx.stub.setEvent('ContributionLogged', Buffer.from(JSON.stringify(contribution)));

    return contribution;
  }

  /**
   * Get a specific contribution
   * Channel: model-governance
   */
  async getContribution(ctx, roundId, contributorId) {
    if (!validateRoundId(roundId)) {
      throw new Error('Invalid round ID format');
    }
    if (!validateContributorId(contributorId)) {
      throw new Error('Invalid contributor ID format');
    }

    const contributionKey = createContributionKey(roundId, contributorId);
    const contributionBytes = await ctx.stub.getState(contributionKey);

    if (!contributionBytes || contributionBytes.length === 0) {
      throw new Error(
        `Contribution for round ${roundId} by ${contributorId} does not exist`
      );
    }

    return JSON.parse(contributionBytes.toString());
  }

  /**
   * List all contributions for a round
   * Channel: model-governance
   */
  async listContributions(ctx, roundId) {
    if (!validateRoundId(roundId)) {
      throw new Error('Invalid round ID format');
    }

    const indexKey = createRoundIndexKey(roundId);
    const indexBytes = await ctx.stub.getState(indexKey);

    if (!indexBytes || indexBytes.length === 0) {
      return [];
    }

    const index = JSON.parse(indexBytes.toString());
    const contributions = [];

    for (const contributorId of index.contributors || []) {
      const contributionKey = createContributionKey(roundId, contributorId);
      const contributionBytes = await ctx.stub.getState(contributionKey);
      if (contributionBytes && contributionBytes.length > 0) {
        contributions.push(JSON.parse(contributionBytes.toString()));
      }
    }

    return contributions;
  }

  /**
   * Get round summary statistics
   * Channel: model-governance
   */
  async getRoundSummary(ctx, roundId) {
    if (!validateRoundId(roundId)) {
      throw new Error('Invalid round ID format');
    }

    const contributions = await this.listContributions(ctx, roundId);

    const summary = {
      roundId,
      contributorCount: contributions.length,
      totalPrivacyBudget: contributions.reduce(
        (sum, c) => sum + (c.privacyBudget || 0),
        0
      ),
      contributors: contributions.map((c) => ({
        contributorId: c.contributorId,
        updateHash: c.updateHash,
        privacyBudget: c.privacyBudget,
        timestamp: c.timestamp,
      })),
    };

    return summary;
  }

  /**
   * Update round index (internal helper)
   * @private
   */
  async _updateRoundIndex(ctx, roundId, contributorId) {
    const indexKey = createRoundIndexKey(roundId);
    const indexBytes = await ctx.stub.getState(indexKey);

    let index;
    if (!indexBytes || indexBytes.length === 0) {
      index = { roundId, contributors: [] };
    } else {
      index = JSON.parse(indexBytes.toString());
    }

    if (!index.contributors.includes(contributorId)) {
      index.contributors.push(contributorId);
    }

    await ctx.stub.putState(indexKey, Buffer.from(JSON.stringify(index)));
  }
}

module.exports = ContributionLedger;

