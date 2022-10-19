// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IOracle {
    function supportsIOracle() external view returns (bool);

    function createRandomNumberRequest() external returns (uint256);
}
