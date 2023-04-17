const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { parseUnits, parseEther } = ethers.utils;


describe("Pool Controller Tests", () => {
  let token;
  let poolController;
  let parseEther = ethers.utils.parseEther;

  // Deploy all contracts before each test suite
  beforeEach(async () => {
    [ownerAcc, clientAcc1, clientAcc2, clientAcc3] = await ethers.getSigners();

    let tokenTx = await ethers.getContractFactory("XTRXToken");
    token = await tokenTx.deploy();
    await token.deployed();

    let poolControllerTx = await ethers.getContractFactory("PoolController");
    poolController = await poolControllerTx.deploy(token.address);
    await poolController.deployed();

  });

  describe("Receive native tokens", () => {
    it("Should fail to receive native tokens", async () => {
    	let tx = {
    		to: poolController.address,
    		value: parseEther("1"),
    		gasLimit: 30000
    	};
    	await ownerAcc.sendTransaction(tx);
    });
  });
});
