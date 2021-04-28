// thanks to tronbox and tvm this test is completely useless
const { getHexAddress, simpleExpectRevert } = require('./utils/tronBSHelpers');
const wait = require('./helpers/wait')
const chalk = require('chalk')

require('chai')
  .use(require('chai-as-promised'))
  .should();

const XETHToken = artifacts.require('XETHToken');
const PoolController = artifacts.require('PoolController');
const Oracle = artifacts.require('Oracle');
const Poker = artifacts.require('Poker');



const userWinsCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];

contract('MaxBetCalc test', async ([owner, alice, bob]) => {

  before(async () => {
    this.xETH = await XETHToken.deployed();
    this.poolController = await PoolController.deployed();
    this.oracle = await Oracle.deployed();
    this.poker = await Poker.deployed();

    await this.xETH.setPoolController(this.poolController.address, { from: owner });
    assert.equal(await this.xETH.getPoolController({ from: owner }),(this.poolController.address));
    await this.poolController.setGame(this.poker.address, { from: owner });
    await this.oracle.setGame(this.poker.address, { from: owner });

    assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 0);
    await this.poker.setMaxBet(1000000000);
    await this.poolController.deposit(owner, { from: owner, callValue: 5000000000 });
    await this.poolController.deposit(owner, { from: bob, callValue: 5000000000 });
    assert.equal((await this.xETH.balanceOf(owner, { from: owner })).toString(), 10000000000);
    assert.equal(((await this.poolController.getPoolInfo())[1]).toString(), 10000000000);
  });

  it('checking maxBetCalc', async () => {      
    for (let i = 0; i < 102; i++) {
      await this.poker.play(0, 0, { from: alice, callValue: 50000000 });
      const poolInfo = await this.poolController.getPoolInfo();
      const requestId = await this.poker.getLastRequestId();
      await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
      console.log(poolInfo[1].toString(), i);
    }
  })
});
