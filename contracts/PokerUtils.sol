pragma solidity >0.4.18 < 0.6.0;

library PokerUtils {
    address public constant ETH_ADDRESS = 0x0000000000000000000000000000000000000001;
    uint256 public constant PERCENT100 = 10 ** 18; // 100 %

    function getETHAddress() external pure returns(address) {
        return ETH_ADDRESS;
    }

    function getPercent100() external pure returns(uint256) {
        return PERCENT100;
    }

    function checkSquare(uint256 square) external pure returns(bool) {
        return (square > 0) && (square < (1 << 37));
    }


    function maximumBet(uint256[] calldata bets) external pure returns(uint256 maxBet) {
        maxBet = bets[0];
        for (uint256 i = 1; i < bets.length; ++i) {
            if (bets[i] > maxBet)
                maxBet = bets[i];
        }
        return maxBet;
    }

    // function computeBet(uint256[] calldata bets) external pure returns(uint256 bet) {
    //     bet = bets[0];
    //     for (uint256 i = 1; i < bets.length; ++i) {
    //         bet = bet + bets[i];
    //         require(bet >= bets[i], "addition overflow");
    //     }
    //     return bet;
    // }
}
