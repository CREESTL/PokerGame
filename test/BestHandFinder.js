const {
  BN,
  expectRevert,
} = require('openzeppelin-test-helpers');
const { expect } = require('chai');
const { getBNEth } = require('../utils/getBN');
const { getCardRank } = require('../utils/pokerHelpers');

require('chai')
  .use(require('chai-as-promised'))
  .should();

const BestHandFinder = artifacts.require('BestHandFinder');
const FakeGameController = artifacts.require('FakeGameController');
const Oracle = artifacts.require('Oracle');

const randomCards = [1, 14, 27, 40, 3, 16, 29, 42, 22];

contract('BestHandFinder test', async ([owner, alice, bob]) => {

  beforeEach(async () => {
    this.bestHandFinder = await BestHandFinder.deployed();
    this.fakeGameController = await FakeGameController.deployed();
    this.oracle = await Oracle.deployed();
  });

  it('checking the BESTHAND ', async () => {
    console.log(await this.oracle.publishRandomNumber(randomCards, this.oracle.address, 0, { from: owner }));
  });
});
