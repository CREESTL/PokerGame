// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces.sol";


contract XTRXToken is IERC20Metadata, ERC20Burnable, IInternalToken, Ownable {
    using SafeMath for uint256;

    /// @dev Only some addresses can burn tokens
    mapping (address => bool) internal _burnerAddresses; 
    address internal _poolController;

    /// @dev Checks if caller controls the pool
    modifier onlyPoolController() {
        require(_msgSender() == _poolController, "xt: Caller is Not a Pool Controller!");
        _;
    }

    /// @dev Create a new token
    /// @dev Add the caller of constructor to the list of burners
    /// @dev Default `decimals` is 18
    constructor() ERC20("xEthereum", "xTRX") {
        _burnerAddresses[_msgSender()] = true;
    }


    /// @dev Checks if this contract supports interface
    function supportsIInternalToken() external pure returns (bool) {
        return true;
    }


    /// @dev Getter for a pool controller address
    function getPoolController() external view returns (address) {
        return _poolController;
    }

    /// @dev Setter for a pool controller address
    function setPoolController(address poolControllerAddress) external onlyOwner {
        IPool iPoolCandidate = IPool(poolControllerAddress);
        require(iPoolCandidate.supportsIPool(), "xt: Contract Does Not Implement IPool Interface!");
        _poolController = poolControllerAddress;
    }

    /// @dev Pool controller can mint tokens to anyone
    function mint(address recipient, uint256 amount) external onlyPoolController {
        _mint(recipient, amount);
    }

    /// @dev Pool controller can burn anyone's tokens
    function burnTokenFrom(address account, uint256 amount) external onlyPoolController {
        _burn(account, amount);
    }
}
