/**
 * SARAnchor Chaincode Tests
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Unit and integration tests (phase_1_plan_details.md:62)
 */

const { ChaincodeStub, ClientIdentity } = require('fabric-shim');
const SARAnchor = require('../src/sarAnchor');
const fixtures = require('./fixtures/sampleSars');

describe('SARAnchor', () => {
  let contract;
  let mockCtx;
  let mockStub;
  let mockClientIdentity;

  beforeEach(() => {
    contract = new SARAnchor();
    mockStub = new ChaincodeStub();
    mockClientIdentity = new ClientIdentity(mockStub);
    mockCtx = {
      stub: mockStub,
      clientIdentity: mockClientIdentity,
    };

    mockStub.getState = jest.fn().mockResolvedValue(Buffer.from(''));
    mockStub.putState = jest.fn().mockResolvedValue();
    mockStub.putPrivateData = jest.fn().mockResolvedValue();
    mockStub.getPrivateData = jest.fn().mockResolvedValue(Buffer.from(''));
    mockStub.setEvent = jest.fn().mockResolvedValue();
    mockClientIdentity.getMSPID = jest.fn().mockReturnValue('BankAMSP');
    mockClientIdentity.getID = jest.fn().mockReturnValue('Admin@banka.example.com');
  });

  describe('anchorSar', () => {
    it('should anchor a valid SAR', async () => {
      const sar = fixtures.validSar;
      const result = await contract.anchorSar(
        mockCtx,
        sar.sarId,
        sar.hash,
        JSON.stringify(sar.metadata),
        sar.timestamp
      );

      expect(result).toBeDefined();
      expect(result.sarId).toBe(sar.sarId);
      expect(mockStub.putState).toHaveBeenCalled();
      expect(mockStub.putPrivateData).toHaveBeenCalledWith('sarHashes', sar.sarId, expect.any(Buffer));
      expect(mockStub.putPrivateData).toHaveBeenCalledWith('sarMetadata', sar.sarId, expect.any(Buffer));
      expect(mockStub.setEvent).toHaveBeenCalledWith('SARAnchored', expect.any(Buffer));
    });

    it('should reject invalid SAR ID', async () => {
      const sar = fixtures.invalidSarId;
      await expect(
        contract.anchorSar(
          mockCtx,
          sar.sarId,
          sar.hash,
          JSON.stringify(sar.metadata),
          sar.timestamp
        )
      ).rejects.toThrow('Invalid SAR ID format');
    });

    it('should reject submission from non-bank MSP', async () => {
      const sar = fixtures.validSar;
      mockClientIdentity.getMSPID = jest.fn().mockReturnValue('RegulatorObserverMSP');

      await expect(
        contract.anchorSar(
          mockCtx,
          sar.sarId,
          sar.hash,
          JSON.stringify(sar.metadata),
          sar.timestamp
        )
      ).rejects.toThrow('Only BankA or BankB can submit SARs');
    });
  });

  describe('acknowledgeSar', () => {
    it('should acknowledge SAR from regulator', async () => {
      const sar = fixtures.validSar;
      mockClientIdentity.getMSPID = jest.fn().mockReturnValue('RegulatorObserverMSP');

      mockStub.getState = jest.fn().mockResolvedValue(
        Buffer.from(
          JSON.stringify({
            sarId: sar.sarId,
            submitterMSP: 'BankAMSP',
            acknowledged: false,
          })
        )
      );

      const result = await contract.acknowledgeSar(mockCtx, sar.sarId, 'regulator-1', 'Acknowledged');

      expect(result).toBeDefined();
      expect(result.acknowledged).toBe(true);
      expect(result.acknowledgement.regulatorId).toBe('regulator-1');
    });

    it('should reject acknowledgement from non-regulator', async () => {
      const sar = fixtures.validSar;
      mockClientIdentity.getMSPID = jest.fn().mockReturnValue('BankAMSP');

      mockStub.getState = jest.fn().mockResolvedValue(
        Buffer.from(
          JSON.stringify({
            sarId: sar.sarId,
            submitterMSP: 'BankAMSP',
            acknowledged: false,
          })
        )
      );

      await expect(
        contract.acknowledgeSar(mockCtx, sar.sarId, 'regulator-1', 'Acknowledged')
      ).rejects.toThrow('Only RegulatorObserver can acknowledge SARs');
    });
  });

  describe('getSarHash', () => {
    it('should get SAR hash for bank', async () => {
      const sar = fixtures.validSar;
      mockClientIdentity.getMSPID = jest.fn().mockReturnValue('BankAMSP');

      mockStub.getPrivateData = jest.fn().mockResolvedValue(
        Buffer.from(
          JSON.stringify({
            sarId: sar.sarId,
            hash: sar.hash,
            timestamp: sar.timestamp,
          })
        )
      );

      const result = await contract.getSarHash(mockCtx, sar.sarId);

      expect(result).toBeDefined();
      expect(result.hash).toBe(sar.hash);
      expect(mockStub.getPrivateData).toHaveBeenCalledWith('sarHashes', sar.sarId);
    });

    it('should reject hash access from regulator', async () => {
      const sar = fixtures.validSar;
      mockClientIdentity.getMSPID = jest.fn().mockReturnValue('RegulatorObserverMSP');

      await expect(contract.getSarHash(mockCtx, sar.sarId)).rejects.toThrow(
        'Only BankA or BankB can read SAR hashes'
      );
    });
  });
});

