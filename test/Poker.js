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
const FakeGameController = artifacts.require('FakeGameController');
const Oracle = artifacts.require('Oracle');
const Poker = artifacts.require('Poker');



const randomCards = [11, 10, 9, 8, 7, 16, 29, 42, 22];
const colorCards = [1, 3, 13];

contract('Poker test', async ([owner, alice, bob]) => {

  beforeEach(async () => {
    this.xETH = await XETHToken.deployed();
    this.poolController = await PoolController.deployed();
    // this.fakeGameController = await FakeGameController.deployed();
    this.oracle = await Oracle.deployed();
    this.poker = await Poker.deployed();
    
    
    await this.xETH.setPoolController(this.poolController.address, { from: owner });
    assert.equal(await this.xETH.getPoolController({ from: owner }),(this.poolController.address));
    await this.poolController.setGame(this.poker.address);
    await this.oracle.setGame(this.poker.address);
  });

  it('checking Poker results', async () => {
    console.log(await this.poker.setCards(randomCards));
  });
  
  it('checking contracts together ', async () => {
    assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 0);
    await this.poolController.deposit(owner, { from: owner, callValue: 1000000 });
    assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 1000000);
    const poolInfo1 = await this.poolController.getPoolInfo();
    assert.equal(poolInfo1[1].toString(), 1000000)
    await this.poker.play(0, 10000, 0, { from: owner, callValue: 20000 });
    const poolInfo2 = await this.poolController.getPoolInfo();
    assert.equal(poolInfo2[1].toString(), 1020000);
    console.log(await this.oracle.publishRandomNumber(randomCards, this.poker.address, 0, { from: owner }));
    const poolInfo3 = await this.poolController.getPoolInfo();
    console.log(poolInfo3[1].toString());
  });
});
