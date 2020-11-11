pragma solidity >0.4.18 < 0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./Interfaces.sol";

contract GameController is IGame, Ownable{
    using SafeMath for uint256;

    enum Status { Unknown, Pending, Result }

    struct Numbers {
        uint8[] result;
        uint64 timestamp;
        Status status;
    }

    uint256 constant private MIN_TIME_TO_HISTORY_OF_REQUESTS = 7 * 86400; // 1 week

    IOracle internal _oracle;
    uint256 internal _lastRequestId;
    mapping(uint256 => Numbers) internal _randomNumbers; // requestId -> Numbers

    modifier onlyOracle() {
        require(msg.sender == address(_oracle), "caller is not the oracle");
        _;
    }

    constructor (address oracleAddress) public {
        _setOracle(oracleAddress);
    }

    function supportsIGame() external view returns (bool) {
        return true;
    }

    function getOracle() external view returns (address) {
        return address(_oracle);
    }

    function setOracle(address oracleAddress) external onlyOwner {
        _setOracle(oracleAddress);
    }

    function getLastRequestId() external view onlyOwner returns (uint256) {
        return _lastRequestId;
    }

    function __callback(uint8[] calldata cards, uint256 requestId, uint256 bitCards) onlyOracle external {
        Numbers storage number = _randomNumbers[requestId];
        number.timestamp = uint64(block.timestamp);
        require(number.status == Status.Pending, "request already closed");
        number.status = Status.Result;
        number.result = cards;
        _publishResults(cards, requestId, bitCards);
    }

    function _updateRandomNumber() internal {
        uint256 requestId = _oracle.createRandomNumberRequest();
        require(_randomNumbers[requestId].timestamp <= (uint64(block.timestamp) - MIN_TIME_TO_HISTORY_OF_REQUESTS), "requestId already used");
        _oracle.acceptRandomNumberRequest(requestId);
        _randomNumbers[requestId].status = Status.Pending;
        _lastRequestId = requestId;
    }

    function _setOracle(address oracleAddress) internal {
        IOracle iOracleCandidate = IOracle(oracleAddress);
        require(iOracleCandidate.supportsIOracle(), "invalid IOracle address");
        _oracle = iOracleCandidate;
    }

    function _publishResults(uint8[] memory cards, uint256 gameId, uint256 bitCards) internal {
    }
}
