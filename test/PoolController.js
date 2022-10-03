// /* eslint-disable max-len */

// const {
//   BN,
//   expectRevert,
//   balance,
// } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');
// require('chai')
//   .use(require('chai-as-promised'))
//   .should();
// const { getBNEth } = require('./utils/getBN');
// const { dumbArrayToString } = require('./utils/dumbArrayToString');
// const { getHexAddress, simpleExpectRevert } = require('./utils/tronBSHelpers');

// const XTRXToken = artifacts.require('XTRXToken');
// const Oracle = artifacts.require('Oracle');
// const PoolController = artifacts.require('PoolController');

// contract('PoolController', async ([owner, alice, bob]) => {
//   const ZERO_ADDRESS = '410000000000000000000000000000000000000000';
//   const ETH_ADDRESS = '410000000000000000000000000000000000000001';
//   const initTotalWinningsMilestones = [0, 20000000000, 60000000000, 100000000000, 140000000000, 180000000000, 220000000000];
//   const initBonusPercentMilestones = [1, 2, 4, 6, 8, 10, 12];
//   const changedTotalWinningsMilestones = ['10', '120000000000', '160000000000', '1100000000000', '1140000000000', '1180000000000', '1220000000000'];
//   const changedBonusPercentMilestones = [11, 12, 14, 16, 18, 110, 112];

//   const initJackpot = 500000;
//   const changedJackPot = 5000000;
//   const initJackpotLimit = 1000000;
//   const changedJackPotLimit = 10000000;

//   beforeEach(async () => {
//     this.xTRX = await XTRXToken.deployed();
//     this.poolController = await PoolController.deployed();
//     this.oracle = await Oracle.deployed();
//   });

//   describe('checking poolController functions:', async () => {
//     it('checking supportsIPool function', async () => {
//       assert.isTrue(await this.poolController.supportsIPool());
//     });

//     it('checking getPoolInfo function', async () => {
//       const ethPoolInfo = await this.poolController.getPoolInfo();
//       expect(ethPoolInfo[0]).to.equal(this.xTRX.address);
//       assert.equal(ethPoolInfo[1], 0);
//       assert.equal(ethPoolInfo[2].toString(), 12000000);
//       assert.equal(ethPoolInfo[3], 0);
//     });

//     it('checking setOracleOperator function', async () => {
//       assert.equal(await this.poolController.getOracleOperator(), ZERO_ADDRESS);
//       await this.poolController.setOracleOperator(alice, { from: owner });
//       assert.equal(await this.poolController.getOracleOperator(), getHexAddress(alice));
//       simpleExpectRevert(this.poolController.setOracleOperator(owner, { from: alice }), 'not owner');
//       assert.equal(await this.poolController.getOracleOperator(), getHexAddress(alice));
//     });

//     it('setTotalWinningsMilestones should change storage value', async () => {
//       assert.equal(dumbArrayToString(await this.poolController.getTotalWinningsMilestones()) , dumbArrayToString(initTotalWinningsMilestones));
//       await this.poolController.setTotalWinningsMilestones(changedTotalWinningsMilestones, { from: owner });
//       assert.equal(dumbArrayToString(await this.poolController.getTotalWinningsMilestones()) , dumbArrayToString(changedTotalWinningsMilestones));
//     });

//     it('setBonusPercentMilestones should change storage value', async () => {
//       assert.equal(dumbArrayToString(await this.poolController.getBonusPercentMilestones()) , dumbArrayToString(initBonusPercentMilestones));
//       await this.poolController.setBonusPercentMilestones(changedBonusPercentMilestones, { from: owner });
//       assert.equal(dumbArrayToString(await this.poolController.getBonusPercentMilestones()) , dumbArrayToString(changedBonusPercentMilestones));
//     });

//     it('setJackpot should change storage value', async () => {
//       assert.equal(await this.poolController.getJackpot(), initJackpot);
//       await this.poolController.setJackpot(changedJackPot, { from: owner });
//       assert.equal(await this.poolController.getJackpot(), changedJackPot);
//     });

//     it('setJackpotLimit should change storage value', async () => {
//       assert.equal(await this.poolController.getJackpotLimit(), initJackpotLimit);
//       await this.poolController.setJackpotLimit(changedJackPotLimit, { from: owner });
//       assert.equal(await this.poolController.getJackpotLimit(), changedJackPotLimit);
//     });

//     it('checking depositToken function', async () => {
//       assert.equal(await this.xTRX.balanceOf(owner, { from: owner }), 0);
//       await this.xTRX.setPoolController(this.poolController.address, { from: owner });
//       await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
//       assert.equal(await this.xTRX.balanceOf(owner, { from: owner }), 1000);
//     });

//     describe('checking withdraw functions:', async () => {
//       beforeEach(async () => {
//         await this.xTRX.setPoolController(this.poolController.address, { from: owner });
//         await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
//         assert.equal(await this.xTRX.balanceOf(owner, { from: owner }), 2000);
//       });

//       it('checking withdraw function', async () => {

//         assert.equal(await this.xTRX.balanceOf(owner), 2000);
//         await this.poolController.withdraw(1000, { from: owner });
//         assert.equal(await this.xTRX.balanceOf(owner, { from: owner }), 1000);
//       });

//       it('failing withdraw function', async () => {
//         assert.equal(await this.xTRX.balanceOf(owner, { from: owner }), 2000);
//         simpleExpectRevert(this.poolController.withdraw(3000, { from: owner }), 'not enough funds');
//         await this.poolController.withdraw(1000, { from: owner });
//         simpleExpectRevert(this.poolController.withdraw(1001, { from: owner }), 'not enough funds');
//         assert.equal(await this.xTRX.balanceOf(owner, { from: owner }), 1000);
//       });
//     });

//     describe('checking whitelist functions:', async () => {
//       it('checking addToWhitelist function', async () => {
//         simpleExpectRevert(this.poolController.deposit(alice, { from: alice, callValue: 1000 }), 'Deposit not allowed');
//         await this.poolController.addToWhitelist(alice, { from: owner });
//         simpleExpectRevert(this.poolController.addToWhitelist(alice, { from: owner }), 'Already added');
//         await this.poolController.deposit(alice, { from: alice, callValue: 1000 });
//       });

//       it('checking removeFromWhitelist function', async () => {
//         await this.poolController.deposit(alice, { from: alice, callValue: 1000 });
//         await this.poolController.removeFromWhitelist(alice, { from: owner });
//         simpleExpectRevert(this.poolController.deposit(alice, { from: alice, callValue: 1000 }), 'Deposit not allowed');
//       });
//     });
//   });
// });
