pragma solidity >0.4.18 < 0.6.0;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "./Interfaces.sol";


contract Oracle is IOracle, Ownable {
    IGame internal _games;
    address internal _operator;
    string internal _owner;
    uint256 internal _nonce;

    mapping(uint256 => bool) internal _pendingRequests;

    event RandomNumberRequestEvent(address indexed callerAddress, uint256 indexed requestId);
    event RandomNumberEvent(uint bitCards, address indexed callerAddress, uint256 indexed requestId);

    modifier onlyGame(address sender) {
        bool senderIsAGame = false;
        require(sender == address(_games), "caller is not allowed to do some");
        _;
    }

    modifier onlyOperator() {
        require(_msgSender() == _operator, "caller is not the operator");
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
    

    function getGame() public view returns (address) {
        return address(_games);
    }

    function setGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        _games = game;
    }

    function getPendingRequests(uint256 requestId) external view onlyOwner returns (bool) {
        return _pendingRequests[requestId];
    }

    function createRandomNumberRequest() external onlyGame(_msgSender()) returns (uint256) {
        uint256 requestId = 0;
        do {
            _nonce++;
            requestId = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _nonce)));
        } while (_pendingRequests[requestId]);
        _pendingRequests[requestId] = true;
        return requestId;
    }

    function acceptRandomNumberRequest(uint256 requestId) external onlyGame(_msgSender()) {
        emit RandomNumberRequestEvent(_msgSender(), requestId);
    }

    function publishRandomNumber(uint8[] calldata cards, address callerAddress, uint256 requestId) external onlyOperator {
        require(_pendingRequests[requestId], "request isn't in pending list");
        delete _pendingRequests[requestId];

        uint bitCards = toBit(cards);
        IGame(callerAddress).__callback(cards, requestId, bitCards);
        emit RandomNumberEvent(bitCards, callerAddress, requestId);
    }

    function _setOperatorAddress(address operatorAddress) internal {
        require(operatorAddress != address(0), "invalid operator address");
        _operator = operatorAddress;
    }

    function toBit(uint8[] memory cards) public pure returns(uint) {
        uint bitCards;
        for(uint i = 0; i < cards.length; i++) {
            bitCards |= (uint256(cards[i]) << (6 * i));
        }
        return bitCards;
    }
}
