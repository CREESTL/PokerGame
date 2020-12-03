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

    // referral system
    uint[7] totalWinningsMilestones = [0, 400000, 6000000, 10000000, 14000000, 18000000, 22000000];
    uint[7] bonusPercentMilestones = [1, 2, 4, 6, 8, 10, 12];

    uint256 public constant PERCENT100 = 10 ** 18; // 100 %

    // maxbet calc
    uint256 private _gamesCounter; // TODO: refactor all this vars to Poker contract
    uint256 private _betFlip;
    uint256 private _betColor;
    uint256 private _betFlipSquare;
    uint256 private _betColorSquare;
    uint256 private _betFlipVariance;
    uint256 private _betColorVariance;
    uint256 private _maxBet;

    // jackpot
    uint256 private _jackpot = 500000; // TODO: ask client
    uint256 private _jackpotLimit = 1000000; // TODO: ask client, set functions for jackpotLimit (set func is onlyOwner)

    mapping (address => RefAccount) refAccounts;

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
        pool.oracleGasFee = 120000;
    }

    function getJackpot() external view returns(uint) {
        return _jackpot;
    }

    function getJackpotLimit() external view returns(uint) {
        return _jackpotLimit;
    }

    function getMaxBet() external view returns(uint) {
        return (_maxBet); // TODO: ...
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

    function getOracleGasFee() external view returns (uint256) {
        return pool.oracleGasFee;
    }

    function getOracleOperator() external view returns (address) {
        return _oracleOperator;
    }

    function getOracleFeeAmount() external view returns (uint256) {
        return pool.oracleFeeAmount;
    }

    function _getMyReferralStats(address referee) external view returns (address, uint, uint, uint, uint) {
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
        if (_jackpot > _jackpotLimit) {
            _rewardDistribution(player, _jackpotLimit);
            _jackpot = _jackpot.sub(_jackpotLimit);
        } else {
            _rewardDistribution(player, _jackpot);
            _jackpot = 0;
        }
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

    function rewardDisribution(address payable player, uint256 prize) external onlyGame returns (bool) {
        _rewardDistribution(player, prize);
        return true;
    }

    function withdrawReferralEarnings(address payable player) external {
        _rewardDistribution(player, refAccounts[player].referralEarningsBalance);
        refAccounts[player].referralEarningsBalance = 0; // TODO: security vulnerability (unchecked-send)
    }

    function deposit(address _to) external payable {
        _deposit(_to, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(pool.internalToken.balanceOf(_msgSender()) >= amount, "amount exceeds balance");
        uint256 withdrawAmount = amount.mul(_getPrice()).div(PERCENT100);
        pool.amount = pool.amount.sub(withdrawAmount);
        _msgSender().transfer(withdrawAmount);
        pool.internalToken.burnTokenFrom(_msgSender(), amount);
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

    function setMaxBet(uint256 maxBet) external onlyOwner { // TODO: remove this function ?????????
        _maxBet = maxBet;
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

    function maxBetCalc(uint pokerB, uint colorB) external {
        _gamesCounter = _gamesCounter.add(1);
        if (_gamesCounter == 1) {
            if (_maxBet == 0) _maxBet = pool.amount.div(230);
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
            if (_gamesCounter > 100 && Fn < pool.amount.div(230) && Cn < pool.amount.div(230)) {
                if (Fn > Cn) {
                    _maxBet = _maxBet.mul(_maxBet).div(Fn);
                } else {
                    _maxBet = _maxBet.mul(_maxBet).div(Cn);
                }
                _gamesCounter = 0;
                if (_maxBet > pool.amount.div(109)) _maxBet = pool.amount.div(109);
                else if (_maxBet < pool.amount.div(230)) _maxBet = pool.amount.div(230);
            }
        }
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
        player.transfer(prize);
        pool.amount = pool.amount.sub(prize);
        return true;
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
