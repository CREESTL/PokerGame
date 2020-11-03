let GameController = artifacts.require("../contracts/GameController.sol");
let Oracle = artifacts.require("../contracts/Oracle.sol");
let XETHToken = artifacts.require("../contracts/XETHToken.sol");
let PokerUtils = artifacts.require("../contracts/PokerUtils.sol");
let FakeGameController = artifacts.require("../contracts/testContracts/FakeGameController.sol");
let PoolController = artifacts.require("../contracts/PoolController.sol");
let Poker = artifacts.require("../contracts/Poker.sol");

module.exports = function(deployer, network, owner) {

  deployer.then(async () => {    
    const xETH = await deployer.deploy(XETHToken);
    const oracle = await deployer.deploy(Oracle, owner);
    // await deployer.deploy(FakeGameController, oracle.address)
    const poolController = await deployer.deploy(PoolController, xETH.address);
    await deployer.deploy(Poker, oracle.address, poolController.address);
    // await deployer.deploy(GameController, oracle.address);
  });
}; 
