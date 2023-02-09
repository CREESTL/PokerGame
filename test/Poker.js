const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { parseUnits, parseEther } = ethers.utils;

const TEST_ADDRESSES = [
  "0x1000000000000000000000000000000000000000",
  "0x2000000000000000000000000000000000000000",
];

const computerWinsCards = [1, 2, 4, 6, 8, 9, 10, 11, 12];
const playerWinsCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];
const drawCards = [0, 1, 12, 25, 38, 51, 13, 14, 26];
const jackpotCards = [12, 11, 10, 9, 8, 5, 2, 1, 3];
const evenWinColorCards = [12, 25, 38]; // returns 2, 0, 3 even wins
const oddWinColorCards = [22, 47, 7]; // returns 1, 3, 0 odd wins

const checkingToBitArr = [1, 6, 13, 14, 24, 27, 44, 45, 50];
const checkingToBitInt = "14274713982914945";

const initHouseEdge = 15;
const changedHouseEdge = 20;

const initJackpotMultiplier = 2;
const changedJackpotMultiplier = 5;

describe("Poker", () => {
  let token;
  let poolController;
  let oracle;
  let poker;
  let zeroAddress = ethers.constants.AddressZero;
  let randomAddress = "0xEd24551e059304BE771ac6CF8B654271ec156Ba0";
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

    let oracleTx = await ethers.getContractFactory("Oracle");
    // Make owner the operator of oracle
    oracle = await oracleTx.deploy(ownerAcc.address);
    await oracle.deployed();

    let pokerTx = await ethers.getContractFactory("Poker");
    // Make owner the operator of poker
    poker = await pokerTx.deploy(
      oracle.address,
      poolController.address,
      ownerAcc.address
    );
    await poker.deployed();

    await poker.connect(ownerAcc).setMaxBet(parseEther("1"));
  });

  describe("Poker result", () => {
    it("Should get poker result", async () => {
      expect(await poker.getPokerResult(computerWinsCards)).to.equal(0);
      expect(await poker.getPokerResult(playerWinsCards)).to.equal(2);
      expect(await poker.getPokerResult(drawCards)).to.equal(1);
    });
  });
});
