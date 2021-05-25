// const { getHexAddress, simpleExpectRevert } = require('./utils/tronBSHelpers');
// const wait = require('./helpers/wait')
// const chalk = require('chalk')

// require('chai')
//   .use(require('chai-as-promised'))
//   .should();

// const XTRXToken = artifacts.require('XTRXToken');
// const PoolController = artifacts.require('PoolController');
// const GameController = artifacts.require('GameController');
// const Oracle = artifacts.require('Oracle');
// const Poker = artifacts.require('Poker');
// const FakePoker = artifacts.require('FakePoker');

// const userWinsCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];
// const drawCards = [0, 1, 12, 25, 38, 51, 13, 14, 26];
// const computerWinsCards = [1, 2, 4, 6, 8, 9, 10, 11, 12];
// const userWinsJackpotCards = [12, 11, 10, 9, 8, 5, 2, 1, 3];
// const array = [1, 2, 3, 4, 5, 6, 7, 8, 9];
// const checkingToBitArr = [1, 6, 13, 14, 24, 27, 44, 45, 50];
// const checkingToBitInt = 14274713982914945;

// const check = [12, 2, 21, 39, 24, 6, 35, 38, 29];

// const evenWinColorCards = [27, 1, 42]; // returns 2, 0, 3 even wins
// const oddWinColorCards = [22, 47, 7]; // retruns 1, 3, 0 odd wins

// const initHouseEdge = 15;
// const changedHouseEdge = 20;

// const initJackpotMultiplier = 2;
// const changedJackpotMultiplier = 5;

// contract('Poker test', async ([owner, alice, bob]) => {

//   before(async () => {
//     this.xTRX = await XTRXToken.deployed();
//     this.poolController = await PoolController.deployed();
//     this.oracle = await Oracle.deployed();
//     this.poker = await Poker.deployed();
//     this.fakePoker = await FakePoker.deployed();

//     await this.xTRX.setPoolController(this.poolController.address, { from: owner });
//     assert.equal(await this.xTRX.getPoolController({ from: owner }),(this.poolController.address));
//     await this.poolController.setGame(this.poker.address, { from: owner });
//     await this.oracle.setGame(this.poker.address, { from: owner });
//   });

//   it('checkingToBit', async () => {
//     assert.equal(await this.oracle.toBit(checkingToBitArr), checkingToBitInt);
//   })

//   it('setHouseEdge should change storage value', async () => {
//     assert.equal(await this.poker.getHouseEdge(), initHouseEdge);
//     await this.poker.setHouseEdge(changedHouseEdge, { from: owner });
//     assert.equal(await this.poker.getHouseEdge(), changedHouseEdge);
//     await this.poker.setHouseEdge(initHouseEdge, { from: owner });
//   });

//   it('setJackpotMultiplier should change storage value', async () => {
//     assert.equal(await this.poker.getJackpotFeeMultiplier(), initJackpotMultiplier);
//     await this.poker.setJackpotFeeMultiplier(changedJackpotMultiplier, { from: owner });
//     assert.equal(await this.poker.getJackpotFeeMultiplier(), changedJackpotMultiplier);
//     await this.poker.setJackpotFeeMultiplier(initJackpotMultiplier, { from: owner });
//   });


//   describe('checking setters and getters:', async () => {
//     describe('GameController functions', async () => {
//       it('setOracle should work',async () => {
//       this.poker.setOracle(this.oracle.address, { from: owner });
//       assert.equal(await this.poker.getOracle({ from: owner }),(this.oracle.address));
//       })
//       it('setOracle should not work cause not Ioracle and not owner',async () => {
//         this.poker.setOracle(this.poolController.address, { from: owner });
//         this.poker.setOracle(this.poolController.address, { from: alice});
//         assert.equal(await this.poker.getOracle({ from: owner }),(this.oracle.address));
//       })
//       it('getLastRequestId should work',async () => {
//         await this.poker.getLastRequestId({ from: owner });
//       })
//       it('getLastRequestId should not work',async () => {
//         simpleExpectRevert(this.poker.getLastRequestId(), 'not owner');
//       })
//     })
//     describe('Poker functions', async () => {
//       it('setPoolController should work',async () => {
//         this.poker.setPoolController(this.poolController.address, { from: owner });
//         assert.equal(await this.poker.getPoolController(), this.poolController.address);
//       })
//       it('setPoolController should not work',async () => {
//         simpleExpectRevert(this.poker.setPoolController(this.poolController.address), "not owner");
//       })
//     })
//   })

//   describe('checking poker results:', async () => {
//     it('user should win', async () => {
//       assert.equal(await this.fakePoker.setCards(userWinsCards), 2);
//     });
//     it('user should lose', async () => {
//       assert.equal(await this.fakePoker.setCards(computerWinsCards), 0);
//     });
//     it('should be draw', async () => {
//       assert.equal(await this.fakePoker.setCards(drawCards), 1); 
//     });
//     it('user should win jackpot', async () => {
//       assert.equal(await this.fakePoker.setCards(userWinsJackpotCards), 3);
//     });
//     it('check', async () => {
//       console.log(await this.fakePoker.checkCombinationResult(check));
//       // assert.equal(await this.fakePoker.setCards(check), 3); 
//     });
//   });

//   describe('checking color results:', async () => {
//     it('odd should win, player wins', async () => {
//       assert.equal(await this.fakePoker.getColorResult(oddWinColorCards, 1), true);
//     });
//     it('odd should win, player looses', async () => {
//       assert.equal(await this.fakePoker.getColorResult(oddWinColorCards, 0), false);
//     });
//      it('even should win, player wins', async () => {
//       assert.equal(await this.fakePoker.getColorResult(evenWinColorCards, 0), true);
//     });
//     it('even should win, player looses', async () => {
//       assert.equal(await this.fakePoker.getColorResult(evenWinColorCards, 1), false);
//     });
//   });

//   describe('full workflow', async () => {
//     it('checking Play workflow', async () => {
//       assert.equal(await this.xTRX.balanceOf(owner, { from: owner }), 0);
//       await this.poker.setMaxBet(1000000000);
//       await this.poolController.deposit(owner, { from: owner, callValue: 1000000000 });
//       assert.equal((await this.xTRX.balanceOf(owner, { from: owner })).toString(), 1000000000);
//       let poolInfo = await this.poolController.getPoolInfo();
//       assert.equal(poolInfo[1].toString(), 1000000000);
//       await this.poker.play(0, 0, { from: alice, callValue: 50000000 });
//       poolInfo = await this.poolController.getPoolInfo();
//       // depostited + bet - energy fee
//       assert.equal(poolInfo[1].toString(), 1038000000);
//       const requestId = await this.poker.getLastRequestId();
//       await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
//       poolInfo = await this.poolController.getPoolInfo();
//       // whats left after user wins
//       assert.equal(poolInfo[1].toString(), 938850000);
//     });
//     it('checking getGameInfo', async () => {
//       await this.poker.play(10000000, 1, { from: bob, callValue: 50000000 });
//       const requestId = await this.poker.getLastRequestId();
//       const gameInfo = await this.poker.getGameInfo(requestId, { from: bob });
//       assert.equal(gameInfo[0].toString(), 10000000);
//       assert.equal(gameInfo[1].toString(), 40000000);
//       assert.equal(gameInfo[2].toString(), 1);
//       assert.equal(gameInfo[3], getHexAddress(bob));
//       const poolInfo = await this.poolController.getPoolInfo();
//       // pool balance from previous test - energy fee(12trx) + 50trx bet
//       assert.equal(poolInfo[1].toString(), 976850000);
//     });

//     it('checking jackpot payout', async () => {
//       /// finishing game started above
//       const requestId = await this.poker.getLastRequestId();
//       await this.oracle.publishRandomNumber(userWinsJackpotCards, this.poker.address, requestId, { from: owner });
//       const poolInfo = await this.poolController.getPoolInfo();

//       assert.equal(poolInfo[1].toString(), 976170000);
//       assert.equal((await this.poolController.getJackpot()).toString(), 0);

//     });

//     it('checking jackpot increasing', async () => {
//       await this.poker.play(10000000, 1, { from: owner, callValue: 50000000 });
//       const requestId = await this.poker.getLastRequestId();
//       await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
//       assert.equal((await this.poolController.getJackpot()).toString(), 80000);
//     });

//     describe('checking referral program', async () => {
//       it('checking referral program adding referrals', async () => {
//         let refsCounter = (await this.poolController.getReferralStats(owner))[4];
//         assert.equal(refsCounter, 0);
//         await this.poolController.addRef(owner, alice, { from: alice });
//         await this.poolController.addRef(owner, bob, { from: bob });
//         simpleExpectRevert(this.poolController.addRef(bob, alice, { from: bob }), "Already a referral");
//         refsCounter = (await this.poolController.getReferralStats(owner))[4];
//         assert.equal(refsCounter, 2);
//         assert.equal((await this.poolController.getReferralStats(alice))[0], getHexAddress(owner));
//         assert.equal((await this.poolController.getReferralStats(bob))[0], getHexAddress(owner));
//       });

//       it('checking referral program adding referral bonus', async () => {
//         let refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
//         let bonusPercent = refStats[1];
//         let totalWinnings = refStats[2];
//         let referralEarningsBalance = refStats[3];
//         assert.equal(bonusPercent, 0);
//         assert.equal(totalWinnings, 0);
//         assert.equal(referralEarningsBalance, 0);
//         await this.poker.play(0, 0, { from: alice, callValue: 100000000 });
//         let requestId = await this.poker.getLastRequestId();
//         await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
//         refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
//         bonusPercent = refStats[1];
//         totalWinnings = refStats[2];
//         referralEarningsBalance = refStats[3];
//         /// updated to level 1
//         assert.equal(bonusPercent, 1);
//         assert.equal(totalWinnings, 198300000);
//         assert.equal(referralEarningsBalance, 15000);
//         await this.poker.play(100000000, 0, { from: bob, callValue: 200000000 });
//         requestId = await this.poker.getLastRequestId();
//         await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
//         refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
//         bonusPercent = refStats[1];
//         totalWinnings = refStats[2];
//         referralEarningsBalance = refStats[3];
//         assert.equal(bonusPercent, 1);
//         assert.equal(totalWinnings, 396600000);
//         assert.equal(referralEarningsBalance, 30000);
//       });

//       it('checking referralBonus withdraw', async () => {
//         let refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
//         let poolInfo = (await this.poolController.getPoolInfo()).map(item => item.toString());
//         let referralEarningsBalance = refStats[3];
//         let poolBalance = poolInfo[1];
//         assert.equal(referralEarningsBalance, 30000);
//         assert.equal(poolBalance, 794400000);
//         await this.poolController.withdrawReferralEarnings(owner);
//         refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
//         poolInfo = (await this.poolController.getPoolInfo()).map(item => item.toString());
//         referralEarningsBalance = refStats[3];
//         poolBalance = poolInfo[1];
//         assert.equal(referralEarningsBalance, 0);
//         assert.equal(poolBalance, 794370000);
//       });
//     });

//     describe('checking takeOracleFee', async () => {
//       it('takeOracleFee posititive', async () => {
//         let oracleFeeAmount = (await this.poolController.getPoolInfo())[3].toString();
//         // poker was played 5 time so, 5 * oracleFee
//         assert.equal(oracleFeeAmount, 60000000);
//         await this.poolController.setOracleOperator(owner, { from: owner });
//         await this.poolController.takeOracleFee({ from: owner });
//         oracleFeeAmount = (await this.poolController.getPoolInfo())[3].toString();
//         assert.equal(oracleFeeAmount, 0);
//       })

//       it('takeOracleFee negative', async () => {
//         simpleExpectRevert(this.poolController.takeOracleFee({ from: alice }), 'Not operator');
//       })
//     })
//   })
// });
