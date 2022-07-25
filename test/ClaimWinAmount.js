// SPDX-License-Identifier: MIT
const { expect } = require("chai");
const { ethers } = require("hardhat");


// Tests for Poker.sol
describe("Poker", function () {
  
  // Constants to be used afterwards
  let poker;
  let poolController;
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
    _xtrx = await ethers.getContractFactory("XTRXToken");
    let xtrx = await _xtrx.deploy();
    await xtrx.deployed();


    // Deploy pool oracle 
    _oracle = await ethers.getContractFactory("Oracle");
    oracle = await _oracle.deploy(addr1.address);
    await oracle.deployed();
    
    // Deploy game controller and provide it with pool oracle address
    _gameController = await ethers.getContractFactory("GameController");
    let gameController = await _gameController.deploy(oracle.address);
    await gameController.deployed();

    // Deploy pool controller and provide it with token address
    _poolController = await ethers.getContractFactory("PoolController");
    poolController = await _poolController.deploy(xtrx.address);
    await poolController.deployed();
    let poolAddress = await poolController.getPoolAddress();
    
    // Deploy the game itself and provide it with required addresses
    _poker = await ethers.getContractFactory("Poker");
    poker = await _poker.deploy(oracle.address, poolController.address, owner.address);
    await poker.deployed();

    // Set max bet of the game
    await poker.setMaxBet(ethers.utils.parseEther("2"));
    // Set the game address of the pool controller
    await poolController.setGame(poker.address);
    // Set the game address of the game oracle
    await oracle.setGame(poker.address);
  });


  describe("Testing Jackpot", function () {

    it("Should mint tokens to accounts", async function () {


      // Start the game
      let overrides = {value: ethers.utils.parseEther("0.001")};
      await poker.connect(owner).play("1000", "2000", overrides);

    });

    it("Should not mint more than one token for address", async function () {
      // Mint the first token to account
      await poker.connect(addr1).giveMeToken(uri);
      // Try mint the second token to account
      await expect(poker.connect(addr1).giveMeToken(uri)).to.revertedWith("Only a Single Token for Address is Allowed!");
    });

    it("Should allow owner to mint tokens to several users", async function () {
      // Mint 3 tokens to 3 different accounts. One for account.
      await poker.connect(owner).giveTokenTo(addr1.address, uri);
      const addr1Balance = await poker.balanceOf(addr1.address);
      expect(addr1Balance).to.equal(1);
      await poker.connect(owner).giveTokenTo(addr2.address, uri);
      const addr2Balance = await poker.balanceOf(addr2.address);
      expect(addr2Balance).to.equal(1);
      await poker.connect(owner).giveTokenTo(addr3.address, uri);
      const addr3Balance = await poker.balanceOf(addr3.address);
      expect(addr3Balance).to.equal(1);
    });      

   
  });

});
