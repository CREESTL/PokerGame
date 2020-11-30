/* eslint-disable max-len */

const {
  BN,
  expectRevert,
  balance,
} = require('openzeppelin-test-helpers');
const { expect } = require('chai');
require('chai')
  .use(require('chai-as-promised'))
  .should();
const { getBNEth } = require('./utils/getBN');
const { getHexAddress, simpleExpectRevert } = require('./utils/tronBSHelpers');



const XETHToken = artifacts.require('XETHToken');
// const RussianRoulette = artifacts.require('RussianRoulette');
const Oracle = artifacts.require('Oracle');
const PoolController = artifacts.require('PoolController');

contract('PoolController', async ([owner, alice, bob]) => {
  const ZERO_ADDRESS = '410000000000000000000000000000000000000000';
  const ETH_ADDRESS = '410000000000000000000000000000000000000001';

  beforeEach(async () => {
    this.xETH = await XETHToken.deployed();
    this.poolController = await PoolController.deployed();
    this.oracle = await Oracle.deployed();
  });

  // it('checking poolController constructor', async () => {
  //   await expectRevert(PoolController.new(ZERO_ADDRESS, this.xWGR.address, this.xETH.address, { from: owner }), 'invalid iWgr address');
  //   await expectRevert.unspecified(PoolController.new(this.iWGR.address, ZERO_ADDRESS, this.xETH.address, { from: owner }), '');
  //   await expectRevert.unspecified(PoolController.new(this.iWGR.address, this.xWGR.address, ZERO_ADDRESS, { from: owner }), '');
  // });

  describe('checking poolController functions:', async () => {
    it('checking supportsIPool function', async () => {
      assert.isTrue(await this.poolController.supportsIPool());
    });

    it('checking getPoolInfo function', async () => {
      const ethPoolInfo = await this.poolController.getPoolInfo();
      expect(ethPoolInfo[0]).to.equal(this.xETH.address);
      assert.equal(ethPoolInfo[1], 0);
      assert.equal(ethPoolInfo[2].toString(), 120000);
      assert.equal(ethPoolInfo[3], 0);
      assert.equal(ethPoolInfo[4], true);
    });

    it('checking setOracleOperator function', async () => {
      assert.equal(await this.poolController.getOracleOperator(), ZERO_ADDRESS);
      await this.poolController.setOracleOperator(alice, { from: owner });
      assert.equal(await this.poolController.getOracleOperator(), getHexAddress(alice));
      simpleExpectRevert(this.poolController.setOracleOperator(owner, { from: alice }), 'not owner');
      assert.equal(await this.poolController.getOracleOperator(), getHexAddress(alice));
    });


    it('checking depositToken function', async () => {
      assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 0);
      await this.xETH.setPoolController(this.poolController.address, { from: owner });
      await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
      assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 1000);
    });


    // it('checking setGame function', async () => {
    //   this.russianRoulette = await RussianRoulette.new(this.oracle.address, this.poolController.address);
    //   await this.poolController.setGame(this.russianRoulette.address, { from: owner });
    //   expect(await this.poolController.getGamesCount()).to.be.bignumber.equal(new BN(1));
    //   await expectRevert.unspecified(this.poolController.addGame(this.xETH.address, { from: owner }), '');
    // });

    // it('checking getGame function', async () => {
    //   await expectRevert(this.poolController.getGame(new BN('0')), 'index out of range');
    //   this.russianRoulette = await RussianRoulette.new(this.oracle.address, this.poolController.address);
    //   await this.poolController.addGame(this.russianRoulette.address, { from: owner });
    //   const game = await this.poolController.getGame(new BN('0'));
    //   expect(await this.russianRoulette.address).to.equal(game);
    // });

    // it('should can not call addBetToPool & rewardDisribution functions directly (only game contract)', async () => {
    //   await expectRevert(this.poolController.addBetToPool(ETH_ADDRESS, getBNEth('1')), 'caller is not allowed to do some');
    //   await expectRevert(this.poolController.rewardDisribution(holder, ETH_ADDRESS, getBNEth('1')), 'caller is not allowed to do some');
    // });

    // it('checking maxBet function', async () => {
    //   expect(await this.poolController.maxBet(ETH_ADDRESS, new BN('1000000000000000001'))).to.be.bignumber.equal(new BN('0')); // > 100%, 10**18 + 1
    //   expect(await this.poolController.maxBet(ETH_ADDRESS, new BN('500000000000000000'))).to.be.bignumber.equal(new BN('0')); // 50%, pool is empty
    //   await this.xETH.setPoolController(this.poolController.address, { from: owner });
    //   await this.poolController.depositToken(ETH_ADDRESS, getBNEth('1'), { from: holder, value: getBNEth('1') });
    //   expect(await this.poolController.maxBet(ETH_ADDRESS, new BN('500000000000000000'))).to.be.bignumber.equal(getBNEth('0.5')); // 50%
    //   await this.poolController.deactivateToken(ETH_ADDRESS, { from: owner });
    //   expect(await this.poolController.maxBet(ETH_ADDRESS, new BN('500000000000000000'))).to.be.bignumber.equal(new BN('0')); // pool is deactivate
    // });

    // it('checking canWithdraw function', async () => {
    //   await expectRevert(this.poolController.canWithdraw(this.xWGR.address, getBNEth('1')), 'pool isn\'t active');
    //   await expectRevert(this.poolController.canWithdraw(owner, getBNEth('1')), 'pool isn\'t active');
    //   expect(await this.poolController.canWithdraw(this.iWGR.address, getBNEth('1'))).to.be.bignumber.equal(getBNEth('1'));
    //   expect(await this.poolController.canWithdraw(ETH_ADDRESS, getBNEth('1'))).to.be.bignumber.equal(getBNEth('1'));
    // });

    describe('checking withdraw functions:', async () => {
      beforeEach(async () => {
        await this.xETH.setPoolController(this.poolController.address, { from: owner });
        await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
        console.log((await this.xETH.balanceOf(owner)).toString(), 9999)
        assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 2000);
      });

      it('checking withdraw function', async () => {

        assert.equal(await this.xETH.balanceOf(owner), 2000);
        await this.poolController.withdraw(1000, { from: owner });
        assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 1000);
      });

      it('failing withdraw function', async () => {
        assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 2000);
        simpleExpectRevert(this.poolController.withdraw(3000, { from: owner }), 'not enough funds');
        await this.poolController.withdraw(1000, { from: owner });
        simpleExpectRevert(this.poolController.withdraw(1001, { from: owner }), 'not enough funds');
        assert.equal(await this.xETH.balanceOf(owner, { from: owner }), 1000);
      });
    });
  });
});
