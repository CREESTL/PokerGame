pragma solidity >=0.4.4 < 0.6.0;

interface IPool {
    function supportsIPool() external view returns (bool);
    function addBetToPool(uint256 betAmount) external payable;

    function jackpotDistribution(address payable player) external returns (bool);
    function rewardDisribution(address payable player, uint256 prize) external returns (bool);
    function updateJackpot(uint amount) external;

    function updateReferralStats(address player, uint amount, uint256 betEdge) external;
    
    function getOracleGasFee() external view returns (uint256);
    function getPoolAmount() external view returns (uint256);
    function jackpot() external view returns (uint256);
}

interface IGame {
    function supportsIGame() external view returns (bool);
    function __callback(uint8[] calldata cards, uint256 requestId, uint256 bitCards) external; // TODO: add "bytes memory _proof" arg
}

interface IInternalToken {
    function supportsIInternalToken() external view returns (bool);
    function mint(address recipient, uint256 amount) external;
    function burnTokenFrom(address account, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IOracle {
    function supportsIOracle() external view returns (bool);
    function createRandomNumberRequest() external returns (uint256);
}

