/**
 * ModelRegistry Chaincode Tests
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Unit and integration tests (phase_1_plan_details.md:62)
 */

const { ChaincodeStub, ClientIdentity } = require('fabric-shim');
const ModelRegistry = require('../src/modelRegistry');
const fixtures = require('./fixtures/sampleModels');

describe('ModelRegistry', () => {
  let contract;
  let mockCtx;
  let mockStub;
  let mockClientIdentity;

  beforeEach(() => {
    contract = new ModelRegistry();
    mockStub = new ChaincodeStub();
    mockClientIdentity = new ClientIdentity(mockStub);
    mockCtx = {
      stub: mockStub,
      clientIdentity: mockClientIdentity,
    };

    // Mock getState
    mockStub.getState = jest.fn().mockResolvedValue(Buffer.from(''));
    // Mock putState
    mockStub.putState = jest.fn().mockResolvedValue();
    // Mock setEvent
    mockStub.setEvent = jest.fn().mockResolvedValue();
    // Mock getMSPID
    mockClientIdentity.getMSPID = jest.fn().mockReturnValue('BankAMSP');
    // Mock getID
    mockClientIdentity.getID = jest.fn().mockReturnValue('Admin@banka.example.com');
  });

  describe('registerModel', () => {
    it('should register a valid model', async () => {
      const model = fixtures.validModel;
      const result = await contract.registerModel(
        mockCtx,
        model.modelId,
        model.version,
        model.hash,
        JSON.stringify(model.parameters),
        model.signature
      );

      expect(result).toBeDefined();
      expect(result.modelId).toBe(model.modelId);
      expect(result.version).toBe(model.version);
      expect(mockStub.putState).toHaveBeenCalled();
      expect(mockStub.setEvent).toHaveBeenCalledWith('ModelRegistered', expect.any(Buffer));
    });

    it('should reject invalid model ID', async () => {
      const model = fixtures.invalidModelId;
      await expect(
        contract.registerModel(
          mockCtx,
          model.modelId,
          model.version,
          model.hash,
          JSON.stringify(model.parameters),
          model.signature
        )
      ).rejects.toThrow('Invalid model ID format');
    });

    it('should reject invalid version', async () => {
      const model = fixtures.invalidVersion;
      await expect(
        contract.registerModel(
          mockCtx,
          model.modelId,
          model.version,
          model.hash,
          JSON.stringify(model.parameters),
          model.signature
        )
      ).rejects.toThrow('Invalid version format');
    });

    it('should reject invalid hash', async () => {
      const model = fixtures.invalidHash;
      await expect(
        contract.registerModel(
          mockCtx,
          model.modelId,
          model.version,
          model.hash,
          JSON.stringify(model.parameters),
          model.signature
        )
      ).rejects.toThrow('Invalid hash format');
    });

    it('should enforce version monotonicity', async () => {
      const model1 = fixtures.validModel;
      const model2 = fixtures.validModelV2; // eslint-disable-line no-unused-vars

      // Register first version
      await contract.registerModel(
        mockCtx,
        model1.modelId,
        model1.version,
        model1.hash,
        JSON.stringify(model1.parameters),
        model1.signature
      );

      // Mock getState to return existing model
      mockStub.getState = jest
        .fn()
        .mockImplementation((key) => {
          if (key.includes('MODEL_INDEX')) {
            return Promise.resolve(
              Buffer.from(JSON.stringify({ modelId: model1.modelId, versions: ['1.0.0'] }))
            );
          }
          if (key.includes(model1.version)) {
            return Promise.resolve(Buffer.from(JSON.stringify({ ...model1, version: '1.0.0' })));
          }
          return Promise.resolve(Buffer.from(''));
        });

      // Try to register older version
      await expect(
        contract.registerModel(
          mockCtx,
          model1.modelId,
          '0.9.9',
          model1.hash,
          JSON.stringify(model1.parameters),
          model1.signature
        )
      ).rejects.toThrow('Version 0.9.9 must be greater than latest version 1.0.0');
    });
  });

  describe('getModel', () => {
    it('should retrieve existing model', async () => {
      const model = fixtures.validModel;
      const modelKey = `MODEL:${model.modelId}:${model.version}`;

      mockStub.getState = jest.fn().mockResolvedValue(
        Buffer.from(
          JSON.stringify({
            ...model,
            parameters: model.parameters,
            timestamp: new Date().toISOString(),
          })
        )
      );

      const result = await contract.getModel(mockCtx, model.modelId, model.version);

      expect(result).toBeDefined();
      expect(result.modelId).toBe(model.modelId);
      expect(mockStub.getState).toHaveBeenCalledWith(modelKey);
    });

    it('should throw error for non-existent model', async () => {
      mockStub.getState = jest.fn().mockResolvedValue(Buffer.from(''));

      await expect(contract.getModel(mockCtx, 'nonexistent', '1.0.0')).rejects.toThrow(
        'does not exist'
      );
    });
  });

  describe('approveModel', () => {
    it('should approve model from BankB', async () => {
      const model = fixtures.validModel;
      mockClientIdentity.getMSPID = jest.fn().mockReturnValue('BankBMSP');

      // Mock existing model
      mockStub.getState = jest.fn().mockResolvedValue(
        Buffer.from(
          JSON.stringify({
            ...model,
            parameters: model.parameters,
            approvals: [{ mspId: 'BankAMSP', signature: model.signature }],
          })
        )
      );

      const result = await contract.approveModel(mockCtx, model.modelId, model.version, 'sig2');

      expect(result).toBeDefined();
      expect(result.approvals).toHaveLength(2);
      expect(result.approvals[1].mspId).toBe('BankBMSP');
    });

    it('should reject approval from non-bank MSP', async () => {
      const model = fixtures.validModel;
      mockClientIdentity.getMSPID = jest.fn().mockReturnValue('ConsortiumOpsMSP');

      mockStub.getState = jest.fn().mockResolvedValue(
        Buffer.from(
          JSON.stringify({
            ...model,
            parameters: model.parameters,
            approvals: [],
          })
        )
      );

      await expect(
        contract.approveModel(mockCtx, model.modelId, model.version, 'sig')
      ).rejects.toThrow('Only BankA or BankB can approve models');
    });
  });
});

