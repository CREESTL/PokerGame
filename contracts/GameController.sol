// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGame.sol";
import "./interfaces/IOracle.sol";

/**
 * @title Controls game state
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
        // Binary representation of array of cards used in the game
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
     * NOTE: Request ID is the ID of the game from {Poker}. It's explicitly shown through the variable name here.
     */
    uint256 internal _lastGameId;

    /**
     * @dev Mapping from game IDs to requests
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
        return _lastGameId;
    }

    /**
     * @notice Returns the request with the provided ID
     * @param gameId The ID of the request to look for
     * @return Full info about the request
     */
    function getRequest(
        uint256 gameId
    ) public view onlyOwner returns (uint64, uint64, Status) {
        return (
            _requests[gameId].result,
            _requests[gameId].closedTime,
            _requests[gameId].status
        );
    }

    /**
     * @notice Finishes work with request and closes it
     * @param cardsBits Binary number representing an array of cards
     * @param gameId The ID of request to close
     */
    function _closeRequest(uint64 cardsBits, uint256 gameId) internal {
        Request storage request = _requests[gameId];
        request.closedTime = uint64(block.timestamp);
        require(
            request.status != Status.Closed,
            "GameController: request is already closed!"
        );
        request.status = Status.Closed;
        request.result = cardsBits;
    }

    /**
     * @notice Picks a random game request and marks it as the pending one. That means that
     *         the game with the same ID as the request has will be started soon
     */
    function _requestNewGame() internal {
        // Request ID is a random number
        uint256 gameId = _oracle.generateRandomGameId();
        Request storage request = _requests[gameId];
        // Check that chosen request was closed not too long ago
        require(
            request.closedTime <= (uint64(block.timestamp) - WAIT_SINCE_CLOSED),
            "GameController: minimum time since the request was closed have not passed yet!"
        );
        // Change request's status to Pending
        request.status = Status.Pending;
        // Update the ID of the last processed request
        _lastGameId = gameId;
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
