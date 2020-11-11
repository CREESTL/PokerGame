let Oracle = artifacts.require("../contracts/Oracle.sol");
let XETHToken = artifacts.require("../contracts/XETHToken.sol");
let PoolController = artifacts.require("../contracts/PoolController.sol");
let Poker = artifacts.require("../contracts/Poker.sol");

module.exports = function(deployer, network, owner) {

  deployer.then(async () => {    
    const xETH = await deployer.deploy(XETHToken);
    const oracle = await deployer.deploy(Oracle, owner);
    const poolController = await deployer.deploy(PoolController, xETH.address);
    await deployer.deploy(Poker, oracle.address, poolController.address);
  });
}; 
