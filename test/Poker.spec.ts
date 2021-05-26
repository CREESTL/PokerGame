import { ethers, waffle } from 'hardhat';
import { PoolController } from '../typechain/PoolController';
import { XTRXToken } from '../typechain/XTRXToken';
import { Poker } from '../typechain/Poker';
import { MockPoker } from '../typechain/MockPoker';
import { Oracle } from '../typechain/Oracle';
import { expect } from './shared/expect';
import { contractsFixture } from './shared/fixtures';
// @ts-ignore
import { ether } from 'openzeppelin-test-helpers';
import { BigNumberish } from 'ethers';

const { constants } = ethers;

const TEST_ADDRESSES: [string, string] = [
  '0x1000000000000000000000000000000000000000',
  '0x2000000000000000000000000000000000000000',
];

const createFixtureLoader = waffle.createFixtureLoader;

type ThenArg<T> = T extends PromiseLike<infer U> ? U : T;

const computerWinsCards = [1, 2, 4, 6, 8, 9, 10, 11, 12];
const drawCards = [0, 1, 12, 25, 38, 51, 13, 14, 26];
const winCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];
const winJackpotCards = [12, 11, 10, 9, 8, 5, 2, 1, 3];

const evenWinColorCards = [12, 25, 38]; // returns 2, 0, 3 even wins
const oddWinColorCards = [22, 47, 7]; // returns 1, 3, 0 odd wins

const checkingToBitArr = [1, 6, 13, 14, 24, 27, 44, 45, 50];
const checkingToBitInt = '14274713982914945';

const initHouseEdge = 15;
const changedHouseEdge = 20;

const initJackpotMultiplier = 2;
const changedJackpotMultiplier = 5;

describe('Poker', () => {
  const [wallet, other] = waffle.provider.getWallets();


  let xTRX: XTRXToken;
  let poolController: PoolController;
  let oracle: Oracle;
  let poker: Poker;
  let mockPoker: MockPoker;

  let loadFixture: ReturnType<typeof createFixtureLoader>;

  before('create fixture loader', async () => {
    loadFixture = createFixtureLoader([wallet, other])
  })

  beforeEach('deploy fixture', async () => {
    ;({
      xTRX,
      poolController,
      oracle,
      poker,
      mockPoker,
    } = await loadFixture(contractsFixture));
  })

  it('toBit func should convert array of cards to correct binary num', async () => {
    expect(await oracle.toBit(checkingToBitArr)).to.equal(checkingToBitInt);
  })

  // setter and getters

  describe('check setters and getters', async () => {
    it('setHouseEdge should change storage value', async () => {
      expect(await poker.houseEdge()).to.equal(initHouseEdge);
      await poker.setHouseEdge(changedHouseEdge);
      expect(await poker.houseEdge()).to.equal(changedHouseEdge);
    });
  
    it('setJackpotMultiplier should change storage value', async () => {
      expect(await poker.jackpotFeeMultiplier()).to.equal(initJackpotMultiplier);
      await poker.setJackpotFeeMultiplier(changedJackpotMultiplier);
      expect(await poker.jackpotFeeMultiplier()).to.equal(changedJackpotMultiplier);
    });

    it('setOracle should work', async () => {
      await poker.setOracle(oracle.address);
      expect(await poker.getOracle()).to.equal(oracle.address);
    })
    
    it('getLastRequestId should work', async () => {
      await poker.getLastRequestId();
    })

    it('getLastRequestId should not work', async () => {
      await expect(poker.getLastRequestId({ from: other.address })).to.be.reverted;
    })

    it('setPoolController should work',async () => {
      await poker.setPoolController(poolController.address);
      expect(await poker.getPoolController()).to.equal(poolController.address);
    })
  });

  describe('check poker results', async () => {
    it('poker result should be lose', async () => {
      expect(await poker.getPokerResult(computerWinsCards)).to.equal(0);
    })

    it('poker result should be draw', async () => {
      expect(await poker.getPokerResult(drawCards)).to.equal(1);
    })

    it('poker result should be win', async () => {
      expect(await poker.getPokerResult(winCards)).to.equal(2);
    })

    it('poker result should be win jackpot', async () => {
      expect(await poker.getPokerResult(winJackpotCards)).to.equal(3);
    })
  })

  describe('full workflow', async () => {
    it('checking play workflow, user wins poker and color', async () => {
      expect (await xTRX.balanceOf(wallet.address)).to.equal(0);
      await poolController.deposit(wallet.address, { value: 100000000000 });
      expect ((await xTRX.balanceOf(wallet.address))).to.equal(100000000000);
      let poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100000000000);
      // @ts-ignore
      await poker.play(0, 0, { from: wallet.address, value: 100000000 });
      poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100088000000);
      const requestId = await poker.getLastRequestId();
      const winPoker = await poker.getPokerResult(winCards);
      const winColor = await poker.getColorResult(requestId, evenWinColorCards);

      const gameResults = await poker.calculateWinAmount(requestId, winPoker, winColor);
      expect(gameResults[0]).to.equal(198300000);
      expect(gameResults[1]).to.equal(0);
      expect(gameResults[2]).to.equal(1500000);

      await poker.setGameWinAmount(requestId, (gameResults[0].add(gameResults[1])));

      const gameInfo = await poker.games(requestId);
      expect(gameInfo[2]).to.equal(gameResults[0].add(gameResults[1]));
    });

    it('checking play workflow, user loses poker and wins color', async () => {
      expect (await xTRX.balanceOf(wallet.address)).to.equal(0);
      await poolController.deposit(wallet.address, { value: 100000000000 });
      expect ((await xTRX.balanceOf(wallet.address))).to.equal(100000000000);
      let poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100000000000);
      // @ts-ignore
      await poker.play(10000000, 0, { from: wallet.address, value: 100000000 });
      poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100088000000);
      const requestId = await poker.getLastRequestId();
      const winPoker = await poker.getPokerResult(computerWinsCards);
      const winColor = await poker.getColorResult(requestId, evenWinColorCards);

      const gameResults = await poker.calculateWinAmount(requestId, winPoker, winColor);
      expect(gameResults[0]).to.equal(0);
      expect(gameResults[1]).to.equal(19850000);
      expect(gameResults[2]).to.equal(150000);

      await poker.setGameWinAmount(requestId, (gameResults[0].add(gameResults[1])));

      const gameInfo = await poker.games(requestId);
      expect(gameInfo[2]).to.equal(gameResults[0].add(gameResults[1]));
    });

    it('checking play workflow, user loses poker and loses color', async () => {
      expect (await xTRX.balanceOf(wallet.address)).to.equal(0);
      await poolController.deposit(wallet.address, { value: 100000000000 });
      expect ((await xTRX.balanceOf(wallet.address))).to.equal(100000000000);
      let poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100000000000);
      // @ts-ignore
      await poker.play(10000000, 0, { from: wallet.address, value: 100000000 });
      poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100088000000);
      const requestId = await poker.getLastRequestId();
      const winPoker = await poker.getPokerResult(computerWinsCards);
      const winColor = await poker.getColorResult(requestId, oddWinColorCards);

      const gameResults = await poker.calculateWinAmount(requestId, winPoker, winColor);
      expect(gameResults[0]).to.equal(0);
      expect(gameResults[1]).to.equal(0);
      expect(gameResults[2]).to.equal(0);

      await poker.setGameWinAmount(requestId, (gameResults[0].add(gameResults[1])));

      const gameInfo = await poker.games(requestId);
      expect(gameInfo[2]).to.equal(gameResults[0].add(gameResults[1]));
    });

    it('check jackpot increasing', async () => {
      // this is mock init jackpot value testing
      expect(await poolController.jackpot()).to.equal(500000);
      // every bet adds 200 000 to jackpot, so +20 000 000 after 100 games
      for (let i = 0; i < 100; i++) {
        await poker.play(0, 0, { value: 100000000 });
      }
      // expect(await poolController.getJackpot()).to.equal(20500000);
    })

    // it('checking play workflow, user wins poker, and color', async () => {
    //   await this.poker.play(10000000, 1, { from: bob, callValue: 50000000 });
    //   const requestId = await this.poker.getLastRequestId();
    //   const gameInfo = await this.poker.getGameInfo(requestId, { from: bob });
    //   assert.equal(gameInfo[0].toString(), 10000000);
    //   assert.equal(gameInfo[1].toString(), 40000000);
    //   assert.equal(gameInfo[2].toString(), 1);
    //   assert.equal(gameInfo[3], getHexAddress(bob));
    //   const poolInfo = await this.poolController.getPoolInfo();
    //   // pool balance from previous test - energy fee(12trx) + 50trx bet
    //   assert.equal(poolInfo[1].toString(), 976850000);
    // });

    // it('checking jackpot payout', async () => {
    //   /// finishing game started above
    //   const requestId = await this.poker.getLastRequestId();
    //   await this.oracle.publishRandomNumber(userWinsJackpotCards, this.poker.address, requestId, { from: owner });
    //   const poolInfo = await this.poolController.getPoolInfo();

    //   assert.equal(poolInfo[1].toString(), 976170000);
    //   assert.equal((await this.poolController.getJackpot()).toString(), 0);

    // });

    // it('checking jackpot increasing', async () => {
    //   await this.poker.play(10000000, 1, { from: owner, callValue: 50000000 });
    //   const requestId = await this.poker.getLastRequestId();
    //   await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
    //   assert.equal((await this.poolController.getJackpot()).toString(), 80000);
    // });

    // describe('checking referral program', async () => {
    //   it('checking referral program adding referrals', async () => {
    //     let refsCounter = (await this.poolController.getReferralStats(owner))[4];
    //     assert.equal(refsCounter, 0);
    //     await this.poolController.addRef(owner, alice, { from: alice });
    //     await this.poolController.addRef(owner, bob, { from: bob });
    //     simpleExpectRevert(this.poolController.addRef(bob, alice, { from: bob }), "Already a referral");
    //     refsCounter = (await this.poolController.getReferralStats(owner))[4];
    //     assert.equal(refsCounter, 2);
    //     assert.equal((await this.poolController.getReferralStats(alice))[0], getHexAddress(owner));
    //     assert.equal((await this.poolController.getReferralStats(bob))[0], getHexAddress(owner));
    //   });

    //   it('checking referral program adding referral bonus', async () => {
    //     let refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
    //     let bonusPercent = refStats[1];
    //     let totalWinnings = refStats[2];
    //     let referralEarningsBalance = refStats[3];
    //     assert.equal(bonusPercent, 0);
    //     assert.equal(totalWinnings, 0);
    //     assert.equal(referralEarningsBalance, 0);
    //     await this.poker.play(0, 0, { from: alice, callValue: 100000000 });
    //     let requestId = await this.poker.getLastRequestId();
    //     await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
    //     refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
    //     bonusPercent = refStats[1];
    //     totalWinnings = refStats[2];
    //     referralEarningsBalance = refStats[3];
    //     /// updated to level 1
    //     assert.equal(bonusPercent, 1);
    //     assert.equal(totalWinnings, 198300000);
    //     assert.equal(referralEarningsBalance, 15000);
    //     await this.poker.play(100000000, 0, { from: bob, callValue: 200000000 });
    //     requestId = await this.poker.getLastRequestId();
    //     await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
    //     refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
    //     bonusPercent = refStats[1];
    //     totalWinnings = refStats[2];
    //     referralEarningsBalance = refStats[3];
    //     assert.equal(bonusPercent, 1);
    //     assert.equal(totalWinnings, 396600000);
    //     assert.equal(referralEarningsBalance, 30000);
    //   });

    //   it('checking referralBonus withdraw', async () => {
    //     let refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
    //     let poolInfo = (await this.poolController.getPoolInfo()).map(item => item.toString());
    //     let referralEarningsBalance = refStats[3];
    //     let poolBalance = poolInfo[1];
    //     assert.equal(referralEarningsBalance, 30000);
    //     assert.equal(poolBalance, 794400000);
    //     await this.poolController.withdrawReferralEarnings(owner);
    //     refStats = (await this.poolController.getReferralStats(owner)).map(item => item.toString());
    //     poolInfo = (await this.poolController.getPoolInfo()).map(item => item.toString());
    //     referralEarningsBalance = refStats[3];
    //     poolBalance = poolInfo[1];
    //     assert.equal(referralEarningsBalance, 0);
    //     assert.equal(poolBalance, 794370000);
    //   });
    // });

    // describe('checking takeOracleFee', async () => {
    //   it('takeOracleFee posititive', async () => {
    //     let oracleFeeAmount = (await this.poolController.getPoolInfo())[3].toString();
    //     // poker was played 5 time so, 5 * oracleFee
    //     assert.equal(oracleFeeAmount, 60000000);
    //     await this.poolController.setOracleOperator(owner, { from: owner });
    //     await this.poolController.takeOracleFee({ from: owner });
    //     oracleFeeAmount = (await this.poolController.getPoolInfo())[3].toString();
    //     assert.equal(oracleFeeAmount, 0);
    //   })

    //   it('takeOracleFee negative', async () => {
    //     simpleExpectRevert(this.poolController.takeOracleFee({ from: alice }), 'Not operator');
    //   })
    // })
  })

})
