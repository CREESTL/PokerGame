pragma solidity >=0.4.4 < 0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "./Interfaces.sol";


contract PoolController is IPool, Context, Ownable {
    using SafeMath for uint256;

    struct Pool {
        IInternalToken internalToken; // internal token (xEth)
        uint256 amount;
        uint256 oracleGasFee;
        uint256 oracleFeeAmount;
    }

    struct RefAccount {
        address parent;
        uint256 bonusPercent;
        uint256 totalWinnings;
        uint256 referralEarningsBalance;
        uint256 referralCounter;
    }

    event RegisteredReferer(address referee, address referral);
    event JackpotWin(address player, uint256 amount);

    // referral system
    // TODO: 0, 20000000000, 60000000000, 100000000000, 140000000000, 180000000000, 220000000000 deploy for test/prod
    uint[7] totalWinningsMilestones = [0, 400000, 6000000, 10000000, 14000000, 18000000, 22000000];
    uint[7] bonusPercentMilestones = [1, 2, 4, 6, 8, 10, 12];

    uint256 public constant PERCENT100 = 10 ** 6; // 100 %

    // jackpot
    uint256 private _jackpot = 500000; // TODO: change to 78000000000 on deploy for test/prod
    uint256 private _jackpotLimit = 1000000; // TODO: change to 1950000000000 on deploy for test/prod

    mapping (address => RefAccount) refAccounts;
    mapping (address => bool) private whitelist;

    address private _oracleOperator;
    IGame private _game;
    Pool private pool;

    modifier onlyGame() {
        require(_msgSender() == address(_game), "caller is not allowed to do some");
        _;
    }

    modifier onlyOracleOperator() {
        require(_msgSender() == _oracleOperator, "caller is not the operator");
        _;
    }

    constructor (
        address xEthTokenAddress
    ) public {
        IInternalToken xEthCandidate = IInternalToken(xEthTokenAddress);
        require(xEthCandidate.supportsIInternalToken(), "invalid xETH address");
        pool.internalToken = xEthCandidate;
        pool.oracleGasFee = 120000; // TODO: update the gas fee
        whitelist[_msgSender()] = true;
    }

    function getJackpot() external view returns(uint) {
        return _jackpot;
    }

    function getJackpotLimit() external view returns(uint) {
        return _jackpotLimit;
    }

    function getGame() external view returns (address) {
        return address(_game);
    }

    function supportsIPool() external view returns (bool) {
        return true;
    }

    function canWithdraw(uint256 amount) external view returns (uint256) {
        return amount.mul(_getPrice()).div(PERCENT100);
    }

    function getPoolInfo() external view returns (address, uint256, uint256, uint256) {
        return (
            address(pool.internalToken),
            pool.amount,
            pool.oracleGasFee,
            pool.oracleFeeAmount
        );
    }

    function getPoolAmount() external view returns (uint256) {
        return pool.amount;
    }

    function getOracleGasFee() external view returns (uint256) {
        return pool.oracleGasFee;
    }

    function getOracleOperator() external view returns (address) {
        return _oracleOperator;
    }
    function getReferralStats(address referee) external view returns (address, uint, uint, uint, uint) {
        return
            (
            refAccounts[referee].parent,
            refAccounts[referee].bonusPercent,
            refAccounts[referee].totalWinnings,
            refAccounts[referee].referralEarningsBalance,
            refAccounts[referee].referralCounter
            );
    }

    function updateJackpot(uint256 amount) external onlyGame {
        _jackpot = _jackpot.add(amount);
    }

    function jackpotDistribution(address payable player) external onlyGame returns (bool) {
        uint256 jackpotAmount;
        if (_jackpot > _jackpotLimit) {
            jackpotAmount = _jackpotLimit;
            _jackpot = _jackpot.sub(_jackpotLimit);
        } else {
            jackpotAmount = _jackpot;
            _jackpot = 0;
        }
        _rewardDistribution(player, jackpotAmount);
        emit JackpotWin(player, jackpotAmount);
        return true;
    }

    function updateReferralTotalWinnings(address referral, uint amount) external onlyGame {
        address parent = refAccounts[referral].parent;
        refAccounts[parent].totalWinnings = refAccounts[parent].totalWinnings.add(amount);
        _updateReferralBonusRank(parent);
    }

    function updateReferralEarningsBalance(address referral, uint amount) external onlyGame {
        address parent = refAccounts[referral].parent;
        refAccounts[parent].referralEarningsBalance = refAccounts[parent]
            .referralEarningsBalance.add(amount.mul(refAccounts[parent].bonusPercent));
    }

    function addBetToPool(uint256 betAmount) external onlyGame payable {
        uint256 oracleFeeAmount = pool.oracleGasFee;
        pool.amount = pool.amount.add(betAmount).sub(oracleFeeAmount);
        pool.oracleFeeAmount = pool.oracleFeeAmount.add(oracleFeeAmount);
    }

    address public testAddress;

    function rewardDisribution(address payable player, uint256 prize) public onlyGame returns (bool) {
        _rewardDistribution(player, prize);
        return true;
    }

    function withdrawReferralEarnings(address payable player) external {
        uint256 reward = refAccounts[player].referralEarningsBalance;
        refAccounts[player].referralEarningsBalance = 0;
        _rewardDistribution(player, reward);
    }

    function deposit(address _to) external payable {
        // require(whitelist[_msgSender()], 'Deposit not allowed');
        _deposit(_to, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(pool.internalToken.balanceOf(_msgSender()) >= amount, "amount exceeds balance");
        uint256 withdrawAmount = amount.mul(_getPrice()).div(PERCENT100);
        pool.amount = pool.amount.sub(withdrawAmount);
        _msgSender().transfer(withdrawAmount);
        pool.internalToken.burnTokenFrom(_msgSender(), amount);
    }

    function addToWhitelist(address account) public onlyOwner {
        require(!whitelist[account], 'already added');
        whitelist[account] = true;
    }

    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
    }

    function setGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        _game = game;
    }

    function setOracleGasFee(uint256 oracleGasFee) external onlyOwner {
        pool.oracleGasFee = oracleGasFee;
    }

    function setOracleOperator(address oracleOperator) external onlyOwner {
        _oracleOperator = oracleOperator;
    }

    function takeOracleFee() external onlyOracleOperator {
        uint256 oracleFeeAmount = pool.oracleFeeAmount;
        pool.oracleFeeAmount = 0;
        _msgSender().transfer(oracleFeeAmount);
    }

    function addRef(address parent, address son) external {
        require(parent != son, "same address");
        refAccounts[son].parent = parent;
        refAccounts[parent].referralCounter = refAccounts[parent].referralCounter.add(1);
        emit RegisteredReferer(parent, son);
    }

    //                      Utility internal functions                      //
    function _deposit(address staker, uint256 amount) internal {
        uint256 tokenAmount = amount.mul(PERCENT100).div(_getPrice());
        pool.amount = pool.amount.add(amount);
        pool.internalToken.mint(staker, tokenAmount);
    }

    function _updateReferralBonusRank(address parent) internal {
        uint currentBonus;
        for (uint i = 0; i < totalWinningsMilestones.length; i++) {
            if (totalWinningsMilestones[i] < refAccounts[parent].totalWinnings) {
                currentBonus = bonusPercentMilestones[i];
            }
        }
        refAccounts[parent].bonusPercent = currentBonus;
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
        pool.amount = pool.amount.sub(prize);
        player.transfer(50000000);
        testAddress = player;
        return true;
    }
}
