// // thanks to tronbox and tvm this test is completely useless
// const { getHexAddress, simpleExpectRevert } = require('./utils/tronBSHelpers');
// const wait = require('./helpers/wait')
// const chalk = require('chalk')

// require('chai')
//   .use(require('chai-as-promised'))
//   .should();

// const XTRXToken = artifacts.require('XTRXToken');
// const PoolController = artifacts.require('PoolController');
// const Oracle = artifacts.require('Oracle');
// const Poker = artifacts.require('Poker');

// const userWinsCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];

// contract('MaxBetCalc test', async ([owner, alice, bob]) => {

//   before(async () => {
//     this.xTRX = await XTRXToken.deployed();
//     this.poolController = await PoolController.deployed();
//     this.oracle = await Oracle.deployed();
//     this.poker = await Poker.deployed();

//     await this.xTRX.setPoolController(this.poolController.address, { from: owner });
//     assert.equal(await this.xTRX.getPoolController({ from: owner }),(this.poolController.address));
//     await this.poolController.setGame(this.poker.address, { from: owner });
//     await this.oracle.setGame(this.poker.address, { from: owner });

//     assert.equal(await this.xTRX.balanceOf(owner, { from: owner }), 0);
//     await this.poker.setMaxBet(1000000000);
//     await this.poolController.deposit(owner, { from: owner, callValue: 54000000 });
//     await this.poolController.deposit(owner, { from: alice, callValue: 9000000000 });
//     await this.poolController.deposit(owner, { from: bob, callValue: 9000000000 });
//     assert.equal(((await this.poolController.getPoolInfo())[1]).toString(), 18054000000);
//   });

//   it('checking maxBetCalc', async () => {
//     for (let i = 0; i < 102; i++) {
//       await this.poker.startGame(0, 0, { from: alice, callValue: 30000000 });
//       const gameId = await this.poker.getLastRequestId();
//       await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, gameId, { from: owner });
//       console.log((await this.poker.getMaxBet()).toString(), 'iteration:', i);
//     }
//   })
// });
