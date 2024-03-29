// const {
//   BN,
//   expectRevert,
//   expectEvent,
// } = require('openzeppelin-test-helpers');
// const { expect } = require('chai');
// const { getHexAddress, simpleExpectRevert } = require('./utils/tronBSHelpers');

// const XTRXToken = artifacts.require('XTRXToken');
// const Oracle = artifacts.require('Oracle');
// // const PoolController = artifacts.require('PoolController');
// const FakeGameController = artifacts.require('FakeGameController');

// contract('Oracle', async ([owner, alice, bob]) => {
//   const ZERO_ADDRESS = '410000000000000000000000000000000000000000';
//   const RANDOM_NUMBER_MODULE = new BN('1000');

//   beforeEach(async () => {
//     this.xTRX = await XTRXToken.deployed();
//     this.oracle = await Oracle.deployed();
//     this.fakeGameController = await FakeGameController.deployed();
//     // this.poolController = await PoolController.new(
//     //   this.xTRX.address,
//     //   { from: owner },
//     // );
//   });

//   // it('should not deploy oracle contract if params is wrong', async () => {
//   //   await expectRevert(Oracle.new( new BN('999'), operator, { from: owner }), 'modulus is small');
//   //   await expectRevert(Oracle.new( RANDOM_NUMBER_MODULE, ZERO_ADDRESS, { from: owner }), 'invalid operator address');
//   // });

//   it('should show right oracle contract parameters', async () => {
//     assert.isTrue(await this.oracle.supportsIOracle())
//     assert.equal(await this.oracle.getOperator(), getHexAddress(owner));
//   });

//   describe('setOperator', async () => {
//     it('should change operator if caller is the owner', async () => {
//       assert.equal(await this.oracle.getOperator(), getHexAddress(owner));
//       await this.oracle.setOperator(getHexAddress(alice), { from: owner });
//       assert.equal(await this.oracle.getOperator(), getHexAddress(alice));
//       await this.oracle.setOperator(getHexAddress(owner), { from: owner });
//     });

//     it('should not change operator if caller is not the owner', async () => {
//       assert.equal(await this.oracle.getOperator(), getHexAddress(owner));
//       // will fail
//       await this.oracle.setOperator(alice, { from: alice });
//       expect(await this.oracle.getOperator()).to.equal(getHexAddress(owner));
//     });

//     it('should not change operator to zero address', async () => {
//       assert.equal(await this.oracle.getOperator(), getHexAddress(owner));
//       // will fail
//       await this.oracle.setOperator(ZERO_ADDRESS, { from: owner });
//       assert.equal(await this.oracle.getOperator(), getHexAddress(owner));
//     });
//   });

//   describe('games functions', async () => {

//     it('should add game contract if caller is the owner', async () => {
//       await this.oracle.setGame(this.fakeGameController.address, { from: alice });
//       assert.equal(await this.oracle.getGame(), ZERO_ADDRESS)
//       await this.oracle.setGame(this.fakeGameController.address, { from: owner });
//       assert.equal(await this.oracle.getGame(), this.fakeGameController.address);
//     });

//     // it('should not add game contract if game contract isn\'t support IGame interface', async () => {
//     //   assert.equal(await this.oracle.getGamesCount(), 1);
//     //   // will fail
//     //   await this.oracle.addGame(alice, { from: owner });
//     //   // will fail
//     //   await this.oracle.addGame(ZERO_ADDRESS, { from: owner });
//     //   assert.equal(await this.oracle.getGamesCount(), 1);
//     // });

//     // it('should return game address at index', async () => {
//     //   assert.equal(await this.oracle.getGamesCount(), 1);
//     //   await this.oracle.addGame(this.fakeGameController.address, { from: owner });
//     //   assert.equal(await this.oracle.getGame(1), this.fakeGameController.address);
//     //   // assert.equal(await this.oracle.getGame(2), "REVERT opcode executed");
//     //     try {
//     //       await this.oracle.getGame(2);
//     //     } catch (e) {
//     //       console.log(e, 'GET GAME ERROR');
//     //     }
//     //   assert.equal(await this.oracle.getGame(1), this.fakeGameController.address);
//     // });

//     // it('should remove game contract if caller is the owner', async () => {
//     //   assert.equal(await this.oracle.getGamesCount(), 2);
//     //   await this.oracle.addGame(this.fakeGameController.address, { from: owner });
//     //   await this.oracle.addGame(this.fakeGameController.address, { from: owner });
//     //   assert.equal(await this.oracle.getGamesCount(), 4);
//     //   await this.oracle.removeGame(3, { from: owner });
//     //   await this.oracle.removeGame(2, { from: owner });
//     //   await this.oracle.removeGame(1, { from: owner });
//     //   await this.oracle.removeGame(0, { from: owner });
//     //   assert.equal(await this.oracle.getGamesCount(), 0);
//     //   try {
//     //     await this.oracle.removeGame(-1, { from: owner });
//     //   } catch (e) {
//     //       console.log(e.reason, 'REMOVE ERROR');
//     //   }
//     // });

//     // it('should not remove game contract if caller is not owner', async () => {
//     //   await this.oracle.addGame(this.fakeGameController.address, { from: owner });
//     //   assert.equal(await this.oracle.getGamesCount(), 1);
//     //   // will fail
//     //   await this.oracle.removeGame(0, { from: alice });
//     //   assert.equal(await this.oracle.getGamesCount(), 1);
//     // });
//   });

//   describe('functions with random number', async () => {

//     it('should create random number request if caller is IGame contract', async () => {
//       await this.fakeGameController.generateRandomGameId();
//       const gameId = await this.fakeGameController.getLastRequestId({ from: owner });
//       assert.isTrue(await this.oracle.checkPending(gameId.toString()), { from: owner });
//     });

//     it('should not create random number request if caller is not IGame contract', async () => {
//       const gameId = await this.fakeGameController.getLastRequestId({ from: owner });
//       assert.isTrue(await this.oracle.checkPending(gameId.toString()), { from: owner });
//        // will fail
//       const fakeRequestId = await this.oracle.generateRandomGameId({ from: owner });
//       assert.equal(await this.fakeGameController.getLastRequestId({ from: owner }), gameId.toString());
//     });

//     it('should accept random number request if caller is IGame contract', async () => {
//       await this.fakeGameController.generateRandomGameId();
//       const gameId = await this.fakeGameController.getLastRequestId({ from: owner });
//       const receipt = await this.fakeGameController.acceptRandomNumberRequest(gameId.toString());
//       // try {
//       //   expectEvent.inTransaction(receipt, this.oracle, 'RandomNumberRequested', {
//       //   callerAddress: this.fakeGameController.address,
//       //   gameId: gameId
//       // });
//       // } catch(e) {
//       //   console.log(e,13123123213213123213);
//       // }

//     });

//     it('should not accept random number request if caller is not IGame contract', async () => {
//       await this.fakeGameController.generateRandomGameId();
//       const gameId = await this.fakeGameController.getLastRequestId({ from: owner });
//       simpleExpectRevert(this.oracle.acceptRandomNumberRequest(gameId, { from: owner }), 'address is not a game');
//     });

//     it('should publish result if caller is the operator', async () => {
//       await this.fakeGameController.generateRandomGameId();
//       const gameId = await this.fakeGameController.getLastRequestId({ from: owner });
//       await this.fakeGameController.acceptRandomNumberRequest(gameId, { from: owner });
//       const RANDOM_NUMBER = 10;
//       assert.equal(await this.oracle.checkPending(gameId, { from: owner }), true);
//       // const oracle = tronweb.contract().at(this.oracle.address);
//       // oracle.then(meta => {
//       //   console.log(meta.RandomNumberEvent(), 999999);
//       //   meta.RandomNumberEvent().watch((err, res) => {
//       //     if(res) {
//       //       console.log(res.result)
//       //       assert.equal(res.result.randomNumber, 11);
//       //       done();
//       //     }
//       //     if(err) console.log(err, 777777777);
//       //     this.oracle.publishRandomNumber(RANDOM_NUMBER, this.fakeGameController.address, gameId, { from: owner });
//       //   })
//       // })
//       // await this.oracle.publishRandomNumber(RANDOM_NUMBER, this.fakeGameController.address, gameId, { from: owner });
//     });

//     it('should not publish result if caller is not operator', async () => {
//       await this.fakeGameController.generateRandomGameId();
//       const gameId = await this.fakeGameController.getLastRequestId({ from: owner });
//       await this.fakeGameController.acceptRandomNumberRequest(gameId, { from: alice });
//       const RANDOM_NUMBER = 10;
//       simpleExpectRevert(this.oracle.publishRandomNumber(RANDOM_NUMBER, this.fakeGameController.address, gameId, { from: owner }),
//         'is not the operator');
//     });

//     it('should not publish result if call func with wrong params', async () => {
//       await this.fakeGameController.generateRandomGameId();
//       const gameId = await this.fakeGameController.getLastRequestId({ from: owner });
//       await this.fakeGameController.acceptRandomNumberRequest(gameId, { from: owner });
//       const RANDOM_NUMBER = 10;
//       const otherGame = await FakeGameController.new(this.oracle.address);
//       simpleExpectRevert(this.oracle.publishRandomNumber(RANDOM_NUMBER, otherGame.address, gameId, { from: owner }),
//         'address is not a game');
//       simpleExpectRevert(this.oracle.publishRandomNumber(RANDOM_NUMBER, this.fakeGameController.address, gameId.add(10), { from: owner }),
//         'request isn\'t in pending list');
//     });
//   });
// });
