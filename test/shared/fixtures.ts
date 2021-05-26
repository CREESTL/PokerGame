import { ethers, waffle } from 'hardhat';
import { PoolController } from '../../typechain/PoolController';
import { XTRXToken } from '../../typechain/XTRXToken';
import { Poker } from '../../typechain/Poker';
import { Oracle } from '../../typechain/Oracle';
import { MockPoker } from '../../typechain/MockPoker';
import { Fixture } from 'ethereum-waffle';

type PokerFixture = {
  xTRX: XTRXToken,
  poolController: PoolController,
  oracle: Oracle,
  poker: Poker,
  mockPoker: MockPoker,
}

const [owner] = waffle.provider.getWallets();

async function pokerFixture(): Promise<PokerFixture> {
  const tokenFactory = await ethers.getContractFactory('XTRXToken');
  const xTRX = await tokenFactory.deploy() as XTRXToken;

  const poolControllerFactory = await ethers.getContractFactory('PoolController');
  const poolController = await poolControllerFactory.deploy(xTRX.address) as PoolController;

  const oracleFactory = await ethers.getContractFactory('Oracle');
  const oracle = await oracleFactory.deploy(owner.address) as Oracle;

  const pokerFactory = await ethers.getContractFactory('Poker');
  const poker = (await pokerFactory.deploy(oracle.address, poolController.address, owner.address)) as Poker;

  const mockPokerFactory = await ethers.getContractFactory('MockPoker');
  const mockPoker = (await mockPokerFactory.deploy(oracle.address, poolController.address)) as MockPoker;

  return { xTRX, poolController, oracle, poker, mockPoker };
}

export const contractsFixture: Fixture<PokerFixture> = async function (): Promise<PokerFixture> {
  const { xTRX, poolController, oracle, poker, mockPoker } = await pokerFixture();

  await xTRX.setPoolController(poolController.address);

  await poolController.setGame(poker.address);
  await oracle.setGame(poker.address);

  await poker.setMaxBet('10000000000000');

  return {
    xTRX,
    poolController,
    oracle,
    poker,
    mockPoker,
  }
}