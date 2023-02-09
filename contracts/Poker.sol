// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPool.sol";
import "./GameController.sol";

/**
 * @title Main Texas Hold`em game logic
 */
contract Poker is GameController {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint8;

    /**
     * @dev All possible results of the game
     */
    enum GameResult {
        Lose,
        Draw,
        Win,
        Jackpot
    }

    /**
     * @dev Maximum amount of tokens to bet
     */
    uint256 public _maxBet;

    /**
     * @dev The address of the operator capable
     *      of calling specific functions
     */
    address public _operator;

    /**
     * @dev One of the players
     */
    struct Hand {
        // Total of 7 cards
        uint8[7] cards;
        // Each card has a rank. A number from 0 to 13
        uint8[7] ranks;
        // Kickers are cards in a poker hand that do not determine the rank of the hand,
        // but are used to break ties between hands of the same rank
        int8[7] kickers;
        uint8 hand;
    }

    /**
     * @dev Game from the point of view of a single player
     *      If 2 players take part in one game round, each of them
     *      has his own {Game}
     */
    struct Game {
        // The amount of tokens a player bet on the color
        uint128 colorBet;
        // The amount of tokens a player bet on the poker game itself
        uint128 pokerBet;
        // The amount of tokens to be given to the winner of the game.
        // It is the sum of the prize for the game and the prize for guessing the dominant color
        uint256 winAmount;
        // The amount of tokens to be given to the members of referral program
        uint128 refAmount;
        // A person taking part in the game
        address payable player;
        // A color a person has chosen to bet on
        uint8 chosenColor;
        // True if win amount of the game has been claimed
        bool isWinAmountClaimed;
        // True if the result of the game was a jackpot
        bool isJackpot;
    }

    /**
     * House edge is the mathematical advantage that a casino has on a player’s bet
     * that ensures the casino makes a profit over the long run.
     */
    uint256 public houseEdge;
    /**
     * If `houserEdge` is 15 and `_percentDivider` is 1000, then house edge is 15 / 1000 = 0.015%
     */
    uint256 private constant _percentDivider = 1000;
    /**
     * @dev Bet amount gets multiplied by {jackpotFeeMultiplier}
     *      if a player wins a jackpot
     */
    uint256 public jackpotFeeMultiplier;

    /**
     * @dev Indicates that the game has started
     */
    event GameStart(uint256 gameId);

    /**
     * @dev Indicates that the game has finished
     *      Shows the result of a single game
     */
    event GameFinished(
        uint256 gameId,
        uint256 winAmount,
        uint256 cardsBits,
        bool isJackpot
    );

    /**
     * @dev Indicates that someone claimed the amount he won
     */
    event WinAmountClaimed(uint256 gameId);

    /**
     * @dev Contract controlling pool of in-game tokens
     */
    IPool private _poolController;

    /**
     * @dev Mapping from request IDs to games
     */
    mapping(uint256 => Game) public games;

    /**
     * @dev Checks that caller is an operator
     */
    modifier onlyOperator() {
        require(msg.sender == _operator, "Poker: caller is not an operator!");
        _;
    }

    /**
     * @notice Initializes the contract. Assignes default values to variables
     */
    constructor(
        // The address of the oracle to generate random numbers
        address oracleAddress,
        // The address controlling the pool of in-game tokens
        address poolControllerAddress,
        // The address of gane operator (usually, address of the backend)
        address operator
    ) GameController(oracleAddress) {
        _setPoolController(poolControllerAddress);
        // House edge is se
        houseEdge = 15;
        // Bet gets multiplied by 2 in case of jackpot by default
        jackpotFeeMultiplier = 2;
        _operator = operator;
    }

    /**
     * @notice Returns the address of the current pool controller
     * @return The address of the current pool controller
     */
    function getPoolController() external view returns (address) {
        return address(_poolController);
    }

    /**
     * @notice Changes the address of the pool controller
     * @param  poolControllerAddress A new address of the pool controller
     */
    function setPoolController(
        address poolControllerAddress
    ) external onlyOwner {
        _setPoolController(poolControllerAddress);
    }

    /**
     * @notice Changes the address of the game operator
     * @param  operatorAddress The address of the new operator
     */
    function setOperator(address operatorAddress) external onlyOwner {
        _operator = operatorAddress;
    }

    /**
     * @notice Changes the maxximum amount of tokens to bet
     * @param maxBet The maximum amount of tokens to bets
     */
    function setMaxBet(uint256 maxBet) external onlyOperator {
        _maxBet = maxBet;
    }

    /**
     * @notice Changes the house edge of the game
     * @param _houseEdge A new house edge
     */
    function setHouseEdge(uint256 _houseEdge) external onlyOwner {
        houseEdge = _houseEdge;
    }

    /**
     * @notice Changes the current jackpot multiplier
     * @param _jackpotFeeMultiplier A new jackpot multiplier to use
     */
    function setJackpotFeeMultiplier(
        uint256 _jackpotFeeMultiplier
    ) external onlyOwner {
        jackpotFeeMultiplier = _jackpotFeeMultiplier;
    }

    /**
     * @notice User pays tokens, makes bets and starts a game
     * @param colorBet The amount of tokens at stake for a chosen color
     * @param chosenColor The color a player chose
     */
    function startGame(uint256 colorBet, uint256 chosenColor) external payable {
        uint256 msgValue = msg.value;

        // What's left of players tokens after he bet on the color
        uint256 pokerBet = msgValue.sub(colorBet);

        // Check that the bet is valid
        _isValidBet(msgValue);

        // Tokens from each bet get added to the total pool
        _poolController.addBetToPool(msgValue);
        // Jackpot amount gets calculated based on player's bet
        _poolController.addToJackpot(
            pokerBet.mul(jackpotFeeMultiplier).div(_percentDivider)
        );

        // Create a new request for a random number
        // This updates {_lastGameId} ( internal variable inhereted from {GameController} )
        super._requestNewGame();

        address payable player = payable(_msgSender());

        // Get a random game from all games
        // It is "empty" at first
        Game storage game = games[_lastGameId];
        // Initialize it with new values
        game.colorBet = uint128(colorBet);
        game.pokerBet = uint128(pokerBet);
        if (chosenColor > 0) {
            game.chosenColor = uint8(chosenColor);
        }
        game.player = player;

        emit GameStart(_lastGameId);
    }

    /**
     * @notice Distributes cards between a player and a computer, compares their hands and determines the winner
     * @param _cards The array of cards to play. Length of 8
     * @return Game result for the *person*: Win, Jackpot, Lose or Draw
     */
    function getPokerResult(
        uint8[] memory _cards
    ) public pure returns (GameResult) {
        Hand memory player;
        Hand memory computer;
        for (uint256 i; i < _cards.length; i++) {
            if (i < 7) {
                // First 7 cards of the player are copied from _cards
                player.cards[i] = _cards[i];
                player.ranks[i] = _cards[i] % 13;
            }
            if (i > 1) {
                // Cards from index 2 to index 8 are copied to computer's hand
                // So cards 2 - 6 (5 in total) are the same for computer and the player
                computer.cards[i - 2] = _cards[i];
                computer.ranks[i - 2] = _cards[i] % 13;
            }
        }
        _sort(player.ranks, player.cards, 0, 6);
        _sort(computer.ranks, computer.cards, 0, 6);

        // Check hands of both players and return the strongest hands for both
        (player.hand, player.kickers) = _evaluateHand(
            player.cards,
            player.ranks
        );
        (computer.hand, computer.kickers) = _evaluateHand(
            computer.cards,
            computer.ranks
        );

        // Determine the winner of the game based on each player's hand
        return
            _getPokerResult(
                player.hand,
                player.kickers,
                computer.hand,
                computer.kickers
            );
    }

    /**
     * @notice Checks if player guessed the dominant color correctly
     * @param gameId The ID of the game
     * @param cardColors Colors of cards
     * @return True if player guessed the dominant color. False - if he did not
     */
    function getColorResult(
        uint256 gameId,
        uint8[] memory cardColors
    ) public view returns (bool) {
        uint256 colorCounter;
        uint256 chosenColor = games[gameId].chosenColor;
        for (uint256 i; i < cardColors.length; i++) {
            if ((cardColors[i] / 13) % 2 == chosenColor) {
                colorCounter++;
            }
            if (colorCounter >= 2) return true;
        }
        return false;
    }

    /**
     * @notice Calculates the amount of tokens to be paid for:
     *         - Poker win
     *         - Color bet win
     *         - Referral program membership
     * @param gameId The ID of the game
     * @param result The result of the game with the provided ID
     * @param winColor True if a player won a color bet. False - if he lost
     * @return The amount of tokens to be paid for:
     *         - Poker win
     *         - Color bet win
     *         - Referral program membership
     */
    function calculateWinAmount(
        uint256 gameId,
        GameResult result,
        bool winColor
    ) external view returns (uint256, uint256, uint256) {
        // How many tokens to pay to the winner of poker game
        uint256 winPokerAmount;
        // How many tokens to pay to the winner of color bet
        // Can be summed with {winPokerAmount}
        uint256 winColorAmount;
        // Tokens to pay for referral program membership
        uint256 referralBonus;

        // Retrive info about the game using the game ID
        uint256 pokerBet = games[gameId].pokerBet;
        uint256 colorBet = games[gameId].colorBet;

        uint256 pokerBetEdge = pokerBet.mul(houseEdge).div(_percentDivider);
        uint256 colorBetEdge;

        uint256 jackPotAdder = pokerBet.mul(jackpotFeeMultiplier).div(
            _percentDivider
        );

        // User won a color bet
        if (winColor) {
            colorBetEdge = colorBet.mul(houseEdge).div(_percentDivider);
            referralBonus = referralBonus.add(colorBetEdge);
            winColorAmount = colorBet.mul(jackpotFeeMultiplier).sub(
                colorBetEdge
            );
        }

        // None of the players won
        if (result == GameResult.Draw) {
            winPokerAmount = pokerBet.sub(pokerBetEdge + jackPotAdder);
        }

        // User won a game
        if (result == GameResult.Win) {
            referralBonus = referralBonus.add(pokerBetEdge);
            winPokerAmount = pokerBet.mul(2).sub(pokerBetEdge + jackPotAdder);
        }

        // User won and it's a jackpot
        if (result == GameResult.Jackpot) {
            winPokerAmount = _poolController.getAvailableJackpot() <=
                _poolController.jackpotLimit()
                ? _poolController.getAvailableJackpot()
                : _poolController.jackpotLimit();
        }

        return (winPokerAmount, winColorAmount, referralBonus);
    }

    /**
     * @notice Called by the backend to set the game result
     * @param gameId The ID of the game
     * @param winAmount The amount that will be given to the winner (for winning the game and guessing the color)
     * @param refAmount The amount that will be given to the member of referral program
     * @param isJackpot True if one of the players won a jackpot
     * @param cardsBits Binary number representing an array of cards
     */
    function endGame(
        uint256 gameId,
        uint256 winAmount,
        uint128 refAmount,
        bool isJackpot,
        uint64 cardsBits
    ) external onlyOperator {
        // Values from backend are assigned to the game
        games[gameId].winAmount = winAmount;
        games[gameId].refAmount = refAmount;
        games[gameId].isJackpot = isJackpot;

        if (isJackpot) {
            require(
                winAmount <= _poolController.jackpotLimit(),
                "Poker: jackpot is greater than limit!"
            );
            require(
                winAmount <= _poolController.totalJackpot(),
                "Poker: not enough funds for jackpot!"
            );
            _poolController.freezeJackpot(winAmount);
        }

        emit GameFinished(gameId, winAmount, cardsBits, isJackpot);

        // Finish work with current game request
        _closeRequest(cardsBits, gameId);
    }

    /**
     * @notice Allows player to claim tokens he won in the game
     * @param gameId The ID of the game request
     */
    function claimWinAmount(uint256 gameId) external {
        require(
            games[gameId].player == _msgSender(),
            "Poker: caller is not a player!"
        );
        // Either player of referee should win.
        require(
            games[gameId].winAmount > 0 || games[gameId].refAmount > 0,
            "Poker: invalid amount!"
        );
        require(
            !games[gameId].isWinAmountClaimed,
            "Poker: prize already claimed!"
        );

        address payable player = games[gameId].player;
        uint256 winAmount = games[gameId].winAmount;
        uint256 refAmount = games[gameId].refAmount;

        // Mark that this game win amount was claimed
        games[gameId].isWinAmountClaimed = true;

        // Update referers stats according to the win amount
        _poolController.updateRefereeStats(player, winAmount, refAmount);

        if (games[gameId].isJackpot) {
            // If a player won a jackpot, distribute tokens in one way
            _poolController.jackpotDistribution(player, winAmount);
        } else {
            // If a player simply won (no jackpot), distribute tokens in another way
            _poolController.rewardDistribution(player, winAmount);
        }

        emit WinAmountClaimed(gameId);
    }

    /**
     * @notice Sends tokens from the game to the pool controller
     */
    function sendFundsToPool() external onlyOperator {
        _poolController.receiveFundsFromGame{value: address(this).balance}();
    }

    /**
     * @notice Changes the address of the pool controller
     *         See {setPoolController}
     */
    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(
            poolCandidate.supportsIPool(),
            "Poker: contract with IPoolAddress does not implement IPool interface!"
        );
        _poolController = poolCandidate;
    }

    /**
     * @notice Sort algorithm for an array of numbers
     * @param dataRanks The array of ranks
     * @param dataCards The array of cards
     * @param low The left border of sort
     * @param high The right border of sort
     */
    function _sort(
        uint8[7] memory dataRanks,
        uint8[7] memory dataCards,
        uint256 low,
        uint256 high
    ) private pure {
        if (low < high) {
            uint256 pivotVal = dataRanks[(low + high) / 2];
            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (dataRanks[low1] > pivotVal) low1++;
                while (dataRanks[high1] < pivotVal) high1--;
                if (low1 >= high1) break;
                (dataRanks[low1], dataRanks[high1]) = (
                    dataRanks[high1],
                    dataRanks[low1]
                );
                (dataCards[low1], dataCards[high1]) = (
                    dataCards[high1],
                    dataCards[low1]
                );
                low1++;
                high1--;
            }
            if (low < high1) _sort(dataRanks, dataCards, low, high1);
            high1++;
            if (high1 < high) _sort(dataRanks, dataCards, high1, high);
        }
    }

    /**
     * @notice Check all card combinations of the player and return the strongest hand
     * @param _cards The array of cards to check
     * @param _ranks The array of ranks of cards
     * @return The strongest hand and card order
     */
    function _evaluateHand(
        uint8[7] memory _cards,
        uint8[7] memory _ranks
    ) private pure returns (uint8, int8[7] memory) {
        uint8 strongestHand;
        // Get kickers.
        int8[7] memory retOrder = [-1, -1, -1, -1, -1, -1, -1];
        // Check for flush
        uint8[4] memory suits = [0, 0, 0, 0];
        // Check for pairs, 3oaK, 4oaK
        uint8[13] memory valuesMatch = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // Used in a loop
        uint256 i;
        // Write pairs and triples, triple always first
        int8[2] memory pairs = [-1, -1];
        uint256 streetChecker = 1;
        // Check for street flush
        uint256 flushWinSuit;
        int8[7] memory streetFlushCards = [-1, -1, -1, -1, -1, -1, -1];

        for (i = 0; i < 7; i++) {
            valuesMatch[_ranks[i]]++;
            // Check for street
            if (i < 6) {
                if (_ranks[i] == _ranks[i + 1] + 1) {
                    streetChecker++;
                    if (streetChecker == 5) {
                        strongestHand = 4;
                        retOrder[0] = int8(_ranks[i + 1]) + 4;
                    }
                }
                if (_ranks[i] > _ranks[i + 1] + 1) {
                    streetChecker = 1;
                }
            }
            // Check for 4oaK
            if (valuesMatch[_ranks[i]] == 4 && strongestHand < 7) {
                strongestHand = 7;
                retOrder[0] = int8(_ranks[i]);
                break;
                // Check for 3oaK
            } else if (valuesMatch[_ranks[i]] == 3 && strongestHand < 3) {
                strongestHand = 3;
                retOrder[0] = int8(_ranks[i]);
            } else if (valuesMatch[_ranks[i]] == 2) {
                if (pairs[0] == -1) {
                    pairs[0] = int8(_ranks[i]);
                } else if (pairs[1] == -1) {
                    pairs[1] = int8(_ranks[i]);
                }
            }
            suits[(_cards[i] / 13)]++;
        }

        if (strongestHand == 7) {
            for (i = 0; i < 7; i++) {
                // Find kicker
                if (int8(_ranks[i]) != retOrder[0]) {
                    retOrder[1] = int8(_ranks[i]);
                    return (strongestHand, retOrder);
                }
            }
        }

        // Check for flush
        if (strongestHand < 5) {
            for (i = 0; i < 4; i++) {
                if (suits[i] >= 5) {
                    flushWinSuit = i;
                    uint8 cnt = 0;
                    for (i = 0; i < 7; i++) {
                        if (_cards[i] / 13 == flushWinSuit) {
                            streetFlushCards[cnt] = int8(_ranks[i]);
                            retOrder[cnt] = int8(_ranks[i]);
                            cnt++;
                            retOrder[6] = 50;
                        }
                    }
                    if (strongestHand == 4) {
                        for (i = 0; i < 3; i++) {
                            if (
                                streetFlushCards[i] - streetFlushCards[i + 4] ==
                                4 &&
                                streetFlushCards[i + 4] != -1
                            ) {
                                strongestHand = 8;
                                retOrder = [
                                    int8(streetFlushCards[i]),
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1,
                                    -1
                                ];
                                if (streetFlushCards[i] == 12) {
                                    strongestHand = 9;
                                }
                                return (strongestHand, retOrder);
                            }
                        }
                    }
                    strongestHand = 5;
                    retOrder[5] = -1;
                    retOrder[6] = -1;
                    return (strongestHand, retOrder);
                }
            }
        }

        if (strongestHand == 3) {
            // Check for full house
            if (pairs[1] > -1) {
                strongestHand = 6;
                if (
                    valuesMatch[uint8(pairs[0])] >= valuesMatch[uint8(pairs[1])]
                ) {
                    retOrder[1] = pairs[1];
                } else {
                    retOrder[1] = pairs[0];
                }
                return (strongestHand, retOrder);
            }
            // Check for 3oaK
            for (i = 0; i < 5; i++) {
                // Find kickers
                if (int8(_ranks[i]) != retOrder[0]) {
                    retOrder[i + 1] = int8(_ranks[i]);
                    if (retOrder[2] != -1) break;
                }
            }
            return (strongestHand, retOrder);
        }

        if (strongestHand < 3) {
            // Two pairs
            if (pairs[1] != -1) {
                strongestHand = 2;
                if (pairs[0] > pairs[1]) {
                    retOrder[0] = pairs[0];
                    retOrder[1] = pairs[1];
                } else {
                    retOrder[0] = pairs[1];
                    retOrder[1] = pairs[0];
                }
                for (i = 0; i < 7; i++) {
                    if (
                        int8(_ranks[i]) != pairs[0] &&
                        int8(_ranks[i]) != pairs[1]
                    ) {
                        retOrder[2] = int8(_ranks[i]);
                        break;
                    }
                }
                return (strongestHand, retOrder);
            }
            // One pair
            if (pairs[0] != -1) {
                strongestHand = 1;
                retOrder[0] = pairs[0];
                uint8 cnt = 1;
                for (i = 0; i < 7; i++) {
                    if (int8(_ranks[i]) != pairs[0]) {
                        retOrder[cnt] = int8(_ranks[i]);
                        cnt++;
                    }
                    if (retOrder[3] != -1) {
                        return (strongestHand, retOrder);
                    }
                }
            } else {
                strongestHand = 0;
                for (i = 0; i < 5; i++) {
                    retOrder[i] = int8(_ranks[i]);
                }
                return (strongestHand, retOrder);
            }
        }
        return (strongestHand, retOrder);
    }

    /**
     * @notice Determines the winner of the game based on each player's hand
     * @param playerHand Person's hand
     * @param playerKickers Kicker cards of the person
     * @param computerHand Computer's hand
     * @param computerKickers Kicker cards of the computer
     * @return Game result for the *person*: Win, Jackpot, Lose or Draw
     */
    function _getPokerResult(
        uint8 playerHand,
        int8[7] memory playerKickers,
        uint8 computerHand,
        int8[7] memory computerKickers
    ) private pure returns (GameResult) {
        // Player wins
        if (playerHand > computerHand) {
            // Players wins a jackpot
            if (playerHand == 9) {
                return GameResult.Jackpot;
            }
            return GameResult.Win;
        }
        if (playerHand == computerHand) {
            // Use kickers to break ties
            for (uint256 i; i < 7; i++) {
                // Player wins
                if (playerKickers[i] > computerKickers[i]) {
                    return GameResult.Win;
                }
                // Computer wins
                if (playerKickers[i] < computerKickers[i]) {
                    return GameResult.Lose;
                }
            }
            // If even kickers are the same - it's a draw
            return GameResult.Draw;
        }
        // Computer wins
        return GameResult.Lose;
    }

    /**
     * @notice Checks that bet amount is valid
     * @param betValue The amount of tokens at stake
     */
    function _isValidBet(uint256 betValue) internal view {
        uint256 gasFee = _poolController.getOracleGasFee();
        require(
            betValue.mul(1000) > gasFee.mul(1015) && betValue <= _maxBet,
            "Poker: invalid bet amount!"
        );
    }
}
