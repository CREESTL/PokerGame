import { ethers, waffle } from "hardhat";
import { PoolController } from "../typechain/PoolController";
import { XTRXToken } from "../typechain/XTRXToken";
import { expect } from "./shared/expect";
import { contractsFixture } from "./shared/fixtures";

const { constants } = ethers;

const TEST_ADDRESSES: [string, string] = [
  "0x1000000000000000000000000000000000000000",
  "0x2000000000000000000000000000000000000000",
];

const createFixtureLoader = waffle.createFixtureLoader;

describe("Poker", () => {
  const [wallet, other] = waffle.provider.getWallets();

  let xTRX: XTRXToken;
  let poolController: PoolController;

  let loadFixture: ReturnType<typeof createFixtureLoader>;

  before("create fixture loader", async () => {
    loadFixture = createFixtureLoader([wallet, other]);
  });

  beforeEach("deploy fixture", async () => {
    ({ xTRX, poolController } = await loadFixture(contractsFixture));
  });

  describe("check getters", () => {
    it("check getPolController", async () => {
      expect(await xTRX.getPoolController()).to.equal(poolController.address);
    });
  });
});
