const {
  BN,
  expectRevert,
} = require('openzeppelin-test-helpers');
const { expect } = require('chai');
const { getBNEth } = require('../utils/getBN');
const { getCardRank } = require('../utils/pokerHelpers');

require('chai')
  .use(require('chai-as-promised'))
  .should();

const XETHToken = artifacts.require('XETHToken');
const PoolController = artifacts.require('PoolController');
const GameController = artifacts.require('GameController');
const Oracle = artifacts.require('Oracle');
const Poker = artifacts.require('Poker');



const randomCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];
const colorCards = [22, 47, 7];

contract('Poker test', async ([owner, alice, bob]) => {

  beforeEach(async () => {
    this.xETH = await XETHToken.deployed();
    this.poolController = await PoolController.deployed();
    // this.gameController = await GameController.deployed();
    this.oracle = await Oracle.deployed();
    this.poker = await Poker.deployed();
    
    
    await this.xETH.setPoolController(this.poolController.address, { from: owner });
    assert.equal(await this.xETH.getPoolController({ from: owner }),(this.poolController.address));
    await this.poolController.setGame(this.poker.address, { from: owner });
    await this.oracle.setGame(this.poker.address, { from: owner });
  });

  it('checking Poker results', async () => {
    console.log(await this.poker.setCards(randomCards));
  });

  it('checking Color results', async () => {
    console.log(await this.poker.determineWinnerColor(colorCards, 1));
  });
  
  it('checking contracts together ', async () => {
    assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 0);
    await this.poolController.deposit(owner, { from: owner, callValue: 1000000 });
    assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 1000000);
    let poolInfo = await this.poolController.getPoolInfo();
    assert.equal(poolInfo[1].toString(), 1000000)
    await this.poker.play(10000, 1, { from: owner, callValue: 20000 });
    poolInfo = await this.poolController.getPoolInfo();
    assert.equal(poolInfo[1].toString(), 1020000);
    const requestId = await this.poker.getLastRequestId();
    await this.oracle.publishRandomNumber(randomCards, this.poker.address, requestId, { from: owner });
    poolInfo = await this.poolController.getPoolInfo();
    assert.equal(poolInfo[1].toString(), 980320);
  });

  it('checking Color results', async () => {
    await this.poolController.addSon(owner, alice);
    await this.poolController.addSon(owner, bob);
    console.log(await this.poolController.getMyReferralStats(owner));
    await this.poker.play(100000, 1, { from: alice, callValue: 200000 });
    let requestId = await this.poker.getLastRequestId();
    await this.oracle.publishRandomNumber(randomCards, this.poker.address, requestId, { from: owner });
    await this.poker.play(100000, 1, { from: bob, callValue: 200000 });
    requestId = await this.poker.getLastRequestId();
    await this.oracle.publishRandomNumber(randomCards, this.poker.address, requestId, { from: owner });
    const refStats = await this.poolController.getMyReferralStats(owner);
    console.log(refStats.slice(1).map((item) => item.toString()));
    const aliceParentAddress = (await this.poolController.getMyReferralStats(alice))[0];
    const bobParentAddress = (await this.poolController.getMyReferralStats(bob))[0];
    assert.equal(aliceParentAddress, bobParentAddress);
  });
});
