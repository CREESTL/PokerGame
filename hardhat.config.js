// SPDX-License-Identifier: MIT
require("dotenv").config();
const { ethers } = require("ethers");
require("@nomicfoundation/hardhat-toolbox");
require("@primitivefi/hardhat-dodoc");

// Add some .env individual variables
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      gas: 2100000,
      gasPrice: 8000000000,
    },
      polygon_mainnet: {
          url: `https://rpc-mainnet.maticvigil.com/`,
          accounts: [PRIVATE_KEY],
      },
      polygon_testnet: {
          url: `https://matic-mumbai.chainstacklabs.com`,
          accounts: [PRIVATE_KEY],
      },
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 20000000000,
  },
  dodoc: {
    include: [],
    runOnCompile: false,
    freshOutput: true,
    outputDir: "./docs/contracts",
  },
  etherscan: {
    apiKey: {
      polygon: POLYGONSCAN_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
    },
  },
};
