const { getHexAddress, simpleExpectRevert } = require('./utils/tronBSHelpers');

require('chai')
  .use(require('chai-as-promised'))
  .should();

const XETHToken = artifacts.require('XETHToken');
const PoolController = artifacts.require('PoolController');
const GameController = artifacts.require('GameController');
const Oracle = artifacts.require('Oracle');
const Poker = artifacts.require('Poker');



const userWinsCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];
const drawCards = [0, 1, 12, 25, 38, 51, 13, 14, 26];
const computerWinsCards = [1, 2, 4, 6, 8, 9, 10, 11, 12];
const userWinsJackpotCards = [12, 11, 10, 9, 8, 5, 2, 1, 3];
const array = [1, 2, 3, 4, 5, 6, 7, 8, 9];
const array2 = [16, 1, 2, 3, 4, 5, 6, 7, 8];

const evenWinColorCards = [27, 1, 42]; // returns 2, 0, 3 even wins
const oddWinColorCards = [22, 47, 7]; // retruns 1, 3, 0 odd wins

contract('Poker test', async ([owner, alice, bob]) => {

  before(async () => {
    this.xETH = await XETHToken.deployed();
    this.poolController = await PoolController.deployed();
    this.oracle = await Oracle.deployed();
    this.poker = await Poker.deployed();

    await this.xETH.setPoolController(this.poolController.address, { from: owner });
    assert.equal(await this.xETH.getPoolController({ from: owner }),(this.poolController.address));
    await this.poolController.setGame(this.poker.address, { from: owner });
    await this.oracle.setGame(this.poker.address, { from: owner });
  });

  // it('checking maxBetCalc', async () => {
  //   assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 0);
  //   await this.poolController.deposit(owner, { from: owner, callValue: 1000000 });
  //   assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 1000000);
  //   // assert.equal((await this.poolController.getMaxBet({ from: owner })).toString(), 0);
  //   // await this.poolController.maxBetCalc(10000, 10000);
  //   console.log((await this.poolController.getMaxBet({ from: owner })).toString());
  //   await this.poolController.deposit(owner, { from: owner, callValue: 10000000 });
  //   await this.poolController.deposit(owner, { from: owner, callValue: 10000000 });
  //   await this.poolController.deposit(owner, { from: owner, callValue: 10000000 });
  //   await this.poolController.maxBetCalc(10000, 10000);
  //   console.log(await this.poolController.getMaxBet({ from: owner }));
  //   await this.poolController.maxBetCalc(5000, 5000);
  //   console.log(await this.poolController.getMaxBet({ from: owner }));
  //   await this.poolController.maxBetCalc(3000, 3000);
  //   console.log(await this.poolController.getMaxBet({ from: owner }));
  //   await this.poolController.maxBetCalc(1000, 1000);
  //   console.log(await this.poolController.getMaxBet({ from: owner }));
  //   await this.poolController.maxBetCalc(10000, 10000);
  //   console.log(await this.poolController.getMaxBet({ from: owner }));
  //   await this.poolController.maxBetCalc(10000, 10000);
  //   console.log(await this.poolController.getMaxBet({ from: owner }));
  //   await this.poolController.maxBetCalc(10000, 10000);
  //   console.log(await this.poolController.getMaxBet({ from: owner }));
  // })

  it('checkingToBit', async () => {
    console.log((await this.oracle.toBit(array)).toString());
  })


  describe('checking setters and getters:', async () => {
    describe('GameController functions', async () => {
      it('setOracle should work',async () => {
      this.poker.setOracle(this.oracle.address, { from: owner });
      assert.equal(await this.poker.getOracle({ from: owner }),(this.oracle.address));
      })
      it('setOracle should not work cause not Ioracle and not owner',async () => {
        this.poker.setOracle(this.poolController.address, { from: owner });
        this.poker.setOracle(this.poolController.address, { from: alice});
        assert.equal(await this.poker.getOracle({ from: owner }),(this.oracle.address));
      })
      it('getLastRequestId should work',async () => {
        await this.poker.getLastRequestId({ from: owner });
      })
      it('getLastRequestId should not work',async () => {
        simpleExpectRevert(this.poker.getLastRequestId(), 'not owner');
      })
    })
    describe('Poker functions', async () => {
      it('setPoolController should work',async () => {
        this.poker.setPoolController(this.poolController.address, { from: owner });
        assert.equal(await this.poker.getPoolController(), this.poolController.address);
      })
      it('setPoolController should not work',async () => {
        simpleExpectRevert(this.poker.setPoolController(this.poolController.address), "not owner");
      })
    })
  })

  describe('checking poker results:', async () => {
    it('user should win', async () => {
      assert.equal(await this.poker.setCards(userWinsCards), 2);
    });
    it('user should lose', async () => {
      assert.equal(await this.poker.setCards(computerWinsCards), 0);
    });
    it('should be draw', async () => {
      assert.equal(await this.poker.setCards(drawCards), 1);
    });
    it('user should win jackpot', async () => {
      assert.equal(await this.poker.setCards(userWinsJackpotCards), 3);
    });
  });

  describe('checking color results:', async () => {
    it('odd should win, player wins', async () => {
      assert.equal(await this.poker.determineWinnerColor(oddWinColorCards, 1), true);
    });
    it('odd should win, player looses', async () => {
      assert.equal(await this.poker.determineWinnerColor(oddWinColorCards, 0), false);
    });
     it('even should win, player wins', async () => {
      assert.equal(await this.poker.determineWinnerColor(evenWinColorCards, 0), true);
    });
    it('even should win, player looses', async () => {
      assert.equal(await this.poker.determineWinnerColor(evenWinColorCards, 1), false);
    });
  });

  describe('full workflow', async () => {
    it('checking Play workflow', async () => {
      assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 0);
      await this.poolController.deposit(owner, { from: owner, callValue: 1000000 });
      assert.equal((await this.xETH.balanceOf(owner, { from: owner })).toString(), 1000000);
      let poolInfo = await this.poolController.getPoolInfo();
      assert.equal(poolInfo[1].toString(), 1000000)
      await this.poker.play(10000, 1, { from: owner, callValue: 20000 });
      poolInfo = await this.poolController.getPoolInfo();
      assert.equal(poolInfo[1].toString(), 1020000);
      const requestId = await this.poker.getLastRequestId();
      await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
      poolInfo = await this.poolController.getPoolInfo();
      assert.equal(poolInfo[1].toString(), 980320);
    });
    it('checking getGameInfo', async () => {
      await this.poker.play(10000, 1, { from: owner, callValue: 20000 });
      const requestId = await this.poker.getLastRequestId();
      const gameInfo = await this.poker.getGameInfo(requestId, { from: owner });
      assert.equal(gameInfo[0].toString(), 10000);
      assert.equal(gameInfo[1].toString(), 10000);
      assert.equal(gameInfo[2].toString(), 1);
      assert.equal(gameInfo[3], getHexAddress(owner));
      const poolInfo = await this.poolController.getPoolInfo();
      assert.equal(poolInfo[1].toString(), 1000320);
    });
    it('checking jackpot payout', async () => {
      /// finishing game started above
      const requestId = await this.poker.getLastRequestId();
      await this.oracle.publishRandomNumber(userWinsJackpotCards, this.poker.address, requestId, { from: owner });
      const poolInfo = await this.poolController.getPoolInfo();
      assert.equal(poolInfo[1].toString(), 500280);
      assert.equal((await this.poolController.getJackpot()).toString(), 0);
    })
    it('checking jackpot increasing', async () => {
      await this.poker.play(10000, 1, { from: owner, callValue: 20000 });
      const requestId = await this.poker.getLastRequestId();
      await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
      assert.equal((await this.poolController.getJackpot()).toString(), 20);
    })

    describe('checking referral program', async () => {
      it('checking referral program adding referrals', async () => {
        let refsCounter = (await this.poolController.getMyReferralStats(owner))[4];
        assert.equal(refsCounter, 0);
        await this.poolController.addRef(owner, alice);
        await this.poolController.addRef(owner, bob);
        refsCounter = (await this.poolController.getMyReferralStats(owner))[4];
        assert.equal(refsCounter, 2);
        assert.equal((await this.poolController.getMyReferralStats(alice))[0], getHexAddress(owner));
        assert.equal((await this.poolController.getMyReferralStats(bob))[0], getHexAddress(owner));

      })
      it('checking referral program adding referral bonus', async () => {
        let refStats = (await this.poolController.getMyReferralStats(owner)).map(item => item.toString());
        let bonusPercent = refStats[1];
        let totalWinnings = refStats[2];
        let referralEarningsBalance = refStats[3];
        assert.equal(bonusPercent, 0);
        assert.equal(totalWinnings, 0);
        assert.equal(referralEarningsBalance, 0);
        await this.poker.play(100000, 1, { from: alice, callValue: 200000 });
        let requestId = await this.poker.getLastRequestId();
        await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
        refStats = (await this.poolController.getMyReferralStats(owner)).map(item => item.toString());
        bonusPercent = refStats[1];
        totalWinnings = refStats[2];
        referralEarningsBalance = refStats[3];
        /// updated to level 1
        assert.equal(bonusPercent, 1);
        assert.equal(totalWinnings, 396800);
        assert.equal(referralEarningsBalance, 30);
        await this.poker.play(100000, 1, { from: bob, callValue: 200000 });
        requestId = await this.poker.getLastRequestId();
        await this.oracle.publishRandomNumber(userWinsCards, this.poker.address, requestId, { from: owner });
        refStats = (await this.poolController.getMyReferralStats(owner)).map(item => item.toString());
        bonusPercent = refStats[1];
        totalWinnings = refStats[2];
        referralEarningsBalance = refStats[3];
        /// updated to level 2 now increased referral bonus
        assert.equal(bonusPercent, 2);
        assert.equal(totalWinnings, 793600);
        assert.equal(referralEarningsBalance, 90);
      })
      it('checking referralBonus withdraw', async () => {
        let refStats = (await this.poolController.getMyReferralStats(owner)).map(item => item.toString());
        let poolInfo = (await this.poolController.getPoolInfo()).map(item => item.toString());
        let referralEarningsBalance = refStats[3];
        let poolBalance = poolInfo[1];
        assert.equal(referralEarningsBalance, 90);
        assert.equal(poolBalance, 483800);
        await this.poolController.withdrawReferralEarnings(owner);
        refStats = (await this.poolController.getMyReferralStats(owner)).map(item => item.toString());
        poolInfo = (await this.poolController.getPoolInfo()).map(item => item.toString());
        referralEarningsBalance = refStats[3];
        poolBalance = poolInfo[1];
        assert.equal(referralEarningsBalance, 0);
        assert.equal(poolBalance, 483710);

      })
    });
  })
});
