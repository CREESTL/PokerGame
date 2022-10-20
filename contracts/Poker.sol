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
        uint8[7] ranks;
        uint8[7] cards;
        int8[7] kickers;
        uint8 hand;
    }

    /**
     * @dev Game from the point of view of a single player
     *      If 2 players take part in one game round, each of them
     *      has his own {Game} 
     */
    struct Game {
        uint128 betColor;
        uint128 betPoker;
        uint256 winAmount;
        uint128 refAmount;
        address payable player;
        uint8 chosenColor;
        bool isWinAmountClaimed;
        bool isJackpot;
    }

    // TODO search in docs
    uint256 public houseEdge;
    /**
     * @dev Bet amount gets multiplied by {jackpotFeeMultiplier} 
     *      if a player wins a jackpot
     */
    uint256 public jackpotFeeMultiplier;

    /**
     * @dev Indicates that the game has started
     */
    event GameStart(uint256 requestId);

    /**
     * TODO not used
     * @dev Indicates that the game has finished
     *      Shows the result of a single game
     */
    event GameFinished(
        uint256 winAmount,
        bool winColor,
        GameResult result,
        uint256 requestId,
        uint256 cards,
        address player
    );

    /**
     * @dev Indicates that someone claimed the amount he won
     */
    event WinAmountClaimed(uint256 requestId);

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
        // TODO percent???
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
     * // TODO add checks for zero address here and in other places
     */
    function setPoolController(address poolControllerAddress)
        external
        onlyOwner
    {
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
     * // TODO what is house edge?
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
    function setJackpotFeeMultiplier(uint256 _jackpotFeeMultiplier)
        external
        onlyOwner
    {
        jackpotFeeMultiplier = _jackpotFeeMultiplier;
    }

    /**
     * @notice Called by the backend to set the game result
     * // TODO Rename it to `gameId`???
     * @param requestId ????
     * @param winAmount The amount that will be given to the winner
     * // TODO or is it a referal program amount???
     * @param refAmount The amount that will be given to the referee
     * @param isJackpot True if one of the players won a jackpot
     * // TODO bit = past tense of bet?
     * @param bitCards ????
     */
    function setGameResult(
        uint256 requestId,
        uint256 winAmount,
        uint128 refAmount,
        bool isJackpot,
        uint64 bitCards
    ) external onlyOperator {
        // Values from backend are assigned to the game
        games[requestId].winAmount = winAmount;
        games[requestId].refAmount = refAmount;
        games[requestId].isJackpot = isJackpot;

        if (isJackpot) {
            require(
                winAmount <= _poolController.jackpotLimit(),
                "Poker: jackpot is greater than limit!"
            );
            require(
                winAmount <= _poolController.totalJackpot(),
                "Poker: not enough funds for jackpot!"
            );
            // TODO freeze jackpot???
            _poolController.freezeJackpot(winAmount);
        }

        // Finish work with current game request
        _closeRequest(bitCards, requestId);
    }

    /**
     * @notice Sends tokens from the game to the pool controller
     */
    function sendFundsToPool() external onlyOperator {
        _poolController.receiveFundsFromGame{value: address(this).balance}();
    }

    /**
     * @notice Allows player to claim tokens he won in the game
     * @param requestId The ID of the game request
     */
    function claimWinAmount(uint256 requestId) external {
        require(
            games[requestId].player == _msgSender(),
            "Poker: caller is not a player!"
        );
        // Either player of referee should win.
        require(
            games[requestId].winAmount > 0 || games[requestId].refAmount > 0,
            "Poker: Invalid Amount!"
        );
        require(
            !games[requestId].isWinAmountClaimed,
            "p: win already claimed!"
        );
        /
        address payable player = games[requestId].player;
        uint256 winAmount = games[requestId].winAmount;
        uint256 refAmount = games[requestId].refAmount;

        // Mark that this game win amount was claimed
        games[requestId].isWinAmountClaimed = true;

        // TODO comment on this...
        _poolController.updateReferralStats(player, winAmount, refAmount);

        if (games[requestId].isJackpot) {
            // If a player won a jackpot, disctribute tokens in one way
            _poolController.jackpotDistribution(player, winAmount);
        } else {
            // If a player simply won (no jackpot), distribute tokens in another way
            _poolController.rewardDistribution(player, winAmount);
        }

        emit WinAmountClaimed(requestId);
    }

    /**
     * @notice User pays tokens, makes bets and starts a game
     * @param betColor The color a player thinks will be dominant in the flop cards 
     * TODO what's the difference between betColor and chosenColor???
     * @chosenColor The color a player chose at first???
     */
    function play(uint256 betColor, uint256 chosenColor) external payable {
        uint256 msgValue = msg.value;

        // What's left of players tokens after he bet on the color
        uint256 betPoker = msgValue.sub(betColor);

        // Check that the bet is valid
        _isValidBet(msgValue);

        // Tokens from each bet get added to the total pool
        _poolController.addBetToPool(msgValue);
        // Jackpot amount gets calculated based on player's bet 
        _poolController.updateJackpot(
            // TODO why divide by 1000?
            betPoker.mul(jackpotFeeMultiplier).div(1000)
        );

        // Create a new request for a random number
        // This updates {_lastRequestId}
        super._updateRandomRequest();

        address payable player = payable(_msgSender());

        // Get a random game from all games
        // It is "empty" at first
        Game storage game = games[_lastRequestId];
        // Initialize it with new values
        game.betColor = uint128(betColor);
        game.betPoker = uint128(betPoker);
        if (chosenColor > 0) {
            game.chosenColor = uint8(chosenColor);
        }
        game.player = player;

        emit GameStart(_lastRequestId);
    }

    /**
     * @notice Calculates the amount of tokens to be payed for:
     *         - Poker win
     *         - Color bet win
     *         - Referral program membership
     * TODO maybe random number request???
     * @param requestId The ID of the game request
     * @param result The result of the game with the provided ID
     * @param winColor True if a player won a color bet. False - if he lost
     */
    function calculateWinAmount(
        uint256 requestId,
        GameResult result,
        bool winColor
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {   
        // How many tokens to pay to the winner of poker game
        uint256 winPokerAmount;
        // How many tokens to pay to the winner of color bet
        // Can be summed with {winPokerAmount}
        uint256 winColorAmount;
        // Tokens to pay for referral program membership
        uint256 referralBonus;

        // Retrive info about the game using the game ID
        uint256 betPoker = games[requestId].betPoker;
        uint256 betColor = games[requestId].betColor;

        // TODO what is edge??? why divide by 1000???
        uint256 betPokerEdge = betPoker.mul(houseEdge).div(1000);
        uint256 betColorEdge;

        // TODO what's that for?
        uint256 jackPotAdder = betPoker.mul(jackpotFeeMultiplier).div(1000);

        // User won a color bet
        if (winColor) {
            betColorEdge = betColor.mul(houseEdge).div(1000);
            referralBonus = referralBonus.add(betColorEdge);
            winColorAmount = betColor.mul(jackpotFeeMultiplier).sub(
                betColorEdge
            );
        }

        // None of the players won
        if (result == GameResult.Draw) {
            winPokerAmount = betPoker.sub(betPokerEdge + jackPotAdder);
        }

        // User won a game
        if (result == GameResult.Win) {
            referralBonus = referralBonus.add(betPokerEdge);
            // TODO why multiply only by 2, not {jackpotFeeMultiplier}
            winPokerAmount = betPoker.mul(2).sub(betPokerEdge + jackPotAdder);
        }

        // User won and it's a jackpot
        if (result == GameResult.Jackpot) {
            winPokerAmount = _poolController.jackpot() <=
                _poolController.jackpotLimit()
                ? _poolController.jackpot()
                : _poolController.jackpotLimit();
        }

        return (winPokerAmount, winColorAmount, referralBonus);
    }

    
    function getPokerResult(uint8[] memory _cardsArray)
        public
        pure
        returns (GameResult)
    {
        Hand memory player;
        Hand memory computer;
        for (uint256 i; i < _cardsArray.length; i++) {
            if (i < 7) {
                // player cards 0 - 6
                player.cards[i] = _cardsArray[i];
                player.ranks[i] = _cardsArray[i] % 13;
            }
            if (i > 1) {
                // computer cards 2 - 8
                computer.cards[i - 2] = _cardsArray[i];
                computer.ranks[i - 2] = _cardsArray[i] % 13;
            }
        }
        _sort(player.ranks, player.cards, 0, 6);
        _sort(computer.ranks, computer.cards, 0, 6);
        (player.hand, player.kickers) = _evaluateHand(
            player.cards,
            player.ranks
        );
        (computer.hand, computer.kickers) = _evaluateHand(
            computer.cards,
            computer.ranks
        );
        return
            _determineWinnerPoker(
                player.hand,
                player.kickers,
                computer.hand,
                computer.kickers
            );
    }

    function getColorResult(uint256 requestId, uint8[] memory colorCards)
        public
        view
        returns (bool)
    {
        uint256 colorCounter;
        uint256 chosenColor = games[requestId].chosenColor;
        for (uint256 i; i < colorCards.length; i++) {
            if ((colorCards[i] / 13) % 2 == chosenColor) {
                colorCounter++;
            }
            if (colorCounter >= 2) return true;
        }
        return false;
    }

    /**
     * @notice Changes the address of the pool controller
     *         See {setPoolController}
     */
    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(
            poolCandidate.supportsIPool(),
            "p: Contract with poolAddress Does Not Implement IPool Interface!"
        );
        _poolController = poolCandidate;
    }

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

    function _determineWinnerPoker(
        uint8 playerHand,
        int8[7] memory playerKickers,
        uint8 computerHand,
        int8[7] memory computerKickers
    ) private pure returns (GameResult) {
        if (playerHand > computerHand) {
            if (playerHand == 9) return GameResult.Jackpot;
            return GameResult.Win;
        }
        if (playerHand == computerHand) {
            for (uint256 i; i < 7; i++) {
                if (playerKickers[i] > computerKickers[i])
                    return GameResult.Win;
                if (playerKickers[i] < computerKickers[i])
                    return GameResult.Lose;
            }
            return GameResult.Draw;
        }
        return GameResult.Lose;
    }

    function _evaluateHand(
        uint8[7] memory cardsArray,
        uint8[7] memory ranksArray
    ) private pure returns (uint8, int8[7] memory) {
        uint8 strongestHand;
        // get kickers
        int8[7] memory retOrder = [-1, -1, -1, -1, -1, -1, -1];
        // check for flush
        uint8[4] memory suits = [0, 0, 0, 0];
        // check for pairs, 3oaK, 4oaK
        uint8[13] memory valuesMatch = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // for loop
        uint256 i;
        // write pairs and triples, triple always 1st
        int8[2] memory pairs = [-1, -1];
        uint256 streetChecker = 1;
        // check for street flush
        uint256 flushWinSuit;
        int8[7] memory streetFlushCards = [-1, -1, -1, -1, -1, -1, -1];

        for (i = 0; i < 7; i++) {
            valuesMatch[ranksArray[i]]++;
            // check for street
            if (i < 6) {
                if (ranksArray[i] == ranksArray[i + 1] + 1) {
                    streetChecker++;
                    if (streetChecker == 5) {
                        strongestHand = 4;
                        retOrder[0] = int8(ranksArray[i + 1]) + 4;
                    }
                }
                if (ranksArray[i] > ranksArray[i + 1] + 1) {
                    streetChecker = 1;
                }
            }
            // check for 4oaK
            if (valuesMatch[ranksArray[i]] == 4 && strongestHand < 7) {
                strongestHand = 7;
                retOrder[0] = int8(ranksArray[i]);
                break;
                // check for 3oaK
            } else if (valuesMatch[ranksArray[i]] == 3 && strongestHand < 3) {
                strongestHand = 3;
                retOrder[0] = int8(ranksArray[i]);
            } else if (valuesMatch[ranksArray[i]] == 2) {
                if (pairs[0] == -1) {
                    pairs[0] = int8(ranksArray[i]);
                } else if (pairs[1] == -1) {
                    pairs[1] = int8(ranksArray[i]);
                }
            }
            suits[(cardsArray[i] / 13)]++;
        }

        if (strongestHand == 7) {
            for (i = 0; i < 7; i++) {
                // find kicker
                if (int8(ranksArray[i]) != retOrder[0]) {
                    retOrder[1] = int8(ranksArray[i]);
                    return (strongestHand, retOrder);
                }
            }
        }

        // check for flush
        if (strongestHand < 5) {
            for (i = 0; i < 4; i++) {
                if (suits[i] >= 5) {
                    flushWinSuit = i;
                    uint8 cnt = 0;
                    for (i = 0; i < 7; i++) {
                        if (cardsArray[i] / 13 == flushWinSuit) {
                            streetFlushCards[cnt] = int8(ranksArray[i]);
                            retOrder[cnt] = int8(ranksArray[i]);
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
            // check for full house
            if (pairs[1] > -1) {
                strongestHand = 6;
                if (
                    valuesMatch[uint8(pairs[0])] >= valuesMatch[uint8(pairs[1])]
                ) {
                    // retOrder[0] = pairs[0];
                    retOrder[1] = pairs[1];
                } else {
                    // retOrder[0] = pairs[1];
                    retOrder[1] = pairs[0];
                }
                return (strongestHand, retOrder);
            }
            // check for 3oaK
            for (i = 0; i < 5; i++) {
                // find kickers
                if (int8(ranksArray[i]) != retOrder[0]) {
                    retOrder[i + 1] = int8(ranksArray[i]);
                    if (retOrder[2] != -1) break;
                }
            }
            return (strongestHand, retOrder);
        }

        if (strongestHand < 3) {
            // two pairs
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
                        int8(ranksArray[i]) != pairs[0] &&
                        int8(ranksArray[i]) != pairs[1]
                    ) {
                        retOrder[2] = int8(ranksArray[i]);
                        break;
                    }
                }
                return (strongestHand, retOrder);
            }
            // one pair
            if (pairs[0] != -1) {
                strongestHand = 1;
                retOrder[0] = pairs[0];
                uint8 cnt = 1;
                for (i = 0; i < 7; i++) {
                    if (int8(ranksArray[i]) != pairs[0]) {
                        retOrder[cnt] = int8(ranksArray[i]);
                        cnt++;
                    }
                    if (retOrder[3] != -1) {
                        return (strongestHand, retOrder);
                    }
                }
            } else {
                strongestHand = 0;
                for (i = 0; i < 5; i++) {
                    retOrder[i] = int8(ranksArray[i]);
                }
                return (strongestHand, retOrder);
            }
        }
        return (strongestHand, retOrder);
    }

    function _isValidBet(uint256 betValue) internal view {
        uint256 gasFee = _poolController.getOracleGasFee();
        require(
            betValue.mul(1000) > gasFee.mul(1015) && betValue <= _maxBet,
            "p: Bet Is Invalid!"
        );
    }
}
