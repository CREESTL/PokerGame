// pragma solidity >0.4.18 < 0.6.0;

// import "../Interfaces.sol";

// contract FakeOracle is IOracle {
//     uint256 public _requestId;

//     function supportsIOracle() external view returns (bool) {
//         return true;
//     }

//     function setRequestId(uint256 requestId) external {
//        _requestId = requestId;
//     }

//     function createRandomNumberRequest() external returns (uint256) {
//         return _requestId;
//     }

//     function acceptRandomNumberRequest(uint256 requestId) external {
//     }

//     function publishRandomNumber(uint8[] calldata cards, address callerAddress, uint256 requestId) external {
//         IGame(callerAddress).__callback(cards, requestId);
//     }
// }
