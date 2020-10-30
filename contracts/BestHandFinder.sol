pragma solidity >0.4.18 < 0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GameController.sol";

contract BestHandFinder is GameController{
    using SafeMath for uint256;
    using SafeMath for uint8;

    struct Hand {
        uint8[7] ranks;
        uint8[7] cards;
        int8[7] kickers;
        uint8 hand;
        
    }

    constructor (address oracleAddress) public GameController(oracleAddress){
    }

    function setCards(uint8[] memory _cardsArray) public pure returns(uint8) {
        Hand memory player;
        Hand memory computer;

        uint8 win;

        uint8 playerCnt = 0;
        uint8 computerCnt = 0;

        for( uint8 i = 0; i < _cardsArray.length; i++) {
            if(i < 7) {
                player.cards[playerCnt] = _cardsArray[i];
                player.ranks[playerCnt] = _cardsArray[i] % 13;
                playerCnt++;
            }
            if(i > 1) {
                computer.cards[computerCnt] = _cardsArray[i];
                computer.ranks[computerCnt] = _cardsArray[i] % 13;
                computerCnt++;
            }
        }

        sort(player.ranks, player.cards, 0, 6);
        sort(computer.ranks, computer.cards, 0, 6);

        (player.hand ,player.kickers) = evaluateHand(player.cards, player.ranks);
        (computer.hand ,computer.kickers) = evaluateHand(computer.cards, computer.ranks);

        win = determineWinner(player.hand ,player.kickers, computer.hand, computer.kickers);
        return win;      
    }

    function sort(uint8[7] memory dataRanks, uint8[7] memory dataCards,uint low, uint high) pure internal {
        if (low < high) {
            uint pivotVal = dataRanks[(low + high) / 2];
        
            uint low1 = low;
            uint high1 = high;
            for (;;) {
                while (dataRanks[low1] > pivotVal) low1++;
                while (dataRanks[high1] < pivotVal) high1--;
                if (low1 >= high1) break;
                (dataRanks[low1], dataRanks[high1]) = (dataRanks[high1], dataRanks[low1]);
                (dataCards[low1], dataCards[high1]) = (dataCards[high1], dataCards[low1]);
                low1++;
                high1--;
            }
            if (low < high1) sort(dataRanks,dataCards, low, high1);
            high1++;
            if (high1 < high) sort(dataRanks,dataCards, high1, high);
        }
    }

    function determineWinner(
        uint8 playerHand, int8[7] memory playerKickers, uint8 computerHand, int8[7] memory computerKickers
        ) public pure returns (uint8){
        uint8 i;
        if (playerHand > computerHand) return 2;
        if (playerHand == computerHand) {
            for(i = 0; i < 7; i++) {
                if (playerKickers[i] > computerKickers[i]) return 2;
                if (playerKickers[i] < computerKickers[i]) return 0;
            }
            return 1;
        }
        return 0;
    }
    
    function evaluateHand(uint8[7] memory cardsArray, uint8[7] memory ranksArray) public pure returns(uint8, int8[7] memory) {
        uint8 strongestHand = 0;
        // get kickers
        int8[7] memory retOrder = [-1, -1, -1, -1, -1, -1, -1];
        // check for flush
        uint8[4] memory suits = [0, 0, 0, 0];
        // check for pairs, 3oaK, 4oaK
        uint8[13] memory valuesMatch = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // for loop
        uint8 i;
        // write pairs and triples, triple always 1st
        int8[2] memory pairs = [-1, -1];
        
        uint8 streetChecker = 1;
        // check for street flush
        uint8 flushWinSuit;
        int8[7] memory streetFlushCards = [-1, -1, -1, -1, -1, -1, -1];

        for(i = 0; i < 7; i++) {
            valuesMatch[ranksArray[i]]++;
            // check for street
            if (i < 6) {
                if (ranksArray[i] == ranksArray[i + 1] + 1) {
                    streetChecker++;
                    if (streetChecker == 5) {
                        strongestHand = 4;
                        retOrder[0] = int8(ranksArray[i + 1]) + 4;
                        // return (strongest.hand, retOrder);
                    }
                }
                if(ranksArray[i] > ranksArray[i + 1] + 1) {
                    streetChecker = 1;
                }
            }
            // check for 4oaK
            if(valuesMatch[ranksArray[i]] == 4 && strongestHand < 7) {
                strongestHand = 7;
                retOrder[0] = int8(ranksArray[i]);
                break;
                // check for 3oaK
            } else if (valuesMatch[ranksArray[i]] == 3 && strongestHand <  3) {
                strongestHand = 3;
                retOrder[0] = int8(ranksArray[i]);
            } else if (valuesMatch[ranksArray[i]] == 2) {
                if (pairs[0] == -1) {
                    pairs[0] = int8(ranksArray[i]);
                }
                else if(pairs[1] == -1){
                    pairs[1] = int8(ranksArray[i]);
                }
            }
            suits[(cardsArray[i] / 13)]++;
        }

        if (strongestHand == 7) {
            for(i = 0; i < 7; i++) {
                // find kicker
                if(int8(ranksArray[i]) != retOrder[0]) {
                    retOrder[1] = int8(ranksArray[0]);
                    return (strongestHand, retOrder);
                }
            }
        }

        // check for flush
        if (strongestHand < 5) {
            for(i = 0; i < 4; i++) {
                if(suits[i] >= 5) {
                    if (strongestHand == 4) {
                        if (suits[i] == 5) {
                            flushWinSuit = i;
                        }
                        uint8 cnt = 0;
                        for (i = 0; i < 7; i++) {
                            if (cardsArray[i] / 13 == flushWinSuit) {
                                streetFlushCards[cnt] = int8(ranksArray[i]);
                                cnt++;
                            }
                            if (i >= 5) {
                                if (streetFlushCards[i - 5] - streetFlushCards[i - 1] == 4) {
                                    strongestHand = 8;
                                    retOrder[0] = int8(streetFlushCards[i - 5]);
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
                }
                else {
                    retOrder[0] = pairs[1];
                    retOrder[1] = pairs[0];
                }
                return (strongestHand, retOrder);
            }
            // check for 3oaK
            for (i = 0; i < 5; i++) {
                // find kickers
                if(int8(ranksArray[i]) != retOrder[0]) {
                    if(int8(ranksArray[i]) > retOrder[1]) {
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
                for(i = 0; i < 7; i++) {
                    if(int8(ranksArray[i]) != pairs[0] && int8(ranksArray[i]) != pairs[1]) {
                        retOrder[2] = int8(ranksArray[i]);
                        break;
                    }
                }
                return (strongestHand, retOrder);
            }
            // one pair
            else {
                strongestHand = 1;
                retOrder[0] = pairs[0];
                uint8 cnt = (pairs[0] == -1) ? 0 : 1;
                for(i = 0; i < 7; i++) {
                    if(int8(ranksArray[i]) != pairs[0]) {
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
    function _publishResults(uint8[] memory cards, uint256 requestId) view internal returns(uint8, uint8[] memory) {
        uint8 win = setCards(cards);
        return (win, cards);
    }
}