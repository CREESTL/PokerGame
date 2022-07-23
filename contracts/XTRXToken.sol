// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Interfaces.sol";


contract XTRXToken is IERC20Metadata, IInternalToken, ERC20Burnable, Ownable {
    using SafeMath for uint256;

//    mapping (address => bool) internal _burnerAddresses; // TODO: remove all unused code
    address internal _poolController;

//    modifier isBurner() {
//        require(_burnerAddresses[_msgSender()], "Caller is not burner");
//        _;
//    }

    modifier onlyPoolController() {
        require(_msgSender() == _poolController, "Caller is not pool controller");
        _;
    }

    constructor() ERC20("xEthereum", "xTRX", 18) public {
//        _burnerAddresses[_msgSender()] = true;
    }

    function supportsIInternalToken() external view returns (bool) {
        return true;
    }

    function getPoolController() external view returns (address) {
        return _poolController;
    }

    function setPoolController(address poolControllerAddress) external onlyOwner {
        IPool iPoolCandidate = IPool(poolControllerAddress);
        require(iPoolCandidate.supportsIPool(), "Invalid IPool address");
        _poolController = poolControllerAddress;
    }

//    function isBurnAllowed(address account) external view returns(bool) {
//        return _burnerAddresses[account];
//    }
//
//    function addBurner(address account) external onlyOwner {
//        require(!_burnerAddresses[account], "Already burner");
//        require(account != address(0), "Cant add zero address");
//        _burnerAddresses[account] = true;
//    }
//
//    function removeBurner(address account) external onlyOwner {
//        require(_burnerAddresses[account], "Isnt burner");
//        delete  _burnerAddresses[account];
//    }

    function mint(address recipient, uint256 amount) external onlyPoolController {
        _mint(recipient, amount);
    }

//    function burn(uint256 amount) external isBurner {
//        _burn(_msgSender(), amount);
//    }
//
//    function burnFrom(address account, uint256 amount) external isBurner {
//        super.burnFrom(account, amount);
//    }

    function burnTokenFrom(address account, uint256 amount) external onlyPoolController {
        _burn(account, amount);
    }
}
