let GameController = artifacts.require("../contracts/GameController.sol");
let Oracle = artifacts.require("../contracts/Oracle.sol");
let XETHToken = artifacts.require("../contracts/XETHToken.sol");
let PokerUtils = artifacts.require("../contracts/PokerUtils.sol");
let FakeGameController = artifacts.require("../contracts/testContracts/FakeGameController.sol");
let PoolController = artifacts.require("../contracts/PoolController.sol");
let BestHandFinder = artifacts.require("../contracts/BestHandFinder.sol");

module.exports = function(deployer, network, owner) {

  deployer.then(async () => {    
    // const xETH = await deployer.deploy(XETHToken);
    // const oracle = await deployer.deploy(Oracle, owner);
    // await deployer.deploy(FakeGameController, oracle.address)
    // await deployer.deploy(PoolController, xETH.address);
    await deployer.deploy(BestHandFinder);
    // await deployer.deploy(GameController, oracle.address);
  });

  // deployer.deploy(ConvertLib);
  // deployer.link(ConvertLib, MetaCoin);
  // deployer.deploy(MetaCoin, 10000);
}; 
