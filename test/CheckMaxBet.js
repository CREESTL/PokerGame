const { getHexAddress, simpleExpectRevert } = require('./utils/tronBSHelpers');
const wait = require('./helpers/wait')
const chalk = require('chalk')

require('chai')
  .use(require('chai-as-promised'))
  .should();

const XETHToken = artifacts.require('XETHToken');
const PoolController = artifacts.require('PoolController');
const GameController = artifacts.require('GameController');
const Oracle = artifacts.require('Oracle');
const FakePoker = artifacts.require('FakePoker');



const userWinsCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];
const drawCards = [0, 1, 12, 25, 38, 51, 13, 14, 26];
const computerWinsCards = [1, 2, 4, 6, 8, 9, 10, 11, 12];
const userWinsJackpotCards = [12, 11, 10, 9, 8, 5, 2, 1, 3];
const array = [1, 2, 3, 4, 5, 6, 7, 8, 9];
const checkingToBitArr = [1, 6, 13, 14, 24, 27, 44, 45, 50];
const checkingToBitInt = 14274713982914945;

const evenWinColorCards = [27, 1, 42]; // returns 2, 0, 3 even wins
const oddWinColorCards = [22, 47, 7]; // retruns 1, 3, 0 odd wins

contract('MaxBetCalc test', async ([owner, alice, bob]) => {

  before(async () => {
    this.xETH = await XETHToken.deployed();
    this.poolController = await PoolController.deployed();
    this.oracle = await Oracle.deployed();
    this.fakePoker = await FakePoker.deployed();

    await this.xETH.setPoolController(this.poolController.address, { from: owner });
    assert.equal(await this.xETH.getPoolController({ from: owner }),(this.poolController.address));
    await this.poolController.setGame(this.fakePoker.address, { from: owner });
    await this.oracle.setGame(this.fakePoker.address, { from: owner });
  });

  it('checking maxBetCalc', async () => {
    assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 0);
    await this.poolController.deposit(owner, { from: owner, callValue: 1000000 });
    assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 1000000);
    // assert.equal((await this.poolController.getMaxBet({ from: owner })).toString(), 0);
    // await this.poolController.maxBetCalc(10000, 10000);
    assert.equal((await this.fakePoker.getMaxBet({ from: owner })).toString(), 0);
    assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 1000000);
    await this.poolController.deposit(owner, { from: owner, callValue: 1000000000 });
   
    await this.fakePoker.maxBetCalc(10000, 10000);
    assert.equal((await this.fakePoker.getMaxBet({ from: owner })).toString(), 4352173);
    await this.fakePoker.maxBetCalc(5000, 5000);
    assert.equal((await this.fakePoker.getMaxBet({ from: owner })).toString(), 4352173);
    await this.fakePoker.maxBetCalc(3000, 3000);
    assert.equal((await this.fakePoker.getMaxBet({ from: owner })).toString(), 9183486);
    await this.fakePoker.maxBetCalc(1000, 1000);
    assert.equal((await this.fakePoker.getMaxBet({ from: owner })).toString(), 9183486);
    await this.poolController.deposit(owner, { from: owner, callValue: 1000000000 });
    await this.fakePoker.maxBetCalc(10000, 10000);
    assert.equal((await this.fakePoker.getMaxBet({ from: owner })).toString(), 9183486);
    await this.fakePoker.maxBetCalc(10000, 10000);
    assert.equal((await this.fakePoker.getMaxBet({ from: owner })).toString(), 18357798);
    await this.fakePoker.maxBetCalc(10000, 10000);
    assert.equal((await this.fakePoker.getMaxBet({ from: owner })).toString(), 18357798);
  })
});
