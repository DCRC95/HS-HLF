/**
 * ModelRegistry Chaincode Entry Point
 * Author: Week 3-4 Implementation
 * Date: 2025-11-28
 * Purpose: Entry point for ModelRegistry chaincode (phase_1_plan_details.md:27-34, 55-64)
 * Channel: model-governance
 */

const { Contract } = require('fabric-contract-api');
const ModelRegistry = require('./modelRegistry');

module.exports = ModelRegistry;

