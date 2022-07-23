// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/GSN/Context.sol";
import "./Interfaces.sol";


contract Oracle is IOracle, Ownable {
    IGame internal _game;
    address internal _operator;
    string internal _owner;
    uint256 internal _nonce;

    mapping(uint256 => bool) internal _pendingRequests;

    event RandomNumberRequestEvent(address indexed callerAddress, uint256 indexed requestId);
    event RandomNumberEvent(uint bitCards, address indexed callerAddress, uint256 indexed requestId);

    modifier onlyGame(address sender) {
        require(sender == address(_game), "O: not game");
        _;
    }

    constructor (address operatorAddress) public {
        _nonce = 0;
        _setOperatorAddress(operatorAddress);
    }

    function supportsIOracle() external view returns (bool) {
        return true;
    }

    function getOperatorAddress() external view onlyOwner returns (address) {
        return _operator;
    }

    function setOperatorAddress(address operatorAddress) external onlyOwner {
        _setOperatorAddress(operatorAddress);
    }

    function setGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        _game = game;
    }

    function getPendingRequests(uint256 requestId) external view onlyOwner returns (bool) {
        return _pendingRequests[requestId];
    }

    function createRandomNumberRequest() external onlyGame(_msgSender()) returns (uint256) {
        uint256 requestId;
        do {
            _nonce++;
            requestId = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _nonce)));
        } while (_pendingRequests[requestId]);
        _pendingRequests[requestId] = true;
        return requestId;
    }

    function getGame() public view returns (address) {
        return address(_game);
    }

    function toBit(uint8[] memory cards) public pure returns(uint256) {
        uint256 bitCards;
        for (uint256 i = 0; i < cards.length; i++) {
            bitCards |= (uint256(cards[i]) << (6 * i));
        }
        return bitCards;
    }

    function _setOperatorAddress(address operatorAddress) internal {
        require(operatorAddress != address(0), "invalid address");
        _operator = operatorAddress;
    }
}
