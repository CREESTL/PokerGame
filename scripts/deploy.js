// SPDX-License-Identifier: MIT
const { ethers, network } = require("hardhat");
const fs = require("fs");
const path = require("path");
const delay = require("delay");

// JSON file to keep information about previous deployments
const OUTPUT_DEPLOY = require("./deployOutput.json");

// Creates a number of random wallets to be used while deploying contracts
function createWallets(numberWallets) {
  let createdWallets = [];
  for (let i = 0; i < numberWallets; i++) {
    let wallet = ethers.Wallet.createRandom();
    createdWallets.push(wallet);
    console.log(`New wallet №${i + 1}:`);
    console.log(`    Address: ${wallet.address}`);
    console.log(`    Private key: ${wallet.privateKey}`);
  }
  return createdWallets;
}

// Create 2 new wallets
// Use them in Oracle and Poker constructors
let [oracleOperator, pokerOperator] = createWallets(2);

let contractName;
let token;
let oracle;
let gameController;
let poolController;
let poker;
let migrations;
let interfaces;

async function main() {

  // Contract #1: XTRXToken
  contractName = "XTRXToken";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  contractDeployTx = await _contractProto.deploy();
  token = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = token.address;

  // Contract #2: Oracle
  contractName = "Oracle";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the oracle with operator address.
  contractDeployTx = await _contractProto.deploy(oracleOperator.address);
  oracle = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = oracle.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].oracleOperatorAddress =
    oracleOperator.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].oracleOperatorPrivateKey =
    oracleOperator.privateKey;

  // Contract #3: PoolController
  contractName = "PoolController";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the pool controller with token address
  contractDeployTx = await _contractProto.deploy(token.address);
  poolController = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address =
    poolController.address;

  // Contract #4: Poker
  contractName = "Poker";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the game with oracle, pool controller, poker operator addresses
  contractDeployTx = await _contractProto.deploy(
    oracle.address,
    poolController.address,
    pokerOperator.address
  );
  poker = await contractDeployTx.deployed();
  // Set the maximum bet of the poker
  // TODO how much should the max bet be?
  poker.connect(pokerOperator).setMaxBet(ethers.utils.parseEther("1"));
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY.networks[network.name][contractName].address = poker.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].pokerOperatorAddress =
    pokerOperator.address;
  OUTPUT_DEPLOY.networks[network.name][contractName].pokerOperatorPrivateKey =
    pokerOperator.privateKey;

  console.log(`See Results in "${__dirname + "/deployOutput.json"}" File`);

  fs.writeFileSync(
    path.resolve(__dirname, "./deployOutput.json"),
    JSON.stringify(OUTPUT_DEPLOY, null, "  ")
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
