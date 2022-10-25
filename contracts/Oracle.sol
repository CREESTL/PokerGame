// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IGame.sol";

/**
 * @title Provides random numbers to contracts. 
 *        Converts array of cards into binary format
 */
contract Oracle is IOracle, Ownable {

    /**
     * @dev Poker contract calling this oracle contract
     */
    IGame internal _game;

    // TODO not used, delete it???
    /**
     * @dev Address of backend
     */
    address internal _operator;
    /**
     * @dev Nonce of each request for random number generation
     */
    uint256 internal _nonce;

    /**
     * @dev Mapping from request ID to request status
     *      Status: true = pending, false = closed
     */
    mapping(uint256 => bool) internal _pendingRequests;

    // TODO not used - emit it!
    event RandomNumberRequested(
        address indexed callerAddress,
        uint256 indexed gameId
    );
    // TODO not used - emit it!
    event RandomNumberEvent(
        uint256 cardsBits,
        address indexed callerAddress,
        uint256 indexed gameId
    );

    /**
     * @dev Checks if caller is a poker contract
     * @param sender The address of caller
     */
    modifier onlyGame(address sender) {
        require(sender == address(_game), "Oracle: caller is not a poker contract!");
        _;
    }

    /**
     * @dev Constuctor initializes the nonce and the operator
     * @param operatorAddress The address of the operator to use
     */
    constructor(address operatorAddress) {
        _nonce = 0;
        _setOperator(operatorAddress);
    }

    /**
     * @notice Indicates that the contract supports {IOracle} interface
     * @return True in any case
     */
    function supportsIOracle() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Returns the address of current operator
     * @return The address of current operator
     */
    function getOperator() external view onlyOwner returns (address) {
        return _operator;
    }

    /**
     * @notice Sets a new operator
     * @param operatorAddress The address of a new operator
     */
    function setOperator(address operatorAddress) external onlyOwner {
        _setOperator(operatorAddress);
    }

    /**
     * @notice Returns the address of the current game that is using the oracle
     * @return The address of the game contract
     */
    function getGame() public view returns (address) {
        return address(_game);
    }

    /**
     * @notice Sets the address of the poker game for this oracle
     *         to provide random numbers for
     * @param gameAddress The address of the game contract
     */
    function setGame(address gameAddress) external onlyOwner {
        _setGame(gameAddress);
    }

    /**
     * @notice Checks if a request is pending
     * @param gameId The ID of the request to look for
     * @return True if request is pending. False if it is not
     */
    function checkPending(uint256 gameId)
        external
        view
        onlyOwner
        returns (bool)
    {
        return _pendingRequests[gameId];
    }

    /** 
     * @notice Creates a request for random number generation
     *         which is then handled by the backend
     * @return The ID of the created request
     */
    function createRandomNumberRequest()
        external
        onlyGame(_msgSender())
        returns (uint256)
    {   
        // ID gets initialized with 0 here
        uint256 gameId;
        /**
         * This cycle iterates at least once
         * By default all _pendingRequests[gameId] are false, so the loop will break
         * But if for any reason the _pendingRequests[gameId] is true, the loop will
         * iterate and generate new random gameId unless _pendingRequests[gameId] is false
         * and then break
         */
        do {
            // Each request gets a unique increasing nonce
            _nonce++;
            // TODO Blockchain is a bad source of randomness. Find another one???
            // Now request gets a random value instead of 0
            gameId = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, _msgSender(), _nonce)
                )
            ); 
        } while (_pendingRequests[gameId]);
        // A request with every new not pending gameId becomes a pending request
        _pendingRequests[gameId] = true;
        return gameId;
    }

    /**
     * @notice Converts an array of numbers (cards) into a single array of bits (binary number)
     * @param cards The array of cards to convert to an array of bits
     * @return Binary representation of an array of cards
     */
    function cardsToBits(uint8[] memory cards) public pure returns (uint256) {
        uint256 cardsBits;
        for (uint256 i = 0; i < cards.length; i++) {
            cardsBits |= (uint256(cards[i]) << (6 * i));
        }
        return cardsBits;
    }

    /**
     * @notice Sets the address of the poker game for this oracle
     *         to provide random numbers for
     * See {setGame}
     */
    function _setGame(address gameAddress) internal {
        // Check that contract with the provided address supports
        // correct interface
        IGame iGameCandidate = IGame(gameAddress);
        require(
            iGameCandidate.supportsIGame(),
            "Oracle: contract does not implement IGame interface!"
        );
        _game = iGameCandidate;
    }

    /**
     * @notice Sets a new operator. See {setOperator}
     */
    function _setOperator(address operatorAddress) internal {
        require(operatorAddress != address(0), "Oracle: invalid operator address!");
        _operator = operatorAddress;
    }
}
