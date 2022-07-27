// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";


contract GameController is IGame, Ownable {
    using SafeMath for uint256;

    enum Status { Unknown, Pending, Result }

    struct Numbers {
        uint64 result;
        uint64 timestamp;
        Status status;
    }

    uint256 constant private MIN_TIME_TO_HISTORY_OF_REQUESTS = 7 * 86400; // 1 week

    IOracle internal _oracle;
    uint256 internal _lastRequestId;
    mapping(uint256 => Numbers) internal _randomNumbers; // requestId -> Numbers

    constructor (address oracleAddress) {
        _setOracle(oracleAddress);
    }

    function supportsIGame() external pure returns (bool) {
        return true;
    }

    function getOracle() external view returns (address) {
        return address(_oracle);
    }

    function getRandomNumberInfo(uint256 requestId) public view onlyOwner returns(uint64, uint64, Status) {
        return (
            _randomNumbers[requestId].result,
            _randomNumbers[requestId].timestamp,
            _randomNumbers[requestId].status
        );
    }

    function setOracle(address oracleAddress) external onlyOwner {
        _setOracle(oracleAddress);
    }

    function getLastRequestId() external view onlyOwner returns (uint256) {
        return _lastRequestId;
    }

    function __callback(uint64 bitCards, uint256 requestId) internal {
        Numbers storage number = _randomNumbers[requestId];
        number.timestamp = uint64(block.timestamp);
        require(number.status == Status.Pending, "gc: Request Is Closed!");
        number.status = Status.Result;
        number.result = bitCards;
    }

    function _updateRandomNumber() internal {
        uint256 requestId = _oracle.createRandomNumberRequest();
        require(_randomNumbers[requestId].timestamp <= (uint64(block.timestamp) - MIN_TIME_TO_HISTORY_OF_REQUESTS), "gc: RequestId Has Already Been Used!");
        _randomNumbers[requestId].status = Status.Pending;
        _lastRequestId = requestId;
    }

    function _setOracle(address oracleAddress) internal {
        IOracle iOracleCandidate = IOracle(oracleAddress);
        require(iOracleCandidate.supportsIOracle(), "gc: Contract with oracleAddress Does Not Implement IOracle Interface!");
        _oracle = iOracleCandidate;
    }
}
