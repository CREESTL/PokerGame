// const {
//   BN,
//   expectRevert,
// } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');
// const { getBNEth } = require('./utils/getBN');
// const { getHexAddress, simpleExpectRevert, tronweb } = require('./utils/tronBSHelpers');

// require('chai')
//   .use(require('chai-as-promised'))
//   .should();


// const XTRXToken = artifacts.require('XTRXToken');
// const PoolController = artifacts.require('PoolController');

// contract('xTRX test', async ([owner, alice, bob]) => {
//   const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

//   beforeEach(async () => {
//     this.xTRX = await XTRXToken.deployed();
//     this.poolController = await PoolController.deployed();
//   });

//   it('checking the xTRX token parameters', async () => {
//     const ethToken = await tronweb.contract().new(XTRXToken);
//     assert.equal(await ethToken.name().call(), 'xEthereum');
//     assert.equal(await ethToken.symbol().call(), 'xTRX');
//     assert.equal(await ethToken.decimals().call(), 18);
//     assert.equal(await ethToken.totalSupply().call(), 0);
//   });

//   it('checking isBurnAllowed function', async () => {
//     assert.equal(await this.xTRX.isBurnAllowed(owner), true);
//     assert.equal(await this.xTRX.isBurnAllowed(alice), false);
//   });

//   it('checking addBurner function', async () => {
//     simpleExpectRevert(this.xTRX.addBurner(alice, { from: alice }));
//     simpleExpectRevert(this.xTRX.addBurner(ZERO_ADDRESS, { from: owner }));
//     expect(await this.xTRX.isBurnAllowed(alice), { from: owner }).to.equal(false);
//     await this.xTRX.addBurner(alice, { from: owner });
//     expect(await this.xTRX.isBurnAllowed(alice, { from: owner })).to.equal(true);
//     simpleExpectRevert(this.xTRX.addBurner(alice, { from: owner }));
//   });

//   it('checking removeBurner function', async () => {
//     simpleExpectRevert(this.xTRX.removeBurner(alice, { from: owner }));
//     await this.xTRX.addBurner(alice, { from: owner });
//     assert.equal(await this.xTRX.isBurnAllowed(alice, { from: owner }), true);
//     await this.xTRX.removeBurner(alice, { from: owner });
//     assert.equal(await this.xTRX.isBurnAllowed(alice, { from: owner }), false);
//   });

//   it('checking setPoolController function', async () => {
//     simpleExpectRevert(this.xTRX.setPoolController(this.xTRX.address, { from: owner }));
//     await this.xTRX.setPoolController(this.poolController.address, { from: owner });
//     assert.equal(await this.xTRX.getPoolController({ from: owner }),(this.poolController.address));
//   });

//   it('checking mint function', async () => {
//     simpleExpectRevert(this.xTRX.mint(getHexAddress(owner), 1000, { from: owner }));
//     await this.xTRX.setPoolController(this.poolController.address, { from: owner });
//     assert.equal(await this.xTRX.balanceOf(owner), 0);
//     await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
//     assert.equal(await this.xTRX.balanceOf(owner), 1000);
//   });

//   it('checking burn function', async () => {
//     simpleExpectRevert(this.xTRX.mint(getHexAddress(owner), 1000, { from: owner }));
//     await this.xTRX.setPoolController(this.poolController.address, { from: owner });
//     assert.equal(await this.xTRX.balanceOf(owner), 1000);
//     await this.poolController.deposit(owner, { from: owner, callValue: 1000 });
//     assert.equal(await this.xTRX.balanceOf(owner), 2000);
//     await this.xTRX.burn(1000, { from: owner });
//     assert.equal(await this.xTRX.balanceOf(owner), 1000);
//     await this.xTRX.burn(1000, { from: owner });
//     assert.equal(await this.xTRX.balanceOf(owner), 0);
//   });

//   it('checking burnerFrom function', async () => {
//     console.log(await this.xTRX.balanceOf(alice), 4)
//     await this.poolController.deposit(alice, { from: alice, callValue: 1000 });
//     console.log(await this.xTRX.balanceOf(alice), 5)
//     await this.xTRX.approve(owner, 500, { from: alice });
//     await this.xTRX.burnFrom(alice, 500, { from: owner });
//     assert.equal(await this.xTRX.balanceOf(alice), 500);
//   });
// });
