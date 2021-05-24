import { BigNumber } from 'ethers'
import { ethers, waffle } from 'hardhat';
import { PoolController } from '../typechain/PoolController';
import { XTRXToken } from '../typechain/XTRXToken';
import { Poker } from '../typechain/Poker';
import { Oracle } from '../typechain/Oracle';
import { expect } from './shared/expect';
import snapshotGasCost from './shared/snapshotGasCost';
import { contractsFixture } from './shared/fixtures';

const { constants } = ethers;

const TEST_ADDRESSES: [string, string] = [
  '0x1000000000000000000000000000000000000000',
  '0x2000000000000000000000000000000000000000',
];

const createFixtureLoader = waffle.createFixtureLoader;

type ThenArg<T> = T extends PromiseLike<infer U> ? U : T;

const checkingToBitArr = [1, 6, 13, 14, 24, 27, 44, 45, 50];
const checkingToBitInt = '14274713982914945';

describe('Poker', () => {
  const [wallet, other] = waffle.provider.getWallets();


  let xTRX: XTRXToken;
  let poolController: PoolController;
  let oracle: Oracle;
  let poker: Poker;

  let loadFixture: ReturnType<typeof createFixtureLoader>;

  before('create fixture loader', async () => {
    loadFixture = createFixtureLoader([wallet, other])
  })

  beforeEach('deploy fixture', async () => {
    ;({ xTRX, poolController, oracle, poker } = await loadFixture(contractsFixture));
  })

  it('toBit func should convert array of cards to correct binary num', async () => {
    expect(await oracle.toBit(checkingToBitArr)).to.equal(checkingToBitInt);
  })
})
