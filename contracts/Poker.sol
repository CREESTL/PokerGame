pragma solidity >0.4.18 < 0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/lifecycle/Pausable.sol";
import "./Interfaces.sol";
import "./GameController.sol";


contract Poker is GameController {
    using SafeMath for uint256;
    using SafeMath for uint8;

    enum GameResults { Lose, Draw, Win, Jackpot }

    struct Hand {
        uint8[7] ranks;
        uint8[7] cards;
        int8[7] kickers;
        uint8 hand;
    }

    struct Game {
        // uint id;
        uint256 betColor;
        uint256 betPoker;
        uint256 chosenColor;
        address payable player;
    }

    // maxbet calc
    uint256 internal _gamesCounter;
    uint256 internal _betFlip;
    uint256 internal _betColor;
    uint256 internal _betFlipSquare;
    uint256 internal _betColorSquare;
    uint256 internal _betFlipVariance;
    uint256 internal _betColorVariance;
    uint256 internal _maxBet;

    event PokerResult(uint256 winAmount, bool winColor, GameResults winPoker, uint256 requestId, uint256 cards, address player);
    event GameStart(address player, uint256 requestId, uint256 betPoker, uint256 betColor);

    IPool private _poolController;
    mapping(uint256 => Game) private games;

    constructor (address oracleAddress, address poolControllerAddress) public GameController(oracleAddress){
        _setPoolController(poolControllerAddress);
        // pause();
    }

    function getMaxBet() external view returns(uint) {
        return (_maxBet);
    }

    function getPoolController() external view returns(address) {
        return address(_poolController);
    }

    function getGameInfo(uint256 requestId) external view returns (uint, uint, uint, address) {
        return (
            games[requestId].betColor,
            games[requestId].betPoker,
            games[requestId].chosenColor,
            games[requestId].player
        );
    }

    function setPoolController(address poolControllerAddress) external onlyOwner {
        _setPoolController(poolControllerAddress);
    }

    // function pauseGame() external onlyOwner {
    //     pause();
    // }

    // function unPauseGame() external onlyOwner {
    //     unpause();
    // }

    function setMaxBet(uint256 maxBet) external onlyOwner {
        _maxBet = maxBet;
    }

    function play(uint256 betColor, uint256 chosenColor) external payable {
        _maxBetCalc(uint256(msg.value.sub(betColor)), betColor);
        uint256 gasFee = _poolController.getOracleGasFee();
        require(msg.value > gasFee.mul(1015).div(1000), 'Bet too small');
        require(msg.value < _maxBet, 'Bet too big');
        address payable player = msg.sender;
        uint256 betPoker = uint256(msg.value.sub(betColor));
        _poolController.addBetToPool(msg.value);
        // if (_randomNumbers[_lastRequestId].status != Status.Pending) {
        super._updateRandomNumber();
        // }
        emit GameStart(player, _lastRequestId, betPoker, betColor);
        games[_lastRequestId] = Game(
            betColor,
            betPoker,
            chosenColor,
            player);
    }

    function getLastGamePlayer() external view returns(address) {
        return games[_lastRequestId].player;
    }

    function _publishResults(uint8[] memory cards, uint256 requestId, uint256 bitCards) internal {
        uint256 winAmount = 0;
        uint256 jackPotAdder = games[requestId].betPoker.div(1000).mul(2);
        uint256 betColorEdge = games[requestId].betColor.div(1000).mul(15);
        uint256 betPokerEdge = games[requestId].betColor.div(1000).mul(15);
        bool colorWin = false;
        _poolController.updateJackpot(jackPotAdder);
        // _maxBetCalc(games[requestId].betPoker, games[requestId].betColor);
        if (games[requestId].betColor > 0) {
            uint8[] memory colorCards = new uint8[](3);
            for (uint256 i = 2; i < 5; i++) {
                colorCards[i - 2] = cards[i];
            }
            if (_determineWinnerColor(colorCards, games[requestId].chosenColor)) {
                winAmount = games[requestId].betColor.mul(2).sub(betColorEdge);
                colorWin = true;
            }
        }
        GameResults winPoker = _setCards(cards);

        if (winPoker == GameResults.Draw) {
            winAmount = winAmount.add(games[requestId].betPoker.sub(betPokerEdge + jackPotAdder));
        } else if (winPoker == GameResults.Win) {
            winAmount = winAmount.add(games[requestId].betPoker.mul(2).sub(betPokerEdge + jackPotAdder));
        } else if (winPoker == GameResults.Jackpot) {
            _poolController.jackpotDistribution(games[requestId].player);
        }

        if (winAmount > 0) {
            _poolController.rewardDisribution(games[requestId].player, winAmount);
            _poolController.updateReferralTotalWinnings(games[requestId].player, winAmount); // TODO: refactor updateReferralTotalWinnings and updateReferralEarningsBalance to one function
            _poolController.updateReferralEarningsBalance(games[requestId].player, (betColorEdge.add(betPokerEdge)).div(100));
        }
        emit PokerResult(winAmount, colorWin, winPoker, requestId, bitCards, games[requestId].player);
    }

    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(poolCandidate.supportsIPool(), "poolAddress must be IPool");
        _poolController = poolCandidate;
    }

    function _setCards(uint8[] memory _cardsArray) private pure returns(GameResults) {
        Hand memory player;
        Hand memory computer;
        for (uint256 i = 0; i < _cardsArray.length; i++) {
            if (i < 7) { // player cards 0 - 6
                player.cards[i] = _cardsArray[i];
                player.ranks[i] = _cardsArray[i] % 13;
            }
            if (i > 1) { // computer cards 2 - 8
                computer.cards[i - 2] = _cardsArray[i];
                computer.ranks[i - 2] = _cardsArray[i] % 13;
            }
        }
        _sort(player.ranks, player.cards, 0, 6);
        _sort(computer.ranks, computer.cards, 0, 6);
        (player.hand, player.kickers) = _evaluateHand(player.cards, player.ranks);
        (computer.hand, computer.kickers) = _evaluateHand(computer.cards, computer.ranks);
        return _determineWinnerPoker(
            player.hand,
            player.kickers,
            computer.hand,
            computer.kickers);
    }

    function _sort(
        uint8[7] memory dataRanks,
        uint8[7] memory dataCards,
        uint256 low,
        uint256 high) private pure
    {
        if (low < high) {
            uint256 pivotVal = dataRanks[(low + high) / 2];
            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (dataRanks[low1] > pivotVal) low1++;
                while (dataRanks[high1] < pivotVal) high1--;
                if (low1 >= high1) break;
                (dataRanks[low1], dataRanks[high1]) = (dataRanks[high1], dataRanks[low1]);
                (dataCards[low1], dataCards[high1]) = (dataCards[high1], dataCards[low1]);
                low1++;
                high1--;
            }
            if (low < high1) _sort(dataRanks,dataCards, low, high1);
            high1++;
            if (high1 < high) _sort(dataRanks,dataCards, high1, high);
        }
    }

    function _determineWinnerPoker(
        uint8 playerHand,
        int8[7] memory playerKickers,
        uint8 computerHand,
        int8[7] memory computerKickers
    ) private pure returns (GameResults)
    {
        if (playerHand > computerHand) {
            if (playerHand == 9) return GameResults.Jackpot;
            return GameResults.Win;
        }
        if (playerHand == computerHand) {
            for (uint256 i = 0; i < 7; i++) {
                if (playerKickers[i] > computerKickers[i]) return GameResults.Win;
                if (playerKickers[i] < computerKickers[i]) return GameResults.Lose;
            }
            return GameResults.Draw;
        }
        return GameResults.Lose;
    }

    function _determineWinnerColor(uint8[] memory colorCards, uint256 chosenColor) private pure returns (bool) {
        uint256 colorCounter = 0;
        for (uint256 i = 0; i < colorCards.length; i++) {
            if ((colorCards[i] / 13) % 2 == chosenColor) {
                colorCounter++;
            }
            if (colorCounter >= 2) return true;
        }
        return false;
    }

    function _evaluateHand(uint8[7] memory cardsArray, uint8[7] memory ranksArray) private pure returns (uint8, int8[7] memory) {
        uint8 strongestHand = 0;
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
                    retOrder[1] = int8(ranksArray[0]);
                    return (strongestHand, retOrder);
                }
            }
        }

        // check for flush
        if (strongestHand < 5) {
            for (i = 0; i < 4; i++) {
                if (suits[i] >= 5) {
                    if (strongestHand == 4) {
                        if (suits[i] == 5) {
                            flushWinSuit = i;
                        }
                        uint8 cnt = 0;
                        for (i = 0; i < 7; i++) {
                            if (cardsArray[i] / 13 == flushWinSuit) {
                                streetFlushCards[cnt] = int8(ranksArray[i]);
                                retOrder[cnt] = int8(ranksArray[i]);
                                cnt++;
                            }
                            if (i >= 5) {
                                if (streetFlushCards[i - 5] - streetFlushCards[i - 1] == 4) {
                                    strongestHand = 8;
                                    retOrder = [int8(streetFlushCards[i - 5]), -1, -1, -1, -1, -1, -1];
                                    if (streetFlushCards[i - 5] == 12) {
                                        strongestHand = 9;
                                    }
                                    return (strongestHand, retOrder);
                                }
                            }
                        }
                    }
                    strongestHand = 5;
                    break;
                }
            }
        }

        if (strongestHand == 3) {
            // check for full house
            if (pairs[1] > -1) {
                strongestHand = 6;
                if (valuesMatch[uint256(pairs[0])] >= valuesMatch[uint256(pairs[1])]) {
                    retOrder[0] = pairs[0];
                    retOrder[1] = pairs[1];
                } else {
                    retOrder[0] = pairs[1];
                    retOrder[1] = pairs[0];
                }
                return (strongestHand, retOrder);
            }
            // check for 3oaK
            for (i = 0; i < 5; i++) {
                // find kickers
                if (int8(ranksArray[i]) != retOrder[0]) {
                    if (int8(ranksArray[i]) > retOrder[1]) {
                        retOrder[2] = retOrder[1];
                        retOrder[1] = int8(ranksArray[i]);
                        // TODO: problem when 3oak rank is lower than kickers
                    } else {
                        retOrder[2] = int8(ranksArray[i]);
                    }
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
                    if (int8(ranksArray[i]) != pairs[0] && int8(ranksArray[i]) != pairs[1]) {
                        retOrder[2] = int8(ranksArray[i]);
                        break;
                    }
                }
                return (strongestHand, retOrder);
                // one pair
            } else {
                strongestHand = 1;
                retOrder[0] = pairs[0];
                uint8 cnt = (pairs[0] == -1) ? 0 : 1;
                for (i = 0; i < 7; i++) {
                    if (int8(ranksArray[i]) != pairs[0]) {
                        retOrder[cnt] = int8(ranksArray[i]);
                        cnt++;
                    }
                }
                // no pairs
                if (pairs[0] == -1) {
                    strongestHand = 0;
                }
                return (strongestHand, retOrder);
            }
        }
        return (strongestHand, retOrder);
    }

    function _maxBetCalc(uint pokerB, uint colorB) internal {
        uint256 poolAmount = _poolController.getPoolAmount();
        _gamesCounter = _gamesCounter.add(1);
        if (_gamesCounter == 1) {
            if (_maxBet == 0) _maxBet = poolAmount.div(230);
            _betFlip = pokerB;
            _betColor = colorB;
            _betFlipSquare = pokerB.mul(pokerB);
            _betColorSquare = colorB.mul(colorB);
        }
        if (_gamesCounter > 1) {
            _betFlip = ((_gamesCounter - 1).mul(_betFlip).add(pokerB)).div(_gamesCounter);
            _betColor = ((_gamesCounter - 1).mul(_betColor).add(colorB)).div(_gamesCounter);
            _betFlipSquare = ((_gamesCounter - 1).mul(_betFlipSquare ).add(pokerB.mul(pokerB))).div(_gamesCounter);
            _betColorSquare = ((_gamesCounter - 1).mul(_betColorSquare ).add(colorB.mul(colorB))).div(_gamesCounter);
            _betFlipVariance = _betFlipSquare - _betFlip.mul(_betFlip);
            _betColorVariance = _betColorSquare - _betColor.mul(_betColor);
            uint Fn = _betFlip.add(sqrt(_betFlipVariance).mul(10));
            uint Cn = _betColor.add(sqrt(_betColorVariance).mul(10));
            if (_gamesCounter > 100 && Fn < poolAmount.div(230) && Cn < poolAmount.div(230)) {
                if (Fn > Cn) {
                    _maxBet = _maxBet.mul(_maxBet).div(Fn);
                } else {
                    _maxBet = _maxBet.mul(_maxBet).div(Cn);
                }
                _gamesCounter = 0;
                if (_maxBet > poolAmount.div(109)) _maxBet = poolAmount.div(109);
                else if (_maxBet < poolAmount.div(230)) _maxBet = poolAmount.div(230);
            }
        }
    }

    function sqrt(uint x) private pure returns (uint y) { // TODO: move Poker contract
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}