// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGame.sol";
import "./interfaces/IOracle.sol";

/**
 * @title Controls game request state
 */
contract GameController is IGame, Ownable {

    /**
     * @dev Status of request
     */
    enum Status {
        Unknown,
        Pending,
        Closed
    }

    /**
     * @dev Request for a single game. 
     *      Gets opened when game is started.
     *      Gets closed when game is finished.
     */     
    struct Request {
        // TODO number of cards??
        uint64 result;
        // Last time when any changes were made in the request
        uint64 closedTime;
        // Current status of the request
        Status status;
    }

    /**
     * @dev This time should pass after the request was closed
     *      to be able to update the request status
     */
    uint256 private constant WAIT_SINCE_CLOSED = 7 * 86400; 

    /**
     * @dev Oracle used for random numbers generation
     */
    IOracle internal _oracle;
    /**
     * @dev The ID of the last closed request
     */
    uint256 internal _lastRequestId;

    /**
     * @dev Mapping from request IDs to requests
     */
    mapping(uint256 => Request) internal _requests;


    /**
     * @dev Constructor. Sets oracle address
     * @param oracleAddress The address of the oracle to be used
     */
    constructor(address oracleAddress) {
        _setOracle(oracleAddress);
    }

    /**
     * @notice Indicates that the contract supports {IGame} interface
     * @return True in any case
     */
    function supportsIGame() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Returns the address of the current oracle
     * @return The address of the current oracle
     */
    function getOracle() external view returns (address) {
        return address(_oracle);
    }

    /**
     * @notice Sets a new oracle
     * @param oracleAddress the address of the oracle to be used
     */
    function setOracle(address oracleAddress) external onlyOwner {
        _setOracle(oracleAddress);
    }

    /**
     * @notice Returns the ID of the last closed request
     * @return The ID of the last closed request
     */
    function getLastRequestId() external view onlyOwner returns (uint256) {
        return _lastRequestId;
    }


    /**
     * @notice Returns the request with the provided ID
     * @param requestId The ID of the request to look for
     * @return Full info about the request
     */
    function getRequest(uint256 requestId)
        public
        view
        onlyOwner
        returns (
            uint64,
            uint64,
            Status
        )
    {
        return (
            _requests[requestId].result,
            _requests[requestId].closedTime,
            _requests[requestId].status
        );
    }

    /**
     * @notice Finishes work with request and closes it
     * TODO not sure about params
     * @param bitCards The amount of cards???
     * @param requestId The ID of request to close
     */
    function _closeRequest(uint64 bitCards, uint256 requestId) internal {
        Request storage request = _requests[requestId];
        request.closedTime = uint64(block.timestamp);
        require(request.status != Status.Closed, "GameController: request is already closed!");
        request.status = Status.Closed;
        request.result = bitCards;
    }

    /**
     * @notice Updates one random request status and marks it as the one
     *         being processed
     */
    function _updateRandomRequest() internal {
        // Request ID is a random number
        uint256 requestId = _oracle.createRandomNumberRequest();
        Request storage request = _requests[requestId];
        // Check that chosen request was closed not too long ago
        require(
            request.closedTime <=
                (uint64(block.timestamp) - WAIT_SINCE_CLOSED),
            "GameController: minimum time since the request was closed have not passed yet!"
        );
        // Change request's status to Pending
        request.status = Status.Pending;
        // Update the ID of the last processed request
        _lastRequestId = requestId;
    }

    /**
     * @notice Sets a new oracle. See {setOracle}
     */
    function _setOracle(address oracleAddress) internal {
        // Check that contract with the provided address supports
        // correct interface
        IOracle iOracleCandidate = IOracle(oracleAddress);
        require(
            iOracleCandidate.supportsIOracle(),
            "GameController: contract does not implement IOracle interface!"
        );
        _oracle = iOracleCandidate;
    }
}
