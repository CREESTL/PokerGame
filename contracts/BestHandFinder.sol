pragma solidity >0.4.18 < 0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract BestHandFinder{
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint[] HandType = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

    uint8[] public arrayForSorting;
    
    struct Strongest {
        uint8 hand;
        uint8 topEqualCard;
        uint8 topCard;
    }

    Strongest strongest;
    uint8 tempEquals;
    uint8 tempStreet;

    uint8[]cardsArray;
    uint8[]rankArray;

    function set(uint8[] memory _data) public { 
        arrayForSorting = _data; 
    }

    function get() public view returns(uint8[] memory){ 
        return arrayForSorting;
    }

    function quick() public {
        if (arrayForSorting.length > 1) {
            quickPart(arrayForSorting, 0, arrayForSorting.length - 1);
        }
    }

    function setCards(uint8[] memory _cardsArray, uint8[] memory _rankArray) public {
        cardsArray = _cardsArray;
        rankArray = _rankArray;
    }

    function getCards() public view returns(uint8[] memory, uint8[] memory) {
        return (cardsArray, rankArray);
    }

    function getStrongest() public view returns (uint8, uint8, uint8) {
        return (strongest.hand, strongest.topEqualCard, strongest.topCard);
    }

    function FindStrongest () public {
        strongest = Strongest(0, 0, rankArray[rankArray.length - 1]);
        tempEquals = 1;
        tempStreet = 1;
        // uint i = 5;
        for(uint i = rankArray.length - 2; i > 0; --i) {  
            if(rankArray[i] == rankArray[i - 1]) {
                tempEquals++;
                tempStreet = 1;
            } 
            else if(rankArray[i] - 1 == rankArray[i - 1]) {
                saveHandWithEquals(strongest, tempEquals, rankArray[i + 1]);
                tempEquals = 1;
                tempStreet.add(1);
                if(tempStreet == 5) {
                    strongest.hand = 4;
                    // strongest.topCard = rankArray[i] + 5;//you aare gay //TODO: stop being gay
                    tempStreet = 1;
                }
            } else {
                tempStreet = 1;
                tempEquals = 1;
            }
        }
        saveHandWithEquals(strongest, tempEquals, rankArray[0]);

        // if(strongest.hand == 4) {
        //     //TODO: checker for streetflush
        // } else if (strongest.hand < 5) {
        //     //TODO: checker for flush
        // }
    }

    function saveHandWithEquals(Strongest memory _strongest, uint8 _tempEquals, uint8 tempTopCard) internal {
        if(_tempEquals == 2) {
            if(_strongest.hand == 0) {
                strongest.hand = 1;
                strongest.topEqualCard = tempTopCard;
            } else if(_strongest.hand == 1) {
                strongest.hand = 2;
                strongest.topEqualCard = tempTopCard;
            } else if(_strongest.hand == 3) {
                strongest.hand = 6;
                strongest.topEqualCard = tempTopCard;
            }
        } else if(tempEquals == 4) {
            strongest.hand = 7;
            strongest.topEqualCard = tempTopCard;
        }
    }

    
    function quickPart(uint8[] storage data, uint low, uint high) internal {
        if (low < high) {
            uint pivotVal = data[(low + high) / 2];
        
            uint low1 = low;
            uint high1 = high;
            for (;;) {
                while (data[low1] < pivotVal) low1++;
                while (data[high1] > pivotVal) high1--;
                if (low1 >= high1) break;
                (data[low1], data[high1]) = (data[high1], data[low1]);
                low1++;
                high1--;
            }
            if (low < high1) quickPart(data, low, high1);
            high1++;
            if (high1 < high) quickPart(data, high1, high);
        }
    }
    
}