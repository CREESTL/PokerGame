// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPool {
    function supportsIPool() external view returns (bool);

    function addBetToPool(uint256 betAmount) external payable;

    function jackpotDistribution(address payable player, uint256 prize)
        external;

    function rewardDistribution(address payable player, uint256 prize) external;

    function freezeJackpot(uint256 amount) external;

    function addToJackpot(uint256 amount) external;

    function updateRefereeStats(
        address player,
        uint256 amount,
        uint256 betEdge
    ) external;

    function getOracleGasFee() external view returns (uint256);

    function getNativeTokensTotal() external view returns (uint256);

    function getAvailableJackpot() external view returns (uint256);

    function totalJackpot() external view returns (uint256);

    function jackpotLimit() external view returns (uint256);

    function receiveFundsFromGame() external payable;
}
