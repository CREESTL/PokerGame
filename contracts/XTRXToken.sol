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

    /// @dev Checks if caller is allowed to burn tokens
    modifier isBurner() {
       require(_burnerAddresses[_msgSender()], "Caller is not allowed to burn tokens!");
       _;
    }

    /// @dev Checks if caller controls the pool
    modifier onlyPoolController() {
        require(_msgSender() == _poolController, "Caller is not a pool controller!");
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
        require(iPoolCandidate.supportsIPool(), "Invalid IPool address!");
        _poolController = poolControllerAddress;
    }

    /// @dev Checks if a provided user is allowes to burn tokens
    function isBurnAllowed(address account) external view returns(bool) {
       return _burnerAddresses[account];
    }

    /// @dev Allows a provided user to burn tokens
    function addBurner(address account) external onlyOwner {
       require(!_burnerAddresses[account], "This user is already allowed to burn tokens!");
       require(account != address(0), "Can't allow a zero address to burn tokens!");
       _burnerAddresses[account] = true;
    }

    /// @dev Prohibits the user from burning tokens
    function removeBurner(address account) external onlyOwner {
       require(_burnerAddresses[account], "Isnt burner");
       delete  _burnerAddresses[account];
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
