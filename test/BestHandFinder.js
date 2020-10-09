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

const sortedHand = [1, 3, 2 , 26, 6, 4, 8];

// const generateRandom = (на) => {
//     return Math.floor(
//         Math.random() * (0 - 51 + 1) + 0;
//     )
// }

contract('BestHandFinder test', async ([owner, alice, bob]) => {

  beforeEach(async () => {
    this.bestHandFinder = await BestHandFinder.deployed();
  });

  it('checking the BESTHAND ', async () => {
   await this.bestHandFinder.set(sortedHand);
   console.log(await this.bestHandFinder.get());
   await this.bestHandFinder.sort();
   console.log(await this.bestHandFinder.get());

  });
});
