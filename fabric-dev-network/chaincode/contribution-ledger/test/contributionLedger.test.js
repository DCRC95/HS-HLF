/**
 * ContributionLedger Chaincode Tests
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Unit and integration tests (phase_1_plan_details.md:62)
 */

const { ChaincodeStub, ClientIdentity } = require('fabric-shim');
const ContributionLedger = require('../src/contributionLedger');
const fixtures = require('./fixtures/sampleContributions');

describe('ContributionLedger', () => {
  let contract;
  let mockCtx;
  let mockStub;
  let mockClientIdentity;

  beforeEach(() => {
    contract = new ContributionLedger();
    mockStub = new ChaincodeStub();
    mockClientIdentity = new ClientIdentity(mockStub);
    mockCtx = {
      stub: mockStub,
      clientIdentity: mockClientIdentity,
    };

    mockStub.getState = jest.fn().mockResolvedValue(Buffer.from(''));
    mockStub.putState = jest.fn().mockResolvedValue();
    mockStub.setEvent = jest.fn().mockResolvedValue();
    mockClientIdentity.getMSPID = jest.fn().mockReturnValue('BankAMSP');
    mockClientIdentity.getID = jest.fn().mockReturnValue('Admin@banka.example.com');
  });

  describe('logContribution', () => {
    it('should log a valid contribution', async () => {
      const contrib = fixtures.validContribution;
      const result = await contract.logContribution(
        mockCtx,
        contrib.roundId,
        contrib.contributorId,
        contrib.updateHash,
        JSON.stringify(contrib.aggregationProof),
        contrib.privacyBudget
      );

      expect(result).toBeDefined();
      expect(result.roundId).toBe(contrib.roundId);
      expect(result.contributorId).toBe(contrib.contributorId);
      expect(mockStub.putState).toHaveBeenCalled();
      expect(mockStub.setEvent).toHaveBeenCalledWith('ContributionLogged', expect.any(Buffer));
    });

    it('should reject invalid round ID', async () => {
      const contrib = fixtures.invalidRoundId;
      await expect(
        contract.logContribution(
          mockCtx,
          contrib.roundId,
          contrib.contributorId,
          contrib.updateHash,
          JSON.stringify(contrib.aggregationProof),
          contrib.privacyBudget
        )
      ).rejects.toThrow('Invalid round ID format');
    });

    it('should reject negative privacy budget', async () => {
      const contrib = fixtures.negativePrivacyBudget;
      await expect(
        contract.logContribution(
          mockCtx,
          contrib.roundId,
          contrib.contributorId,
          contrib.updateHash,
          JSON.stringify(contrib.aggregationProof),
          contrib.privacyBudget
        )
      ).rejects.toThrow('Invalid privacy budget');
    });
  });

  describe('getContribution', () => {
    it('should retrieve existing contribution', async () => {
      const contrib = fixtures.validContribution;
      const contribKey = `CONTRIBUTION:${contrib.roundId}:${contrib.contributorId}`;

      mockStub.getState = jest.fn().mockResolvedValue(
        Buffer.from(
          JSON.stringify({
            ...contrib,
            privacyBudget: parseFloat(contrib.privacyBudget),
            timestamp: new Date().toISOString(),
          })
        )
      );

      const result = await contract.getContribution(mockCtx, contrib.roundId, contrib.contributorId);

      expect(result).toBeDefined();
      expect(result.roundId).toBe(contrib.roundId);
      expect(mockStub.getState).toHaveBeenCalledWith(contribKey);
    });
  });
});

