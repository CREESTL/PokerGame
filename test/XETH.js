const {
  BN,
  expectRevert,
} = require('openzeppelin-test-helpers');
const { expect } = require('chai');
const { getBNEth } = require('./utils/getBN');
const { getHexAddress, simpleExpectRevert, tronweb } = require('./utils/tronBSHelpers');

require('chai')
  .use(require('chai-as-promised'))
  .should();


const XETHToken = artifacts.require('XETHToken');
const PoolController = artifacts.require('PoolController');

contract('xETH test', async ([owner, alice, bob]) => {
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  beforeEach(async () => {
    this.xETH = await XETHToken.deployed();
    this.poolController = await PoolController.deployed();
  });

  it('checking the xETH token parameters', async () => {
    const ethToken = await tronweb.contract().new(XETHToken);
    assert.equal(await ethToken.name().call(), 'xEthereum');
    assert.equal(await ethToken.symbol().call(), 'xETH');
    assert.equal(await ethToken.decimals().call(), 18);
    assert.equal(await ethToken.totalSupply().call(), 0);
  });

  it('checking isBurnAllowed function', async () => {
    assert.equal(await this.xETH.isBurnAllowed(owner), true);
    assert.equal(await this.xETH.isBurnAllowed(alice), false);
  });

  it('checking addBurner function', async () => {
    simpleExpectRevert(this.xETH.addBurner(alice, { from: alice }));
    simpleExpectRevert(this.xETH.addBurner(ZERO_ADDRESS, { from: owner }));
    expect(await this.xETH.isBurnAllowed(alice), { from: owner }).to.equal(false);
    await this.xETH.addBurner(alice, { from: owner });
    expect(await this.xETH.isBurnAllowed(alice, { from: owner })).to.equal(true);
    simpleExpectRevert(this.xETH.addBurner(alice, { from: owner }));
  });

  it('checking removeBurner function', async () => {
    simpleExpectRevert(this.xETH.removeBurner(alice, { from: owner }));
    await this.xETH.addBurner(alice, { from: owner });
    assert.equal(await this.xETH.isBurnAllowed(alice, { from: owner }), true);
    await this.xETH.removeBurner(alice, { from: owner });
    assert.equal(await this.xETH.isBurnAllowed(alice, { from: owner }), false);
  });

  it('checking setPoolController function', async () => {
    simpleExpectRevert(this.xETH.setPoolController(this.xETH.address, { from: owner }));
    await this.xETH.setPoolController(this.poolController.address, { from: owner });
    assert.equal(await this.xETH.getPoolController({ from: owner }),(this.poolController.address));
  });

  it('checking mint function', async () => {
    simpleExpectRevert(this.xETH.mint(getHexAddress(owner), 1000, { from: owner }));
    await this.xETH.setPoolController(this.poolController.address, { from: owner });
    assert.equal(await this.xETH.balanceOf(owner), 0);
    await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
    assert.equal(await this.xETH.balanceOf(owner), 1000);
  });

  it('checking burn function', async () => {
    simpleExpectRevert(this.xETH.mint(getHexAddress(owner), 1000, { from: owner }));
    await this.xETH.setPoolController(this.poolController.address, { from: owner });
    assert.equal(await this.xETH.balanceOf(owner), 1000);
    await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
    assert.equal(await this.xETH.balanceOf(owner), 2000);
    await this.xETH.burn(1000, { from: owner });
    assert.equal(await this.xETH.balanceOf(owner), 1000);
    await this.xETH.burn(1000, { from: owner });
    assert.equal(await this.xETH.balanceOf(owner), 0);
  });

  it('checking burnerFrom function', async () => {
    console.log(await this.xETH.balanceOf(alice), 4)
    await this.poolController.deposit(alice, { from: alice, callValue: 1000 });
    console.log(await this.xETH.balanceOf(alice), 5)
    await this.xETH.approve(owner, 500, { from: alice });
    await this.xETH.burnFrom(alice, 500, { from: owner });
    assert.equal(await this.xETH.balanceOf(alice), 500);
  });
});
