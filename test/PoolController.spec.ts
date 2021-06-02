import { ethers, waffle } from 'hardhat';
import { Oracle } from '../typechain/Oracle';
import { Poker } from '../typechain/Poker';
import { PoolController } from '../typechain/PoolController';
import { expect } from './shared/expect';
import { contractsFixture } from './shared/fixtures';
import { dumbArrayToString } from './utils';

const { constants } = ethers;

const TEST_ADDRESSES: [string, string] = [
  '0x1000000000000000000000000000000000000000',
  '0x2000000000000000000000000000000000000000',
];

const initTotalWinningsMilestones = [0, 20000000000, 60000000000, 100000000000, 140000000000, 180000000000, 220000000000];
const initBonusPercentMilestones = [1, 2, 4, 6, 8, 10, 12];
const changedTotalWinningsMilestones = ['10', '120000000000', '160000000000', '1100000000000', '1140000000000', '1180000000000', '1220000000000'];
const changedBonusPercentMilestones = [11, 12, 14, 16, 18, 110, 112];


const winCards = [11, 10, 22, 47, 7, 5, 2, 1, 3];
const winJackpotCards = [12, 11, 10, 9, 8, 5, 2, 1, 3];

const evenWinColorCards = [12, 25, 38]; // returns 2, 0, 3 even wins

const createFixtureLoader = waffle.createFixtureLoader;

describe('Poker', () => {
  const [wallet, other] = waffle.provider.getWallets();

  let oracle: Oracle;
  let poker: Poker;
  let poolController: PoolController;

  let loadFixture: ReturnType<typeof createFixtureLoader>;

  before('create fixture loader', async () => {
    loadFixture = createFixtureLoader([wallet, other])
  })

  beforeEach('deploy fixture', async () => {
    ;({
      oracle,
      poker,
      poolController,
    } = await loadFixture(contractsFixture));
  })

  describe('check getters and setters', async () => {
    it('getGame should return storage value', async () => {
      expect(await poolController.getGame()).to.equal(poker.address);
    });

    it('canWithdraw should return storage value', async () => {
      expect(await poolController.canWithdraw(100000000000)).to.equal(100000000000);
    });

    it('getPoolAmount should return storage value', async () => {
      expect(await poolController.getPoolAmount()).to.equal(100000000000);
    });

    it('getOracleOperator should return storage value', async () => {
      await poolController.setOracleOperator(wallet.address);
      expect(await poolController.getOracleOperator()).to.equal(wallet.address);
    });

    it('setBonusPercentMilestones ', async () => {
      let contractBonusMilestones = dumbArrayToString(await poolController.getBonusPercentMilestones());
      expect(contractBonusMilestones).to.equal(dumbArrayToString(initBonusPercentMilestones));
      await poolController.setBonusPercentMilestones(changedBonusPercentMilestones);
      contractBonusMilestones = dumbArrayToString(await poolController.getBonusPercentMilestones());
      expect(contractBonusMilestones).to.equal(dumbArrayToString(changedBonusPercentMilestones));
    });

    it('getTotalWinningsMilestones ', async () => {
      let contractTotalWinningsMilestones = dumbArrayToString(await poolController.getTotalWinningsMilestones());
      expect(contractTotalWinningsMilestones).to.equal(dumbArrayToString(initTotalWinningsMilestones));
      await poolController.setTotalWinningsMilestones(changedTotalWinningsMilestones);
      contractTotalWinningsMilestones = dumbArrayToString(await poolController.getTotalWinningsMilestones());
      expect(contractTotalWinningsMilestones).to.equal(dumbArrayToString(changedTotalWinningsMilestones));
    });

    it('setJackpot, setJackpotLimit', async () => {
      await poolController.setJackpot(100);
      await poolController.setJackpotLimit(100);
    });

    it('setOracleGasFee', async () => {
      await poolController.setOracleGasFee(100);
    });
  });

  it('check referral program, poker wins only', async() => {
    let refsCounter = (await poolController.getReferralStats(other.address))[4];
    expect(refsCounter).to.equal(0);
    await poolController.addRef(other.address, wallet.address);
    refsCounter = (await poolController.getReferralStats(other.address))[4];
    expect(refsCounter).to.equal(1);
    for (let i = 0; i < 10; i++) {
      // @ts-ignore
      await poker.play(0, 0, { value: 100000000 });
      const requestId = await poker.getLastRequestId();
      const winPoker = await poker.getPokerResult(winCards);
      const winColor = await poker.getColorResult(requestId, evenWinColorCards);
      const gameResults = await poker.calculateWinAmount(requestId, winPoker, winColor);

      const bitCards = await oracle.toBit(winCards);
      await poker.setGameResult(requestId, (gameResults[0].add(gameResults[1])), gameResults[2], bitCards);
      await poker.claimWinAmount(requestId);
    }
    const refStats = await poolController.getReferralStats(other.address);
    expect(refStats[2]).to.equal(1983000000);
    expect(refStats[3]).to.equal(150000);
  })

  it('check referral program, color wins only', async() => {
    let refsCounter = (await poolController.getReferralStats(other.address))[4];
    expect(refsCounter).to.equal(0);
    await poolController.addRef(other.address, wallet.address);
    refsCounter = (await poolController.getReferralStats(other.address))[4];
    expect(refsCounter).to.equal(1);
    for (let i = 0; i < 10; i++) {
      // @ts-ignore
      await poker.play(100000000, 0, { value: 100000000 });
      const requestId = await poker.getLastRequestId();
      const winPoker = await poker.getPokerResult(winCards);
      const winColor = await poker.getColorResult(requestId, evenWinColorCards);
      const gameResults = await poker.calculateWinAmount(requestId, winPoker, winColor);

      const bitCards = await oracle.toBit(winCards);
      await poker.setGameResult(requestId, (gameResults[0].add(gameResults[1])), gameResults[2], bitCards);
      await poker.claimWinAmount(requestId);
    }
    let refStats = await poolController.getReferralStats(other.address);
    expect(refStats[2]).to.equal(1985000000);
    expect(refStats[3]).to.equal(150000);

    await poolController.withdrawReferralEarnings(other.address);
    refStats = await poolController.getReferralStats(other.address);
    expect(refStats[2]).to.equal(1985000000);
    expect(refStats[3]).to.equal(0);
  })

  it('check referral program reverts', async () => {
    await poolController.addRef(wallet.address, other.address);
    await expect(poolController.addRef(wallet.address, other.address)).to.be.reverted;
    await expect(poolController.addRef(wallet.address, wallet.address)).to.be.reverted;
  })

  it('takeOracleFee should work', async () => {
    await poolController.setOracleOperator(wallet.address);
    let poolInfo = await poolController.getPoolInfo();
    expect(poolInfo[3]).to.equal(0);
    for (let i = 0; i < 10; i++) {
      // @ts-ignore
      await poker.play(100000000, 0, { value: 100000000 });
    }
    poolInfo = await poolController.getPoolInfo();
    expect(poolInfo[3]).to.equal(120000000);
    await poolController.takeOracleFee();
    poolInfo = await poolController.getPoolInfo();
    expect(poolInfo[3]).to.equal(0);
  })

  it('withdraw should work', async () => {
    await poolController.withdraw(100000000000);
    const poolInfo = await poolController.getPoolInfo();
    expect(poolInfo[1]).to.equal(0);
  })

  it('withdraw should fail', async () => {
    await expect(poolController.withdraw(10000000000000)).to.be.reverted;
  })

  describe('check whitelist logic', async () => {
    it('addToWhitelist should work', async () => {
      expect(await poolController.whitelist(wallet.address)).to.equal(true);
      expect(await poolController.whitelist(other.address)).to.equal(false);
      await poolController.addToWhitelist(other.address);
      expect(await poolController.whitelist(other.address)).to.equal(true);
    })

    it('addToWhitelist should fail', async () => {
      await expect(poolController.addToWhitelist(wallet.address)).to.be.reverted;
    })

    it('removeFromWhitelist should work', async () => {
      await poolController.removeFromWhitelist(wallet.address);
      expect(await poolController.whitelist(wallet.address)).to.equal(false);
    })
  })

  describe('check misc reverts', async () => {
    it('check onlyGame modifier', async () => {
      await expect(poolController.addBetToPool(1000)).to.be.reverted;
    })

    it('check onlyOracleOperator modifier', async () => {
      // @ts-ignore
      await expect(poolController.takeOracleFee({ from: other.address })).to.be.reverted;
    })

    it('check deposit allowed only for whitelisted addresses', async () => {
      // @ts-ignore
      await expect(poolController.deposit({ from: other.address })).to.be.reverted;
    })
  })

  it('artificially lower jackpot limit and check logic if jackpot is higher than jackpot limit', async () => {
    await poolController.setJackpotLimit(1);
    await poker.play(0, 0, { value: 100000000000 });
    const requestId = await poker.getLastRequestId();

    const winPoker = await poker.getPokerResult(winJackpotCards);
    const winColor = await poker.getColorResult(requestId, evenWinColorCards);
    const gameResults = await poker.calculateWinAmount(requestId, winPoker, winColor);

    const bitCards = await oracle.toBit(winJackpotCards);

    await poker.setGameResult(requestId, (gameResults[0].add(gameResults[1])), gameResults[2], bitCards);
    await poker.claimWinAmount(requestId);
  })

})
