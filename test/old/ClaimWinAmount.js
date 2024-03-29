// SPDX-License-Identifier: MIT

const { expect } = require("chai");
const { ethers } = require("hardhat");
const { parseEther } = ethers.utils;

// Tests for Poker.sol
describe("Poker", function () {
  // Constants to be used afterwards
  let poker;
  let poolController;
  let gameController;
  let oracle;
  let owner;
  let addr1;
  let addr2;
  let addr3;
  let addrs;

  // Hook runs before each test suite
  beforeEach(async function () {
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();

    // Deploy token
    const _xtrx = await ethers.getContractFactory("XTRXToken");
    let xtrx = await _xtrx.deploy();
    await xtrx.deployed();

    // Deploy pool oracle and provide it with pool operator address
    const _oracle = await ethers.getContractFactory("Oracle");
    oracle = await _oracle.deploy(addr1.address);
    await oracle.deployed();

    // Deploy game controller and provide it with pool oracle address
    const _gameController = await ethers.getContractFactory("GameController");
    gameController = await _gameController.deploy(oracle.address);
    await gameController.deployed();

    // Deploy pool controller and provide it with token address
    const _poolController = await ethers.getContractFactory("PoolController");
    poolController = await _poolController.deploy(xtrx.address);
    await poolController.deployed();
    // Send some funds to the pool
    await poolController.receiveFundsFromGame({ value: parseEther("1") });

    // Deploy the game itself and provide it with required addresses
    const _poker = await ethers.getContractFactory("Poker");
    poker = await _poker.deploy(
      oracle.address,
      poolController.address,
      owner.address
    );
    await poker.deployed();

    // Set max bet of the game
    await poker.setMaxBet(parseEther("2"));
    // Set the game address of the pool controller
    await poolController.setGame(poker.address);
    // Set the game address of the game oracle
    await oracle.setGame(poker.address);
    // Set game operator
    await poker.setOperator(owner.address);
  });

  describe("Jackpot", () => {
    it("Should work fine in normal conditions", async () => {
      // Start the game
      // This also refreshes random numbers and updates jackpot
      // colorBet = 1000 wei (random)
      // chosenColor = 2000 wei (random)
      // Add 10_000_000_000 - 3_000_000 (oracle fee) =  9_997_000_000 wei to the pool amount
      await poker.startGame(1000, 2000, { value: 10_000_000_000 });
      // Get the last request id
      let lastReqId = await poker.getLastRequestId();
      // Cheat: set jackpot
      // winAmount = 200_000 wei (random)
      // refAmount = 100_000 wei (random)
      await poker.endGame(lastReqId, 200_000, 100_000, true, 0);
      // Try to claim the winAmount
      // This should work
      await poker.claimWinAmount(lastReqId);
    });

    it("Should fail if jackpot is greater than pool amount", async () => {
      // Start the game
      // This also refreshes random numbers and updates jackpot
      // colorBet = 1000 wei (random)
      // chosenColor = 2000 wei (random)
      // Add 10_000_000_000 - 3_000_000 (oracle fee) =  9_997_000_000 wei to the pool amount
      await poker.startGame(1000, 2000, { value: 10_000_000_000 });
      // Get the last request id
      let lastReqId = await poker.getLastRequestId();
      // Cheat: set jackpot
      // winAmount = 9_997_000_001 wei (greater than pool balance)
      // refAmount = 100_000 wei (random)
      await poker.endGame(lastReqId, 9_997_000_001, 100_000, true, 0);
      // Try to claim the winAmount
      // This should fail
      await expect(poker.claimWinAmount(lastReqId)).to.revertedWith(
        "pc: Not Enough Funds in the Pool!"
      );
    });

    it("Should fail if win amount was not set", async () => {
      // Start the game
      // This also refreshes random numbers and updates jackpot
      // colorBet = 1000 wei (random)
      // chosenColor = 2000 wei (random)
      // Add 10_000_000_000_000 - 3_000_000 (oracle fee) =  9_999_997_000_000 wei to the pool amount
      await poker.startGame(1000, 2000, { value: 10_000_000_000_000 });
      // Get the last request id
      let lastReqId = await poker.getLastRequestId();
      // Cheat: set jackpot
      // winAmount = 0 wei ()
      // refAmount = 0 wei (random)
      await poker.endGame(lastReqId, 0, 0, true, 0);
      // Try to claim the winAmount
      // It should fail because neither winAmount nor refAmount was set
      await expect(poker.claimWinAmount(lastReqId)).to.be.revertedWith(
        "p: Invalid Amount!"
      );
    });

    it("Should fail if win has been claimed before", async () => {
      // Start the game
      // This also refreshes random numbers and updates jackpot
      // colorBet = 1000 wei (random)
      // chosenColor = 2000 wei (random)
      // Add 10_000_000_000_000 - 3_000_000 (oracle fee) =  9_999_997_000_000 wei to the pool amount
      await poker.startGame(1000, 2000, { value: 10_000_000_000_000 });
      // Get the last request id
      let lastReqId = await poker.getLastRequestId();
      // Cheat: set jackpot
      // winAmount = 200_000 wei (random)
      // refAmount = 100_000 wei (random)
      await poker.endGame(lastReqId, 200_000, 100_000, true, 0);
      // Try to claim the winAmount
      await poker.claimWinAmount(lastReqId);
      // And try that again
      await expect(poker.claimWinAmount(lastReqId)).to.be.revertedWith(
        "p: Win Already Claimed!"
      );
    });

    it("Should fail if jackpot is greater then jackpot funds", async () => {
      await poker.startGame(1000, 2000, { value: 10_000_000_000_000 });
      let lastReqId = await poker.getLastRequestId();
      let jackpotFunds = await poolController.totalJackpot();
      await expect(
        poker.endGame(lastReqId, jackpotFunds.add(1), 100_000, true, 0)
      ).to.be.revertedWith("pc: not enough funds for jackpot");
    });

    it("Should fail if jackpot is greater then jackpot limit", async () => {
      await poker.startGame(1000, 2000, { value: 10_000_000_000_000 });
      let lastReqId = await poker.getLastRequestId();
      let jackpotLimit = await poolController.jackpotLimit();
      await expect(
        poker.endGame(lastReqId, jackpotLimit.add(1), 100_000, true, 0)
      ).to.be.revertedWith("pc: jackpot is greater than limit");
    });

    it("Should decrease available for jackpot funds when not claimed", async () => {
      await poker.startGame(1000, 2000, { value: 10_000_000_000_000 });
      let lastReqId = await poker.getLastRequestId();
      let jackpotFunds = await poolController.totalJackpot();
      await poker.endGame(lastReqId, jackpotFunds.div(10), 100_000, true, 0);
      expect(await poolController.getAvailableJackpot()).to.be.equal(
        jackpotFunds.sub(jackpotFunds.div(10))
      );
    });
  });
});
