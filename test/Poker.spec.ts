import { ethers, waffle } from "hardhat";
import { PoolController } from "../typechain/PoolController";
import { XTRXToken } from "../typechain/XTRXToken";
import { Poker } from "../typechain/Poker";
import { Oracle } from "../typechain/Oracle";
import { expect } from "./shared/expect";
import { contractsFixture } from "./shared/fixtures";

const { constants } = ethers;

const TEST_ADDRESSES: [string, string] = [
  "0x1000000000000000000000000000000000000000",
  "0x2000000000000000000000000000000000000000",
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
const checkingToBitInt = "14274713982914945";

const initHouseEdge = 15;
const changedHouseEdge = 20;

const initJackpotMultiplier = 2;
const changedJackpotMultiplier = 5;

describe("Poker", () => {
  const [wallet, other] = waffle.provider.getWallets();

  let xTRX: XTRXToken;
  let poolController: PoolController;
  let oracle: Oracle;
  let poker: Poker;

  let loadFixture: ReturnType<typeof createFixtureLoader>;

  before("create fixture loader", async () => {
    loadFixture = createFixtureLoader([wallet, other]);
  });

  beforeEach("deploy fixture", async () => {
    ({ xTRX, poolController, oracle, poker } = await loadFixture(
      contractsFixture
    ));
  });

  it("cardsToBits func should convert array of cards to correct binary num", async () => {
    expect(await oracle.cardsToBits(checkingToBitArr)).to.equal(checkingToBitInt);
  });

  // setter and getters

  describe("check setters and getters", async () => {
    it("setHouseEdge should change storage value", async () => {
      expect(await poker.houseEdge()).to.equal(initHouseEdge);
      await poker.setHouseEdge(changedHouseEdge);
      expect(await poker.houseEdge()).to.equal(changedHouseEdge);
    });

    it("setJackpotMultiplier should change storage value", async () => {
      expect(await poker.jackpotFeeMultiplier()).to.equal(
        initJackpotMultiplier
      );
      await poker.setJackpotFeeMultiplier(changedJackpotMultiplier);
      expect(await poker.jackpotFeeMultiplier()).to.equal(
        changedJackpotMultiplier
      );
    });

    it("setOracle should work", async () => {
      await poker.setOracle(oracle.address);
      expect(await poker.getOracle()).to.equal(oracle.address);
    });

    it("getLastRequestId should work", async () => {
      await poker.getLastRequestId();
    });

    it("getLastRequestId should not work", async () => {
      await expect(poker.getLastRequestId({ from: other.address })).to.be
        .reverted;
    });

    it("setPoolController should work", async () => {
      await poker.setPoolController(poolController.address);
      expect(await poker.getPoolController()).to.equal(poolController.address);
    });

    it("setOperator should work", async () => {
      await poker.setOperator(other.address);
      expect(await poker._operator()).to.equal(other.address);
    });
  });

  describe("check poker results", async () => {
    it("poker result should be lose", async () => {
      expect(await poker.getPokerResult(computerWinsCards)).to.equal(0);
    });

    it("poker result should be draw", async () => {
      expect(await poker.getPokerResult(drawCards)).to.equal(1);
    });

    it("poker result should be win", async () => {
      expect(await poker.getPokerResult(winCards)).to.equal(2);
    });

    it("poker result should be win jackpot", async () => {
      expect(await poker.getPokerResult(winJackpotCards)).to.equal(3);
    });
  });

  describe("check unchecked requires", async () => {
    it("setMaxBet should fail", async () => {
      // @ts-ignore
      await expect(poker.setMaxBet(100, { from: other.address })).to.be
        .reverted;
    });

    it("setGameResult should fail", async () => {
      await poker.play(10000000, 0, { value: 100000000 });
      const gameId = await poker.getLastRequestId();
      // @ts-ignore
      await expect(poker.setGameResult(gameId, 100, { from: other.address }))
        .to.be.reverted;
    });

    it("sendFundsToPool should fail", async () => {
      // @ts-ignore
      await expect(poker.sendFundsToPool({ from: other.address })).to.be
        .reverted;
    });

    it("claimWinAmount should fail", async () => {
      await poker.play(10000000, 0, { value: 100000000 });
      const gameId = await poker.getLastRequestId();
      // @ts-ignore
      await expect(poker.claimWinAmount(gameId, { from: other.address })).to
        .be.reverted;
    });
  });

  describe("misc functions", async () => {
    describe("check sendFundsToPool", async () => {
      it("sendFundsToPool to pool should work", async () => {
        await poker.play(0, 0, { value: 100000000 });
        await poker.sendFundsToPool();
      });

      it("sendFundsToPool should fail", async () => {
        // @ts-ignore
        await expect(poker.sendFundsToPool({ from: other.address })).to.be
          .reverted;
      });
    });

    describe("check claimWinAmount", async () => {
      it("claimWinAmount should work", async () => {
        await poker.play(0, 0, { value: 100000000 });
        const gameId = await poker.getLastRequestId();
        await poker.claimWinAmount(gameId);
      });

      it("claimWinAmount should fail", async () => {
        await poker.play(0, 0, { value: 100000000 });
        const gameId = await poker.getLastRequestId();
        // @ts-ignore
        await expect(poker.claimWinAmount(gameId, { from: other.address }))
          .to.be.reverted;
      });
    });
  });

  describe("game workflow", async () => {
    it("checking play workflow, user wins poker and color", async () => {
      expect(await xTRX.balanceOf(wallet.address)).to.equal(100000000000);
      let poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100000000000);
      // @ts-ignore
      await poker.play(0, 0, { from: wallet.address, value: 100000000 });
      poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100097000000);
      const gameId = await poker.getLastRequestId();
      const result = await poker.getPokerResult(winCards);
      const winColor = await poker.getColorResult(gameId, evenWinColorCards);

      const gameResults = await poker.calculateWinAmount(
        gameId,
        result,
        winColor
      );
      expect(gameResults[0]).to.equal(198300000);
      expect(gameResults[1]).to.equal(0);
      expect(gameResults[2]).to.equal(1500000);

      const cardsBits = await oracle.cardsToBits(winCards);

      await poker.setGameResult(
        gameId,
        gameResults[0].add(gameResults[1]),
        gameResults[2],
        cardsBits
      );
      await poker.claimWinAmount(gameId);
      // check that winAmount is correct
      let gameInfo = await poker.games(gameId);
      expect(gameInfo[2]).to.equal(gameResults[0].add(gameResults[1]));
      // check that cards are correct
      const gameMetaData = await poker.getRequest(gameId);
      expect(gameMetaData[0]).to.equal(cardsBits);
      // check that user data updated and he cant claim reward again
      gameInfo = await poker.games(gameId);
      // @ts-ignore
      expect(gameInfo[6]).to.equal(true);
      await expect(poker.claimWinAmount(gameId)).to.be.reverted;
    });

    it("checking play workflow, user loses poker and wins color", async () => {
      expect(await xTRX.balanceOf(wallet.address)).to.equal(100000000000);
      let poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100000000000);
      // @ts-ignore
      await poker.play(10000000, 0, { from: wallet.address, value: 100000000 });
      poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100097000000);
      const gameId = await poker.getLastRequestId();
      const result = await poker.getPokerResult(computerWinsCards);
      const winColor = await poker.getColorResult(gameId, evenWinColorCards);

      const gameResults = await poker.calculateWinAmount(
        gameId,
        result,
        winColor
      );
      expect(gameResults[0]).to.equal(0);
      expect(gameResults[1]).to.equal(19850000);
      expect(gameResults[2]).to.equal(150000);

      const cardsBits = await oracle.cardsToBits(computerWinsCards);

      await poker.setGameResult(
        gameId,
        gameResults[0].add(gameResults[1]),
        gameResults[2],
        cardsBits
      );
      await poker.claimWinAmount(gameId);

      // check that winAmount is correct
      let gameInfo = await poker.games(gameId);
      expect(gameInfo[2]).to.equal(gameResults[0].add(gameResults[1]));
      // check that cards are correct
      const gameMetaData = await poker.getRequest(gameId);
      expect(gameMetaData[0]).to.equal(cardsBits);
      // check that user data updated and he cant claim reward again
      gameInfo = await poker.games(gameId);
      // @ts-ignore
      expect(gameInfo[6]).to.equal(true);
      await expect(poker.claimWinAmount(gameId)).to.be.reverted;
    });

    it("checking play workflow, user loses poker and loses color", async () => {
      expect(await xTRX.balanceOf(wallet.address)).to.equal(100000000000);
      let poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100000000000);
      // @ts-ignore
      await poker.play(10000000, 0, { from: wallet.address, value: 100000000 });
      poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100097000000);
      const gameId = await poker.getLastRequestId();
      const result = await poker.getPokerResult(computerWinsCards);
      const winColor = await poker.getColorResult(gameId, oddWinColorCards);

      const gameResults = await poker.calculateWinAmount(
        gameId,
        result,
        winColor
      );
      expect(gameResults[0]).to.equal(0);
      expect(gameResults[1]).to.equal(0);
      expect(gameResults[2]).to.equal(0);

      const cardsBits = await oracle.cardsToBits(computerWinsCards);

      await poker.setGameResult(
        gameId,
        gameResults[0].add(gameResults[1]),
        gameResults[2],
        cardsBits
      );
      await poker.claimWinAmount(gameId);

      // check that winAmount is correct
      let gameInfo = await poker.games(gameId);
      expect(gameInfo[2]).to.equal(gameResults[0].add(gameResults[1]));
      // check that cards are correct
      const gameMetaData = await poker.getRequest(gameId);
      expect(gameMetaData[0]).to.equal(cardsBits);
      // check that user data updated and he cant claim reward again
      gameInfo = await poker.games(gameId);
      // @ts-ignore
      expect(gameInfo[6]).to.equal(true);
      await expect(poker.claimWinAmount(gameId)).to.be.reverted;
    });

    it("checking play workflow, draw poker and loses color", async () => {
      expect(await xTRX.balanceOf(wallet.address)).to.equal(100000000000);
      let poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100000000000);
      // @ts-ignore
      await poker.play(10000000, 0, { from: wallet.address, value: 100000000 });
      poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100097000000);
      const gameId = await poker.getLastRequestId();
      const result = await poker.getPokerResult(drawCards);
      const winColor = await poker.getColorResult(gameId, oddWinColorCards);

      const gameResults = await poker.calculateWinAmount(
        gameId,
        result,
        winColor
      );
      expect(gameResults[0]).to.equal(88470000);
      expect(gameResults[1]).to.equal(0);
      expect(gameResults[2]).to.equal(0);

      const cardsBits = await oracle.cardsToBits(drawCards);

      await poker.setGameResult(
        gameId,
        gameResults[0].add(gameResults[1]),
        gameResults[2],
        cardsBits
      );
      await poker.claimWinAmount(gameId);

      // check that winAmount is correct
      let gameInfo = await poker.games(gameId);
      expect(gameInfo[2]).to.equal(gameResults[0].add(gameResults[1]));
      // check that cards are correct
      const gameMetaData = await poker.getRequest(gameId);
      expect(gameMetaData[0]).to.equal(cardsBits);
      // check that user data updated and he cant claim reward again
      gameInfo = await poker.games(gameId);
      // @ts-ignore
      expect(gameInfo[6]).to.equal(true);
      await expect(poker.claimWinAmount(gameId)).to.be.reverted;
    });

    it("checking play workflow, user wins jackpot and loses color", async () => {
      expect(await xTRX.balanceOf(wallet.address)).to.equal(100000000000);
      let poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100000000000);
      // @ts-ignore
      await poker.play(10000000, 0, { from: wallet.address, value: 100000000 });
      poolInfo = await poolController.getPoolInfo();
      expect(poolInfo[1]).to.equal(100097000000);
      const gameId = await poker.getLastRequestId();
      const result = await poker.getPokerResult(winJackpotCards);
      const winColor = await poker.getColorResult(gameId, oddWinColorCards);

      const gameResults = await poker.calculateWinAmount(
        gameId,
        result,
        winColor
      );
      // 180000 came from him playing thus updating jackpot pool
      expect(gameResults[0]).to.equal(500000180000);
      expect(gameResults[1]).to.equal(0);
      expect(gameResults[2]).to.equal(0);

      const cardsBits = await oracle.cardsToBits(winJackpotCards);

      await poker.setGameResult(
        gameId,
        gameResults[0].add(gameResults[1]),
        gameResults[2],
        cardsBits
      );
      await poker.claimWinAmount(gameId);

      const gameInfo = await poker.games(gameId);
      expect(gameInfo[2]).to.equal(gameResults[0].add(gameResults[1]));

      const gameMetaData = await poker.getRequest(gameId);
      expect(gameMetaData[0]).to.equal(cardsBits);
    });

    it("check jackpot increasing", async () => {
      // this is mock init jackpot value testing
      expect(await poolController.jackpot()).to.equal(500000000000);
      // every bet adds 200 000 to jackpot, so +20 000 000 after 100 games
      for (let i = 0; i < 100; i++) {
        await poker.play(0, 0, { value: 100000000 });
      }
      expect(await poolController.jackpot()).to.equal(500020000000);
    });
  });
});
