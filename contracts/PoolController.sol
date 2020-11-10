pragma solidity >=0.4.4 < 0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./Interfaces.sol";

contract PoolController is IPool, Context, Ownable {
    using SafeMath for uint256;

    // enum BonusRank { Bronze, Silver, Gold, Platinum, Diamond, Emerald, Saphire }
    uint[7] totalWinningsMilestones =  [0, 400000, 6000000, 10000000, 14000000, 18000000, 22000000];
    uint[7] bonusPercentMilestones = [1, 2, 4, 6, 8, 10 ,12];

    uint256 public constant PERCENT100 = 10 ** 18; // 100 %

    uint256 public jackpot = 500000;
    uint256 internal jackpotLimit = 1000000;

    struct Pool {
        IInternalToken internalToken; // internal token (xEth or xWgr)
        uint256 amount;
        uint256 oracleGasFee;
        uint256 oracleFeeAmount;
        bool active;
    }

    struct RefAccount {
        address parent;
        // uint256 bonusRank;
        uint256 bonusPercent;
        uint256 totalWinnings;
        uint256 referralEarningsBalance;
        uint256 sonCounter;
    }

    event RegisteredReferer(address referee, address referral);

    mapping (address => RefAccount) refAccounts;

    address _oracleOperator;
    IGame internal _games;
    ERC20 internal _tokens;
    Pool internal pool;

    modifier onlyGame() {
        bool senderIsAGame = false;
        require(_msgSender() == address(_games), "caller is not allowed to do some");
        _;
    }

    modifier onlyOracleOperator() {
        require(_msgSender() == _oracleOperator, "caller is not the operator");
        _;
    }

    modifier activePool () {
        require(pool.active, "pool isn't active");
        _;
    }

    constructor (
        address xEthTokenAddress
    ) public {
        IInternalToken xEthCandidate = IInternalToken(xEthTokenAddress);
        require(xEthCandidate.supportsIInternalToken(), "invalid xETH address");
        pool.internalToken = xEthCandidate;
        pool.oracleGasFee = 120_000;
        pool.active = true;
    }

    // function() external payable {
    //     // require(pool.active, "pool isn't active");
    //     // _deposit(_msgSender(), msg.value);
    // }

    //                      Common getters functions                  //
    // function activateToken(address tokenAddress) external onlyOwner {
    //     require(tokenAddress != address(0), "invalid token address");
    //     require(!_pools[tokenAddress].active, "already activated");
    //     _pools[tokenAddress].active = true;
    // }

    // function deactivateToken(address tokenAddress) external onlyOwner {
    //     require(_pools[tokenAddress].active, "already deactivated");
    //     _pools[tokenAddress].active = false;
    // }   

    function getJackpot() public view returns(uint) {
        return jackpot;
    }

    function setOracleGasFee(uint256 oracleGasFee) external onlyOwner {
        pool.oracleGasFee = oracleGasFee;
    }

    function setOracleOperator(address oracleOperator) external onlyOwner {
        _oracleOperator = oracleOperator;
    }

    function supportsIPool() external view returns (bool) {
        return true;
    }

    function canWithdraw(uint256 amount) external view returns (uint256) {
        require(pool.active, "pool isn't active");
        return amount.mul(_getPrice()).div(PERCENT100);
    }

    function getPoolInfo() external view returns (address, uint256, uint256, uint256, bool) {
        return (
            address(pool.internalToken),
            pool.amount,
            pool.oracleGasFee,
            pool.oracleFeeAmount,
            pool.active
        );
    }

    function getOracleGasFee() external view returns (uint256) {
        return pool.oracleGasFee;
    }

    function getOracleOperator() external view returns (address) {
        return _oracleOperator;
    }

    function getOracleFeeAmount() external view returns (uint256) {
        return pool.oracleFeeAmount;
    }

    /// referral programm ///


    function addRef(address parent, address son) public {
        require(parent != son, "same address");
        refAccounts[son].parent = parent;
        refAccounts[parent].sonCounter = refAccounts[parent].sonCounter.add(1);
    }

    function updateJackpot(uint256 amount) external onlyGame activePool() {
        jackpot = jackpot.add(amount);
    }

    function updateReferralTotalWinnings(address son, uint amount) external onlyGame activePool() {
        address parent = refAccounts[son].parent;
        refAccounts[parent].totalWinnings = refAccounts[parent].totalWinnings.add(amount);
        updateReferralBonusRank(parent);
    }

    function updateReferralEarningsBalance(address son, uint amount) external onlyGame activePool() {
        address parent = refAccounts[son].parent;
        refAccounts[parent].referralEarningsBalance = refAccounts[parent].referralEarningsBalance.add(amount.mul(refAccounts[parent].bonusPercent));
    }

    function updateReferralBonusRank(address parent) internal {
        uint currentBonus;
        for (uint i = 0; i < totalWinningsMilestones.length; i++) {
            if(totalWinningsMilestones[i] < refAccounts[parent].totalWinnings) {
                currentBonus = bonusPercentMilestones[i];
            }
        }
        refAccounts[parent].bonusPercent = currentBonus;
    }

    function withdrawReferralEarnings(address payable player) external {
        _rewardDistribution(player, refAccounts[player].referralEarningsBalance);
        refAccounts[player].referralEarningsBalance = 0;
    }

    function getMyReferralStats(address referee) public view returns (address, uint, uint, uint, uint) {
        return 
            (
            refAccounts[referee].parent,
            refAccounts[referee].bonusPercent,
            refAccounts[referee].totalWinnings,
            refAccounts[referee].referralEarningsBalance,
            refAccounts[referee].sonCounter
            );
    }

    //                      Deposit/Withdraw functions                      //
    function deposit(address _to) external activePool() payable {
        // require(msg.value > 0, 'REVERT');
        _deposit(_to, msg.value);
    }

    function withdraw(uint256 amount) external activePool() {
        require(pool.internalToken.balanceOf(_msgSender()) >= amount, "amount exceeds balance");
        uint256 withdrawAmount = amount.mul(_getPrice()).div(PERCENT100);
        pool.amount = pool.amount.sub(withdrawAmount);
        _msgSender().transfer(withdrawAmount);
        pool.internalToken.burnTokenFrom(_msgSender(), amount);
    }

    //                      Game functions                      //
    // function getGamesCount() external view returns (uint256) {
    //     return _games.length;
    // }

    function getGame() public view returns (address) {
        return address(_games);
    }

    function setGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        _games = game;
    }

    // function removeGame(uint256 index) external onlyOwner {
    //     getGame(index); // for require check
    //     if (index != (_games.length - 1)) {
    //         _games[index] == _games[_games.length - 1];
    //     }
    //     _games.pop();
    // }

    function addBetToPool(uint256 betAmount) external onlyGame activePool() payable {
        uint256 oracleFeeAmount = pool.oracleGasFee;
        pool.amount = pool.amount.add(betAmount);
            // .sub(oracleFeeAmount);
        pool.oracleFeeAmount = pool.oracleFeeAmount.add(oracleFeeAmount);
    }

    function rewardDisribution(address payable player, uint256 prize) public onlyGame activePool() returns (bool) {
        _rewardDistribution(player, prize);
    }

    function jackpotDistribution(address payable player) external onlyGame activePool() returns (bool) {
        if(jackpot > jackpotLimit) {
            _rewardDistribution(player, jackpotLimit);
            jackpot = jackpot.sub(jackpotLimit);
        }
        _rewardDistribution(player, jackpot);
        jackpot = 0;
    }
    // TODO: redesign
    function maxBet(uint256 maxPercent) external view returns (uint256) {
        if (maxPercent > PERCENT100)
            return 0;
        if (!pool.active) {
            return 0;
        }
        return pool.amount.mul(maxPercent).div(PERCENT100);
    }

    //                      Oracle functions                                //
    function takeOracleFee() external onlyOracleOperator {
        uint256 oracleFeeAmount = pool.oracleFeeAmount;
        pool.oracleFeeAmount = 0;
        _msgSender().transfer(oracleFeeAmount);
    }

    //                      Utility internal functions                      //
    function _deposit(address staker, uint256 amount) internal {
        uint256 tokenAmount = amount.mul(PERCENT100).div(_getPrice());
        pool.amount = pool.amount.add(amount);
        pool.internalToken.mint(staker, tokenAmount);
    }

    function _getPrice() internal view returns (uint256) {
        if (pool.internalToken.totalSupply() == 0)
            return PERCENT100;
        return (pool.amount).mul(PERCENT100).div(pool.internalToken.totalSupply());
    }

    function _rewardDistribution(address payable player, uint256 prize) internal returns (bool) {
         if (address(this).balance < prize) {
            return false;
        }
        player.transfer(prize);
        pool.amount = pool.amount.sub(prize);
        return true;
    }
}
