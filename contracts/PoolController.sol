// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IInternalToken.sol";
import "./interfaces/IGame.sol";

/**
 * Jackpot logic
 */

contract PoolController is IPool, Context, Ownable {
    using SafeMath for uint256;

    /**
     * @dev The representation of the pool
     */
    struct Pool {
        // TODO All ERC20 tokens can be added here
        // The internal token of the pool
        IInternalToken internalToken; 
        // The amount of internal tokens in the pool
        uint256 amount;
        // Gas fee for oracle services
        uint256 oracleGasFee;
        // Total amount of fees collected by the oracle
        uint256 oracleTotalGasFee;
    }

    /**
     * The representation of the account taking part in the referral system
     */
    struct RefAccount {
        // The account who invited another account to the referral system
        address parent;
        // The percent to be paid for referral system membership as a bonus
        uint256 bonusPercent;
        // TODO what's the difference between the two?
        // Total amount of tokens won while using referral program
        uint256 totalWinnings;
        uint256 referralEarningsBalance;
        // The amount of referers of the referee
        uint256 referralCounter;
    }
    /**
     * @dev If `bonusPercent` is 5 and `_percentDivider` is 100, then house edge is 5 / 100 = 0.05%
     */
    uint256 private constant _percentDivider = 100;

    /**
     * @title Indicates that a new referer has been registered
     */
    event RegisteredReferer(address referee, address referral);
    
    /**
     * @title Indicates that a player won a jackpot
     */
    event JackpotWin(address player, uint256 amount);

    /**
     * @title Each milestone reached by the referee increases his bonus percent
     * @dev {bonusPercentMilestones[i]} corresponds to {totalWinningsMilestones[i]} and vice versa
     */
    uint256[7] public totalWinningsMilestones;
    uint256[7] public bonusPercentMilestones;

    // TODO why 10**6?
    uint256 internal constant HUNDRED_PERCENT = 10**6; 

    /**
     * @title The total amount of tokens stored to be paid as jackpot
     */
    uint256 public totalJackpot;
    /**
     * @title Amount of tokens freezed to be paid some time in the future
     */
    uint256 public freezedJackpot;
    /**
     * @title The maximum amount of tokens to be stored for jackpot payments
     */
    uint256 public jackpotLimit;

    /**
     * @title All account taking part in the referral program
     */
    mapping(address => RefAccount) public refAccounts;
    /**
     * @title The list of addresses that can deposit funds into the pool
     */
    mapping(address => bool) public whitelist;

    /**
     * @dev The address of the operator. Usually the backend address
     */
    address private _oracleOperator;
    /**
     * @dev The game using this pool controller
     */
    IGame private _game;
    /**
     * @dev The pool controlled by this pool controller
     */
    Pool private pool;

    /**
     * @dev Checks that caller is the game using this pool controller
     */
    modifier onlyGame() {
        require(
            _msgSender() == address(_game),
            "PoolController: caller is not a game owner!"
        );
        _;
    }
    /**
     * @dev Checks that caller is the pool operator
     */
    modifier onlyOracleOperator() {
        require(
            _msgSender() == _oracleOperator,
            "PoolController: caller is not an operator!"
        );
        _;
    }
    constructor(address internalTokenAddress) {
        IInternalToken internalCandidate = IInternalToken(internalTokenAddress);
        require(
            internalCandidate.supportsIInternalToken(),
            "pc: Invalid xTRX Token Address!"
        );

        // TODO maybe take all of this as arguments for constructor
        pool.internalToken = internalCandidate;
        pool.oracleGasFee = 3000000;
        whitelist[_msgSender()] = true;
        totalWinningsMilestones = [
            0,
            20000000000,
            60000000000,
            100000000000,
            140000000000,
            180000000000,
            220000000000
        ];
        bonusPercentMilestones = [1, 2, 4, 6, 8, 10, 12];
        // TODO: change to 78000000000 on deploy for test/prod
        totalJackpot = 78000000000; 
        // TODO: change to 1950000000000 on deploy for test/prod
        jackpotLimit = 1950000000000; 
    }

    /**
     * @title Returns referral program winnings milestones
     * @return Referral program winnings milestones
     */
    function getTotalWinningsMilestones()
        external
        view
        returns (uint256[7] memory)
    {
        return totalWinningsMilestones;
    }

    /**
     * @title Returns referral program bonus percent milestones
     * @return Referral program bonus percent milestones
     */
    function getBonusPercentMilestones()
        external
        view
        returns (uint256[7] memory)
    {
        return bonusPercentMilestones;
    }

    /**
     * @title Returns the address of the game that is using this pool controller
     * @return The address of the game that is using this pool controller 
     */
    function getGame() external view returns (address) {
        return address(_game);
    }

    /**
     * @title Should be called by other contracts to check that the contract with the given
     *        address supports the {IPool} interface
     * @return Always True
     */
    function supportsIPool() external pure returns (bool) {
        return true;
    }

    function canWithdraw(uint256 amount) external view returns (uint256) {
        return amount.mul(_getPrice()).div(HUNDRED_PERCENT);
    }

    function getPoolInfo()
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            address(pool.internalToken),
            pool.amount,
            pool.oracleGasFee,
            pool.oracleTotalGasFee
        );
    }

    function getPoolAmount() external view returns (uint256) {
        return pool.amount;
    }

    function getTokenAddress() external view returns (address) {
        return address(pool.internalToken);
    }

    function getOracleGasFee() external view returns (uint256) {
        return pool.oracleGasFee;
    }

    function getOracleOperator() external view returns (address) {
        return _oracleOperator;
    }

    function getReferralStats(address referee)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            refAccounts[referee].parent,
            refAccounts[referee].bonusPercent,
            refAccounts[referee].totalWinnings,
            refAccounts[referee].referralEarningsBalance,
            refAccounts[referee].referralCounter
        );
    }

    // setters
    function setTotalWinningsMilestones(
        uint256[] calldata newTotalWinningMilestones
    ) external onlyOwner {
        for (uint256 i = 0; i < 7; i++) {
            totalWinningsMilestones[i] = newTotalWinningMilestones[i];
        }
    }

    function setBonusPercentMilestones(uint256[] calldata newBonusPercent)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < 7; i++) {
            bonusPercentMilestones[i] = newBonusPercent[i];
        }
    }

    function setJackpot(uint256 _jackpot) external onlyOwner {
        totalJackpot = _jackpot;
    }

    function setJackpotLimit(uint256 _jackpotLimit) external onlyOwner {
        jackpotLimit = _jackpotLimit;
    }

    function updateJackpot(uint256 amount) external onlyGame {
        totalJackpot = totalJackpot.add(amount);
    }


    function freezeJackpot(uint256 amount) external onlyGame {
        // TODO why isn't here `totalJackpot.sub(amount)`
        // TODO aren't freezed tokens withdrawn from total jackpot?
        freezedJackpot = freezedJackpot.add(amount);
    }

    // Don't change this name, otherwise back/front can break
    function jackpot() public view returns (uint256) {
        return totalJackpot.sub(freezedJackpot);
    }

    function receiveFundsFromGame() external payable {}

    function jackpotDistribution(address payable player, uint256 prize)
        external
        onlyGame
    {
        totalJackpot = totalJackpot.sub(prize);
        freezedJackpot = freezedJackpot.sub(prize);
        _rewardDistribution(player, prize);
        emit JackpotWin(player, prize);
    }

    function updateReferralStats(
        address referral,
        uint256 amount,
        uint256 betEdge
    ) external onlyGame {
        // update data first for correct referralEarningsBalance distribution
        address parent = refAccounts[referral].parent;
        refAccounts[parent].totalWinnings = refAccounts[parent]
            .totalWinnings
            .add(amount);
        _updateReferralBonusRank(parent);

        uint256 referralEarnings = betEdge
            .mul(refAccounts[parent].bonusPercent)
            .div(_percentDivider);
        refAccounts[parent].referralEarningsBalance = refAccounts[parent]
            .referralEarningsBalance
            .add(referralEarnings);
    }

    function addBetToPool(uint256 betAmount) external payable onlyGame {
        uint256 oracleGasFee = pool.oracleGasFee;
        pool.amount = pool.amount.add(betAmount).sub(oracleGasFee);
        pool.oracleTotalGasFee = pool.oracleTotalGasFee.add(oracleGasFee);
    }

    function rewardDistribution(address payable player, uint256 prize)
        public
        onlyGame
    {
        _rewardDistribution(player, prize);
    }

    function withdrawReferralEarnings(address payable player) external {
        uint256 reward = refAccounts[player].referralEarningsBalance;
        refAccounts[player].referralEarningsBalance = 0;
        _rewardDistribution(player, reward);
    }

    function deposit(address _to) external payable {
        require(
            whitelist[_msgSender()],
            "pc: Deposit is Forbidden for the Caller!"
        );
        _deposit(_to, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(
            pool.internalToken.balanceOf(_msgSender()) >= amount,
            "pc: Amount Exceeds Token Balance!"
        );
        uint256 withdrawAmount = amount.mul(_getPrice()).div(HUNDRED_PERCENT);
        pool.amount = pool.amount.sub(withdrawAmount);
        payable(_msgSender()).transfer(withdrawAmount);
        pool.internalToken.burnTokenFrom(_msgSender(), amount);
    }

    function addToWhitelist(address account) public onlyOwner {
        require(!whitelist[account], "already added");
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
        uint256 oracleTotalGasFee = pool.oracleTotalGasFee;
        pool.oracleTotalGasFee = 0;
        payable(_msgSender()).transfer(oracleTotalGasFee);
    }

    function addRef(address parent, address son) external {
        require(
            refAccounts[son].parent == address(0),
            "pc: Already a Referral!"
        );
        require(parent != son, "same address");
        refAccounts[son].parent = parent;
        refAccounts[parent].referralCounter = refAccounts[parent]
            .referralCounter
            .add(1);
        emit RegisteredReferer(parent, son);
    }

    //                      Utility internal functions                      //
    function _deposit(address staker, uint256 amount) internal {
        uint256 tokenAmount = amount.mul(HUNDRED_PERCENT).div(_getPrice());
        pool.amount = pool.amount.add(amount);
        pool.internalToken.mint(staker, tokenAmount);
    }

    function _updateReferralBonusRank(address parent) internal {
        uint256 currentBonus;
        for (uint256 i = 0; i < totalWinningsMilestones.length; i++) {
            if (
                totalWinningsMilestones[i] < refAccounts[parent].totalWinnings
            ) {
                currentBonus = bonusPercentMilestones[i];
            }
        }
        refAccounts[parent].bonusPercent = currentBonus;
    }

    function _getPrice() internal view returns (uint256) {
        if (pool.internalToken.totalSupply() == 0) {
            return HUNDRED_PERCENT;
        }
        return (pool.amount).mul(HUNDRED_PERCENT).div(pool.internalToken.totalSupply());
    }

    function _rewardDistribution(address payable player, uint256 prize)
        internal
    {
        require(
            prize <= address(this).balance,
            "pc: Not Enough Funds to Pay the Reward!"
        );
        require(prize <= pool.amount, "pc: Not Enough Funds in the Pool!");
        pool.amount = pool.amount.sub(prize);
        player.transfer(prize);
    }
}
