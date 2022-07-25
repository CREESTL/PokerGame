// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function supportsIPool() external view returns (bool);
    function addBetToPool(uint256 betAmount) external payable;

    function jackpotDistribution(address payable player, uint256 prize) external;
    function rewardDisribution(address payable player, uint256 prize) external;
    function updateJackpot(uint amount) external;

    function updateReferralStats(address player, uint amount, uint256 betEdge) external;
    
    function getOracleGasFee() external view returns (uint256);
    function getPoolAmount() external view returns (uint256);
    function jackpot() external view returns (uint256);

    function receiveFundsFromGame() external payable;
}

interface IGame {
    // function supportsIGame() external view returns (bool);
    // function __callback(uint8[] calldata cards, uint256 requestId) in; // TODO: add "bytes memory _proof" arg
}

interface IInternalToken is IERC20{
    function supportsIInternalToken() external view returns (bool);
    function burnTokenFrom(address account, uint256 amount) external;
    function mint(address recipient, uint256 amount) external;

}

interface IOracle {
    function supportsIOracle() external view returns (bool);
    function createRandomNumberRequest() external returns (uint256);
}

