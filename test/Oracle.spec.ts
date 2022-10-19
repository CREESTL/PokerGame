import { ethers, waffle } from "hardhat";
import { Oracle } from "../typechain/Oracle";
import { Poker } from "../typechain/Poker";
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

  let oracle: Oracle;
  let poker: Poker;

  let loadFixture: ReturnType<typeof createFixtureLoader>;

  before("create fixture loader", async () => {
    loadFixture = createFixtureLoader([wallet, other]);
  });

  beforeEach("deploy fixture", async () => {
    ({ poker, oracle } = await loadFixture(contractsFixture));
  });

  describe("check getters", async () => {
    it("getOperatorAddress and setOperatorAddress should change/return storage value", async () => {
      expect(await oracle.getOperatorAddress()).to.equal(wallet.address);
      await oracle.setOperatorAddress(other.address);
      await expect(oracle.setOperatorAddress(constants.AddressZero)).to.be
        .reverted;
      expect(await oracle.getOperatorAddress()).to.equal(other.address);
    });

    it("getPendingRequests should return storage value", async () => {
      await poker.play(0, 0, { value: 1000000000000 });
      const requestId = await poker.getLastRequestId();
      expect(await oracle.getPendingRequests(requestId)).to.equal(true);
    });

    it("getGame should return storage value", async () => {
      expect(await oracle.getGame()).to.equal(poker.address);
    });

    it("createRandomNumberRequest should fail", async () => {
      await expect(oracle.createRandomNumberRequest()).to.be.reverted;
    });
  });
});
