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
let pokerOperator = createWallets(1);

let contractName;
let token;
let oracle;
let gameController;
let poolController;
let poker;

async function main() {
  console.log(`[NOTICE!] Chain of deployment: ${network.name}`);

  // ===============Contract #1: XTRXToken===============
  contractName = "XTRXToken";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  contractDeployTx = await _contractProto.deploy();
  token = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY[network.name][contractName].address = token.address;

  // Verify
  console.log(`[${contractName}]: Start of Verification...`);

  await delay(90000);

  if (network.name === "polygon_mainnet") {
    url = "https://polygonscan.com/address/" + token.address + "#code";
  } else if (network.name === "polygon_testnet") {
    url = "https://mumbai.polygonscan.com/address/" + token.address + "#code";
  }
  OUTPUT_DEPLOY[network.name][contractName].verification = url;

  try {
    await hre.run("verify:verify", {
      address: token.address,
    });
  } catch (error) {
    console.error(error);
  }
  console.log(`[${contractName}]: Verification Finished!`);

  // ===============Contract #2: Oracle===============
  contractName = "Oracle";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the oracle with operator address.
  contractDeployTx = await _contractProto.deploy();
  oracle = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY[network.name][contractName].address = oracle.address;

  // Verify
  console.log(`[${contractName}]: Start of Verification...`);

  await delay(90000);

  if (network.name === "polygon_mainnet") {
    url = "https://polygonscan.com/address/" + oracle.address + "#code";
  } else if (network.name === "polygon_testnet") {
    url = "https://mumbai.polygonscan.com/address/" + oracle.address + "#code";
  }
  OUTPUT_DEPLOY[network.name][contractName].verification = url;

  try {
    await hre.run("verify:verify", {
      address: oracle.address,
    });
  } catch (error) {
    console.error(error);
  }
  console.log(`[${contractName}]: Verification Finished!`);

  // ===============Contract #3: PoolController===============
  contractName = "PoolController";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the pool controller with token address
  contractDeployTx = await _contractProto.deploy(token.address);
  poolController = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY[network.name][contractName].address = poolController.address;

  // Verify
  console.log(`[${contractName}]: Start of Verification...`);

  await delay(90000);

  if (network.name === "polygon_mainnet") {
    url = "https://polygonscan.com/address/" + poolController.address + "#code";
  } else if (network.name === "polygon_testnet") {
    url =
      "https://mumbai.polygonscan.com/address/" +
      poolController.address +
      "#code";
  }
  OUTPUT_DEPLOY[network.name][contractName].verification = url;

  try {
    await hre.run("verify:verify", {
      address: poolController.address,
      constructorArguments: [token.address],
    });
  } catch (error) {
    console.error(error);
  }
  console.log(`[${contractName}]: Verification Finished!`);

  // ===============Contract #4: Poker===============
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

  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY[network.name][contractName].address = poker.address;
  OUTPUT_DEPLOY[network.name][contractName].pokerOperatorAddress =
    pokerOperator.address;
  OUTPUT_DEPLOY[network.name][contractName].pokerOperatorPrivateKey =
    pokerOperator.privateKey;

  // Verify
  console.log(`[${contractName}]: Start of Verification...`);

  await delay(90000);

  if (network.name === "polygon_mainnet") {
    url = "https://polygonscan.com/address/" + poker.address + "#code";
  } else if (network.name === "polygon_testnet") {
    url = "https://mumbai.polygonscan.com/address/" + poker.address + "#code";
  }
  OUTPUT_DEPLOY[network.name][contractName].verification = url;

  try {
    await hre.run("verify:verify", {
      address: poker.address,
      constructorArguments: [
        oracle.address,
        poolController.address,
        pokerOperator.address,
      ],
    });
  } catch (error) {
    console.error(error);
  }
  console.log(`[${contractName}]: Verification Finished!`);

  // ===============Contract #5: GameController===============
  contractName = "GameController";
  console.log(`[${contractName}]: Start of Deployment...`);
  _contractProto = await ethers.getContractFactory(contractName);
  // Provide the game with oracle, pool controller, poker operator addresses
  contractDeployTx = await _contractProto.deploy(oracle.address);
  gameController = await contractDeployTx.deployed();
  console.log(`[${contractName}]: Deployment Finished!`);
  OUTPUT_DEPLOY[network.name][contractName].address = gameController.address;

  // Verify
  console.log(`[${contractName}]: Start of Verification...`);

  await delay(90000);

  if (network.name === "polygon_mainnet") {
    url = "https://polygonscan.com/address/" + gameController.address + "#code";
  } else if (network.name === "polygon_testnet") {
    url =
      "https://mumbai.polygonscan.com/address/" +
      gameController.address +
      "#code";
  }
  OUTPUT_DEPLOY[network.name][contractName].verification = url;

  try {
    await hre.run("verify:verify", {
      address: gameController.address,
      constructorArguments: [oracle.address],
    });
  } catch (error) {
    console.error(error);
  }
  console.log(`[${contractName}]: Verification Finished!`);

  console.log(
    `\n\n--See Results in "${__dirname + "/deployOutput.json"}" File--`
  );

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
