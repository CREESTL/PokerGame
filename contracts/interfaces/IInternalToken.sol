// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IInternalToken is IERC20 {
    function supportsIInternalToken() external view returns (bool);

    function burnTokenFrom(address account, uint256 amount) external;

    function mint(address recipient, uint256 amount) external;
}
