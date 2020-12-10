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

    describe('checking withdraw functions:', async () => {
      beforeEach(async () => {
        await this.xETH.setPoolController(this.poolController.address, { from: owner });
        await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
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

    describe('checking whitelist functions:', async () => {
      it('checking addToWhitelist function', async () => {
        simpleExpectRevert(this.poolController.deposit(alice, { from: alice, callValue: 1000 }), 'Deposit not allowed');
        await this.poolController.addToWhitelist(alice, { from: owner });
        simpleExpectRevert(this.poolController.addToWhitelist(alice, { from: owner }), 'Already added');
        await this.poolController.deposit(alice, { from: alice, callValue: 1000 });
      });

      it('checking removeFromWhitelist function', async () => {
        await this.poolController.deposit(alice, { from: alice, callValue: 1000 });
        await this.poolController.removeFromWhitelist(alice, { from: owner });
        simpleExpectRevert(this.poolController.deposit(alice, { from: alice, callValue: 1000 }), 'Deposit not allowed');
      });
    });
  });
});
