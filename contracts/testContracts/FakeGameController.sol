pragma solidity >0.4.18 < 0.6.0;

import "../GameController.sol";

contract FakeGameController is GameController {
    constructor (address oracleAddress) GameController(oracleAddress) public {
    }

    function createRandomNumberRequest() external {
         uint256 requestId = _oracle.createRandomNumberRequest();
        _randomNumbers[requestId].status = Status.Pending;
        _lastRequestId = requestId;
    }

    function acceptRandomNumberRequest(uint256 requestId) external {
        _oracle.acceptRandomNumberRequest(requestId);
    }

    function _publishResults(uint8[] memory cards, uint256 gameId) internal {
    }
}
