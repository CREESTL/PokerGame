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
        bool active; // TODO: remove unused
    }

    struct RefAccount {
        address parent;
        uint256 bonusPercent;
        uint256 totalWinnings;
        uint256 referralEarningsBalance;
        uint256 sonCounter; // TODO: rename
    }

    event RegisteredReferer(address referee, address referral);

    // referral system
    uint[7] totalWinningsMilestones = [0, 400000, 6000000, 10000000, 14000000, 18000000, 22000000];
    uint[7] bonusPercentMilestones = [1, 2, 4, 6, 8, 10, 12];

    uint256 public constant PERCENT100 = 10 ** 18; // 100 %

    // maxbet calc
    uint256 _gamesCounter; // TODO: refactor all this vars to Poker contract and add private modifier
    uint256 _betFlip;
    uint256 _betColor;
    uint256 _betFlipSquare;
    uint256 _betColorSquare;
    uint256 _betFlipVariance;
    uint256 _betColorVariance;
    uint256 public maxBet; // TODO: change to private

    // jackpot
    uint256 public jackpot = 500000; // TODO: * 10 ** 18, change to private
    uint256 internal jackpotLimit = 1000000; // TODO: * 10 ** 18, change to private, add get/set functions for jackpotLimit (set func is onlyOwner)

    mapping (address => RefAccount) refAccounts;

    address _oracleOperator; // TODO: add private modifier
    IGame private _games; // TODO: rename _games -> _game
    ERC20 private _tokens;// TODO: remove unused
    Pool private pool;

    modifier onlyGame() {
        // bool senderIsAGame = false;
        require(_msgSender() == address(_games), "caller is not allowed to do some");
        _;
    }

    modifier onlyOracleOperator() {
        require(_msgSender() == _oracleOperator, "caller is not the operator");
        _;
    }

    modifier activePool () { // TODO: remove unused
        require(pool.active, "pool isn't active");
        _;
    }

    constructor (
        address xEthTokenAddress
    ) public {
        IInternalToken xEthCandidate = IInternalToken(xEthTokenAddress);
        require(xEthCandidate.supportsIInternalToken(), "invalid xETH address");
        pool.internalToken = xEthCandidate;
        pool.oracleGasFee = 120000;
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

    // TODO: group all onlyGame function to one block
    function updateJackpot(uint256 amount) external onlyGame activePool() {
        jackpot = jackpot.add(amount);
    }

    function jackpotDistribution(address payable player) external onlyGame activePool() returns (bool) {
        if (jackpot > jackpotLimit) {
            _rewardDistribution(player, jackpotLimit);
            jackpot = jackpot.sub(jackpotLimit);
        }
        _rewardDistribution(player, jackpot); // TODO: missing else block
        jackpot = 0;
    } // TODO: missing return value

    function updateReferralTotalWinnings(address son, uint amount) external onlyGame activePool() { // TODO: rename son, uint -> uint256
        address parent = refAccounts[son].parent;
        refAccounts[parent].totalWinnings = refAccounts[parent].totalWinnings.add(amount);
        updateReferralBonusRank(parent);
    }

    function updateReferralEarningsBalance(address son, uint amount) external onlyGame activePool() { // TODO: rename son, uint -> uint256
        address parent = refAccounts[son].parent;
        refAccounts[parent].referralEarningsBalance = refAccounts[parent]
            .referralEarningsBalance.add(amount.mul(refAccounts[parent].bonusPercent));
    }

    function withdrawReferralEarnings(address payable player) external {
        _rewardDistribution(player, refAccounts[player].referralEarningsBalance);
        refAccounts[player].referralEarningsBalance = 0; // TODO: security vulnerability (unchecked-send)
    }

    function deposit(address _to) external payable {
        // require(msg.value > 0, 'REVERT'); // TODO: remove unused
        _deposit(_to, msg.value);
    }

    function withdraw(uint256 amount) external activePool() {
        require(pool.internalToken.balanceOf(_msgSender()) >= amount, "amount exceeds balance");
        uint256 withdrawAmount = amount.mul(_getPrice()).div(PERCENT100);
        pool.amount = pool.amount.sub(withdrawAmount);
        _msgSender().transfer(withdrawAmount);
        pool.internalToken.burnTokenFrom(_msgSender(), amount);
    }

    function addBetToPool(uint256 betAmount) external onlyGame activePool() payable {
        uint256 oracleFeeAmount = pool.oracleGasFee;
        pool.amount = pool.amount.add(betAmount);
            // .sub(oracleFeeAmount);
        pool.oracleFeeAmount = pool.oracleFeeAmount.add(oracleFeeAmount);
    }

    // TODO: group all onlyOwner functions to one block
    function setGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        _games = game;
    }

    function takeOracleFee() external onlyOracleOperator {
        uint256 oracleFeeAmount = pool.oracleFeeAmount;
        pool.oracleFeeAmount = 0;
        _msgSender().transfer(oracleFeeAmount);
    }

    // TODO: group all external view functions to one block
    function getJackpot() public view returns(uint) { // TODO: public -> external
        return jackpot;
    }

    function getMaxBet() public view returns(uint) { // TODO: public -> external
        return (maxBet); // TODO: ...
    }

    function getGame() public view returns (address) { // TODO: public -> external
        return address(_games);
    }

    function setMaxBet(uint256 _maxBet) public { // TODO: remove this function
        maxBet = _maxBet;
    }

    function addRef(address parent, address son) public { // TODO: public -> external
        require(parent != son, "same address");
        refAccounts[son].parent = parent;
        refAccounts[parent].sonCounter = refAccounts[parent].sonCounter.add(1);
    }

    function getMyReferralStats(address referee) public view returns (address, uint, uint, uint, uint) { // TODO: public -> external, rename getMyReferralStats to getReferralStats
        return
            (
            refAccounts[referee].parent,
            refAccounts[referee].bonusPercent,
            refAccounts[referee].totalWinnings,
            refAccounts[referee].referralEarningsBalance,
            refAccounts[referee].sonCounter
            );
    }

    function maxBetCalc(uint pokerB, uint colorB) public { // TODO: public -> external, uint -> uint256
        _gamesCounter = _gamesCounter.add(1);
        if (_gamesCounter == 1) {
            if (maxBet == 0) maxBet = pool.amount.div(230);
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
                    maxBet = maxBet.mul(maxBet).div(Fn);
                } else {
                    maxBet = maxBet.mul(maxBet).div(Cn);
                }
                _gamesCounter = 0;
                if (maxBet > pool.amount.div(109)) maxBet = pool.amount.div(109);
                else if (maxBet < pool.amount.div(230)) maxBet = pool.amount.div(230);
            }
        }
    }

    function rewardDisribution(address payable player, uint256 prize) public onlyGame activePool() returns (bool) { // TODO: public -> external
        _rewardDistribution(player, prize);
    } // TODO: missing return value

    function updateReferralBonusRank(address parent) internal { // TODO: rename updateReferralBonusRank -> _updateReferralBonusRank
        uint currentBonus; // TODO: uint -> uint256
        for (uint i = 0; i < totalWinningsMilestones.length; i++) {
            if (totalWinningsMilestones[i] < refAccounts[parent].totalWinnings) {
                currentBonus = bonusPercentMilestones[i];
            }
        }
        refAccounts[parent].bonusPercent = currentBonus;
    }

    function sqrt(uint x) internal pure returns (uint y) { // TODO: move Poker contract, internal -> private, uint -> uint256
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    //                      Utility internal functions                      //
    // TODO: add to this place all internal functions from up side
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
