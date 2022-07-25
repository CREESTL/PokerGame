// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces.sol";
import "./GameController.sol";
import "./libraries/CheapMath.sol";


contract Poker is GameController {
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint8;

    enum GameResults { Lose, Draw, Win, Jackpot }
    
    uint256 public _maxBet;
    address public _operator;

    struct Hand {
        uint8[7] ranks;
        uint8[7] cards;
        int8[7] kickers;
        uint8 hand;
    }

    struct Game {
        uint128 betColor;
        uint128 betPoker;
        uint128 winAmount;
        uint128 refAmount;
        address payable player;
        uint8 chosenColor;
        bool isWinAmountClaimed;
        bool isJackpot;
    }

    uint256 public houseEdge;
    uint256 public jackpotFeeMultiplier;

    event PokerResult(uint256 winAmount, bool winColor, GameResults winPoker, uint256 requestId, uint256 cards, address player);
    event GameStart(uint256 requestId);
    event WinAmountClaimed(uint256 requestId);

    IPool private _poolController;
    mapping(uint256 => Game) public games;

    modifier onlyOperator() {
        require(msg.sender == _operator, "p: not operator");
        _;
    }

    constructor (address oracleAddress, address poolControllerAddress, address operator) GameController(oracleAddress){
        _setPoolController(poolControllerAddress);
        houseEdge = 15;
        jackpotFeeMultiplier = 2;
        _operator = operator;
    }

    function setPoolController(address poolControllerAddress) external onlyOwner {
        _setPoolController(poolControllerAddress);
    }

    function setOperator(address operator) external onlyOwner {
        _operator = operator;
    }

    function getPoolController() external view returns(address){
        return address(_poolController);
    }

    function setMaxBet(uint256 maxBet) external onlyOperator {
        _maxBet = maxBet;
    }

    function setHouseEdge(uint256 _houseEdge) external onlyOwner {
        houseEdge = _houseEdge;
    }

    function setJackpotFeeMultiplier(uint256 _jackpotFeeMultiplier) external onlyOwner {
        jackpotFeeMultiplier = _jackpotFeeMultiplier;
    }
    
    function setGameResult(uint256 requestid, uint128 winAmount, uint128 refAmount, bool isJackpot, uint64 bitCards) external onlyOperator {
        games[requestid].winAmount = winAmount;
        games[requestid].refAmount = refAmount;
        games[requestid].isJackpot = isJackpot;
        __callback(bitCards, requestid);
    }

    function sendFundsToPool() external onlyOperator {
        _poolController.receiveFundsFromGame{value: address(this).balance}();
    }
    
    function claimWinAmount(uint256 requestId) external {
        require(games[requestId].player == _msgSender()
            && (games[requestId].winAmount > 0 || games[requestId].refAmount > 0)
            && !games[requestId].isWinAmountClaimed, 'p: not valid claim');
        address payable player = games[requestId].player;
        uint256 winAmount = games[requestId].winAmount;
        uint256 refAmount = games[requestId].refAmount;

        if (games[requestId].isJackpot) {
            _poolController.jackpotDistribution(player, winAmount);
        } else {
            _poolController.rewardDisribution(player, winAmount);
        }

        games[requestId].isWinAmountClaimed = true;

        _poolController.updateReferralStats(player, winAmount, refAmount);
        
        emit WinAmountClaimed(requestId);
    }

    function play(uint256 betColor, uint256 chosenColor) external payable {
        uint256 msgValue = msg.value;
        uint256 betPoker = msgValue.sub(betColor);

        _isValidBet(msgValue);
        
        address payable player = payable(_msgSender());
        _poolController.addBetToPool(msgValue);
        _poolController.updateJackpot(betPoker.mul(jackpotFeeMultiplier).div(1000));
        
        super._updateRandomNumber();

        Game storage game = games[_lastRequestId];
        game.betColor = uint128(betColor);
        game.betPoker = uint128(betPoker);
        if (chosenColor > 0) {
            game.chosenColor = uint8(chosenColor);
        }
        game.player = player;

        emit GameStart(_lastRequestId);
    }

    function calculateWinAmount(uint256 requestId, GameResults winPoker, bool winColor) external view returns(uint256, uint256, uint256) {
        uint256 winPokerAmount;
        uint256 winColorAmount;

        uint256 betPoker = games[requestId].betPoker;
        uint256 betColor = games[requestId].betColor;

        uint256 betPokerEdge = betPoker.mul(houseEdge).div(1000);
        uint256 betColorEdge;

        uint256 jackPotAdder = betPoker.mul(jackpotFeeMultiplier).div(1000);

        uint256 referralBonus;

        if (winColor) {
            betColorEdge = betColor.mul(houseEdge).div(1000);
            referralBonus = referralBonus.add(betColorEdge);
            winColorAmount = betColor.mul(jackpotFeeMultiplier).sub(betColorEdge);
        }

        if (winPoker == GameResults.Draw) {
            winPokerAmount = winPokerAmount.add(betPoker.sub(betPokerEdge + jackPotAdder));
        }

        if (winPoker == GameResults.Win) {
            referralBonus = referralBonus.add(betPokerEdge);
            winPokerAmount = winPokerAmount.add(betPoker.mul(2).sub(betPokerEdge + jackPotAdder));
        }

        if (winPoker == GameResults.Jackpot) {
            winPokerAmount = winPokerAmount.add(_poolController.jackpot());
        }

        return (winPokerAmount, winColorAmount, referralBonus);
    }

    function getPokerResult(uint8[] memory _cardsArray) public pure returns(GameResults) {
        Hand memory player;
        Hand memory computer;
        for (uint256 i; i < _cardsArray.length; i++) {
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
            computer.kickers
        );
    }

    function getColorResult(uint256 requestId, uint8[] memory colorCards) public view returns (bool) {
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

    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(poolCandidate.supportsIPool(), "p: poolAddress not IPool");
        _poolController = poolCandidate;
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
            for (uint256 i; i < 7; i++) {
                if (playerKickers[i] > computerKickers[i]) return GameResults.Win;
                if (playerKickers[i] < computerKickers[i]) return GameResults.Lose;
            }
            return GameResults.Draw;
        }
        return GameResults.Lose;
    }

    function _evaluateHand(uint8[7] memory cardsArray, uint8[7] memory ranksArray) private pure returns (uint8, int8[7] memory) {
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
                            if (streetFlushCards[i] - streetFlushCards[i + 4] == 4 && streetFlushCards[i + 4] != -1) {
                                strongestHand = 8;
                                retOrder = [int8(streetFlushCards[i]), -1, -1, -1, -1, -1, -1];
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
                if (valuesMatch[uint256(uint8(pairs[0]))] >= valuesMatch[uint256(uint8(pairs[1]))]) {
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
                    if(retOrder[2] != -1) break;
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
        require(betValue.mul(1000) > gasFee.mul(1015) && betValue <= _maxBet, 'p: bad bet');
    }
}