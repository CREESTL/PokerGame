// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IInternalToken.sol";
import "./interfaces/IGame.sol";

/**
 * @notice Controls the tokens pool of the game, distributes rewards.
 *        Controls the referral program payments
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
        // The amount of native tokens paid to mint internal tokens into the pool
        uint256 nativeTokensTotal;
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
        // Total amount of tokens won buy the referer
        uint256 referersTotalWinnings;
        // Total amount of tokens earned buy the referee during the referral program
        uint256 referralEarningsBalance;
        // The amount of referers of the referee
        uint256 referralCounter;
    }
    /**
     * @dev If `bonusPercent` is 5 and `_percentDivider` is 100, then house edge is 5 / 100 = 0.05%
     */
    uint256 private constant _percentDivider = 100;

    /**
     * @notice Indicates that a new referer has been registered
     */
    event RegisteredReferer(address referee, address referral);
    
    /**
     * @notice Indicates that a player won a jackpot
     */
    event JackpotWin(address player, uint256 amount);

    /**
     * @notice Each milestone reached by the referee increases his bonus percent
     * @dev {bonusPercentMilestones[i]} corresponds to {referersTotalWinningsMilestones[i]} and vice versa
     */
    uint256[7] public referersTotalWinningsMilestones;
    uint256[7] public bonusPercentMilestones;


    /**
     * @dev Equivalent between native token and internal tokens
     *      e.g. 1 ETH (native) = 1_000_000 xETH (internal)
     * NOTE: This is NOT a price. Price is not constant. 
     */
    uint256 internal constant INTERNALS_FOR_NATIVE = 10**6; 

    /**
     * @notice The total amount of tokens stored to be paid as jackpot
     */
    uint256 public totalJackpot;
    /**
     * @notice Amount of tokens freezed to be paid some time in the future
     */
    uint256 public freezedJackpot;
    /**
     * @notice The maximum amount of tokens to be stored for jackpot payments
     */
    uint256 public jackpotLimit;

    /**
     * @notice All account taking part in the referral program
     */
    mapping(address => RefAccount) public refAccounts;
    /**
     * @notice The list of addresses that can deposit funds into the pool
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
            "PoolController: invalid xTRX token address!"
        );

        // TODO maybe take all of this as arguments for constructor
        pool.internalToken = internalCandidate;
        pool.oracleGasFee = 3000000;
        whitelist[_msgSender()] = true;
        referersTotalWinningsMilestones = [
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
     * @notice Returns referral program winnings milestones
     * @return Referral program winnings milestones
     */
    function getTotalWinningsMilestones()
        external
        view
        returns (uint256[7] memory)
    {
        return referersTotalWinningsMilestones;
    }

    /**
     * @notice Returns referral program bonus percent milestones
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
     * @notice Returns the address of the game that is using this pool controller
     * @return The address of the game that is using this pool controller 
     */
    function getGame() external view returns (address) {
        return address(_game);
    }

    /**
     * @notice Should be called by other contracts to check that the contract with the given
     *        address supports the {IPool} interface
     * @return Always True
     */
    function supportsIPool() external pure returns (bool) {
        return true;
    }

    /**
     * @notice Calculates the amount of native tokens ready to be withdrawn from the pool based
     *        on the provided amount of internal tokens
     * @param internalTokensAmount The amount of internal tokens used to calculate the withdrawable amount of native tokens
     * @return The withdrawable amount of native tokens
     */
    function getWithDrawableNatives(uint256 internalTokensAmount) external view returns (uint256) {
        // 1. internalTokensAmount.div(INTERNALS_FOR_NATIVE) - The equivalent of how many native tokens was provided as internal tokens in the parameter
        // 2. (1).mul(_realNativePrice()) - Calibrate the amount on native tokens based on the real price of the native tokens
        return internalTokensAmount.mul(_realNativePrice()).div(INTERNALS_FOR_NATIVE);
    }

    /**
     * @notice Returns information about the current pool
     * @return - The Address of internal token
     *         - The total amount of native tokens paid to the pool
     *         - The gas fee paid for oracle services
     *         - The total amount of fees paid to the 
     */
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
            pool.nativeTokensTotal,
            pool.oracleGasFee,
            pool.oracleTotalGasFee
        );
    }


    /**
     * @notice Returns the total amount of native tokens paid to the pool
     * @return The total amount of native tokens paid to the pool
     */
    function getNativeTokensTotal() external view returns (uint256) {
        return pool.nativeTokensTotal;
    }

    /**
     * @notice Returns the address of the internal token of the pool
     * @return The address of the internal token of the pool
     */
    function getTokenAddress() external view returns (address) {
        return address(pool.internalToken);
    }

    /**
     * @notice Returns the gas fee paid for oracle services
     * @return The gas fee paid for oracle services
     */
    function getOracleGasFee() external view returns (uint256) {
        return pool.oracleGasFee;
    }


    /**
     * @notice Returns the address of the oracle operator
     * @return The address of the oracle operator
     */
    function getOracleOperator() external view returns (address) {
        return _oracleOperator;
    }


    /**
     * @notice Shows information about the referral program referee
     * @param referee The address of the referee to check
     * @return - The address of the referee's parent
     *         - The bonus percent for the referee
     * TODO what's the difference between the two?
     *         - The total amount of tokens won while using referral program
     *         - The ???
     */
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
            refAccounts[referee].referersTotalWinnings,
            refAccounts[referee].referralEarningsBalance,
            refAccounts[referee].referralCounter
        );
    }

    /**
     * @notice Sets new milestones for referral program winnings
     * @param newTotalWinningMilestones New milestones to be set
     */
    function setTotalWinningsMilestones(
        uint256[] calldata newTotalWinningMilestones
    ) external onlyOwner {
        for (uint256 i = 0; i < 7; i++) {
            referersTotalWinningsMilestones[i] = newTotalWinningMilestones[i];
        }
    }
    /**
     * @notice Sets new milestones for bonus percents of the referral program winnings
     * @param newBonusPercents New milestones to be set
     */
    function setBonusPercentMilestones(uint256[] calldata newBonusPercents)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < 7; i++) {
            bonusPercentMilestones[i] = newBonusPercents[i];
        }
    }

    /**
     * @notice Changes the jackpot amount of the game
     * @param jackpot The new jackpot
     */
    function setJackpot(uint256 jackpot) external onlyOwner {
        totalJackpot = jackpot;
    }

    /**
     * @notice Changes the jackpot limit of the game
     * @param jackpotLimit_ The new jackpot limit
     */
    function setJackpotLimit(uint256 jackpotLimit_) external onlyOwner {
        jackpotLimit = jackpotLimit_;
    }

    /**
     * @notice Adds the provided amount of tokens to the jackpot
     * @param amount The amount of tokens to add to jackpot
     */
    function addToJackpot(uint256 amount) external onlyGame {
        totalJackpot = totalJackpot.add(amount);
    }

    /**
     * TODO
     * @notice Locks a part of jackpot to be paid to the player later in the future
     * @param amount The amount of tokens to lock
     */
    function freezeJackpot(uint256 amount) external onlyGame {
        // TODO why isn't here `totalJackpot.sub(amount)`
        // TODO aren't freezed tokens withdrawn from total jackpot?
        freezedJackpot = freezedJackpot.add(amount);
    }

    /**
     * @notice Returns the amount of non-freezed jackpot available
     * @return The amount of available jackpot
     */
    function getAvailableJackpot() public view returns (uint256) {
        return totalJackpot.sub(freezedJackpot);
    }

    /**
     * @notice Receives tokens from game and stores them on the contract's balance
     */
     // TODO why there's no `onlyGame` here? 
    function receiveFundsFromGame() external payable {}

    /**
     * @notice Pays the prize to the jackpot winner
     * @param player The jackpot winner address
     * @param prize The prize to pay
     */
    function jackpotDistribution(address payable player, uint256 prize)
        external
        onlyGame
    {   
        // Prize to be paid is subtracted from the total jackpot
        totalJackpot = totalJackpot.sub(prize);
        // TODO Shouldn't `freezedJackpot` be a part of `totalJackpot`?
        // Prize to be paid is subtracted from the freezed jackpot
        freezedJackpot = freezedJackpot.sub(prize);
        _rewardDistribution(player, prize);
        emit JackpotWin(player, prize);
    }

    /**
     * @notice Updates referral program information of the referee of the provided member (referer)
     * @param referer The member taking part on the referral program
     * @param winAmount The amount the referer won in the game
     * @param refAmount The amount used to calculcate the payment for the refere
     */
    function updateRefereeStats(
        address referer,
        uint256 winAmount,
        uint256 refAmount 
    ) external onlyGame {
        // Get the parent (referee) of the current member (referer) and update his stats
        address parent = refAccounts[referer].parent;
        // Add referer's winnings
        refAccounts[parent].referersTotalWinnings = refAccounts[parent]
            .referersTotalWinnings
            .add(winAmount);
        _updateReferralBonusPercent(parent);
        // Add referral amount to the earnings
        uint256 referralEarnings = refAmount
            .mul(refAccounts[parent].bonusPercent)
            .div(_percentDivider);
        refAccounts[parent].referralEarningsBalance = refAccounts[parent]
            .referralEarningsBalance
            .add(referralEarnings);
    }

    /**
     * @notice Adds bet to the pool and pays oracle for services
     * @param betAmount The bet to add to the pool
     */
    function addBetToPool(uint256 betAmount) external payable onlyGame {
        uint256 oracleGasFee = pool.oracleGasFee;
        pool.nativeTokensTotal = pool.nativeTokensTotal.add(betAmount).sub(oracleGasFee);
        pool.oracleTotalGasFee = pool.oracleTotalGasFee.add(oracleGasFee);
    }

    /**
     * @notice Pays the prize to the player
     * @param player The player receiving the prize
     * @param prize The prize to be paid
     */
    function rewardDistribution(address payable player, uint256 prize)
        public
        onlyGame
    {
        _rewardDistribution(player, prize);
    }

    /**
     * TODO Shouldn't it have any modifiers?S
     * @notice Transfers referral earnings of the referee to the provided player
     * @param player The receiver of withdrawn referral earnings
     */
    function withdrawReferralEarnings(address payable player) external {
        uint256 reward = refAccounts[player].referralEarningsBalance;
        refAccounts[player].referralEarningsBalance = 0;
        _rewardDistribution(player, reward);
    }

    /**
     * @notice Deposits the provided amount of native tokens to the pool
     * @param to The address of the staker inside the pool to mint internal tokens to
     */
    function deposit(address to) external payable {
        require(
            whitelist[_msgSender()],
            "PoolController: deposit is forbidden for the caller!"
        );
        _deposit(to, msg.value);
    }

    /**
     * @notice Withdraws the amount of native tokens from the pool equal to the provided amount of internal tokens of the pool
     * @param internalTokensAmount The amount of internal tokens used to calculate the amount of native tokens to be withdrawn
     */
    function withdraw(uint256 internalTokensAmount) external {
        require(
            pool.internalToken.balanceOf(_msgSender()) >= internalTokensAmount,
            "PoolController: amount exceeds token balance!"
        );
        // NOTE The real logical order of operations:
        // 1. internalTokensAmount.div(INTERNALS_FOR_NATIVE) - The equivalent of how many native tokens was provided as internal tokens in the parameter
        // 2. (1).mul(_realNativePrice()) - Calibrate the amount on native tokens based on the real price of the native tokens
        uint256 withdrawAmount = internalTokensAmount.mul(_realNativePrice()).div(INTERNALS_FOR_NATIVE);
        pool.nativeTokensTotal = pool.nativeTokensTotal.sub(withdrawAmount);
        payable(_msgSender()).transfer(withdrawAmount);
        pool.internalToken.burnTokenFrom(_msgSender(), internalTokensAmount);
    }

    /**
     * @notice Adds an account to the whitelist
     * @param account The account to add to the whitelist
     */
    function addToWhitelist(address account) public onlyOwner {
        require(!whitelist[account], "PoolController: account is already in the whitelist");
        whitelist[account] = true;
    }

    /**
     * @notice Removes the account from the whitelist
     * @param account The account to remove from the whitelist
     */
    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
    }

    /**
     * @notice Changes the address of the game using this pool controller
     * @param gameAddress The new address of the game
     */
    function setGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        _game = game;
    }

    /**
     * @notice Changes oracle gas fee
     * @param oracleGasFee A new oracle gas fee
     */
    function setOracleGasFee(uint256 oracleGasFee) external onlyOwner {
        pool.oracleGasFee = oracleGasFee;
    }

    /**
     * @notice Changes the oracle operator
     * @param oracleOperator The address of the new oracle operator
     */
    function setOracleOperator(address oracleOperator) external onlyOwner {
        _oracleOperator = oracleOperator;
    }

    /**
     * @notice Transfers oracle gas fee to the oracle operator and resets the fee
     */
    function takeOracleFee() external onlyOracleOperator {
        uint256 oracleTotalGasFee = pool.oracleTotalGasFee;
        pool.oracleTotalGasFee = 0;
        payable(_msgSender()).transfer(oracleTotalGasFee);
    }

    /**
     * @notice Adds a new referer to the referee in the referral program
     * @param parent The address of the referee
     * @param son The address of the referer
     * TODO rename args to "referee" and "referer"
     */
    function addReferer(address parent, address son) external {
        require(
            refAccounts[son].parent == address(0),
            "PoolController: this address is already a referer!"
        );
        require(parent != son, "PoolController: referee and referer can not have the same address!");
        refAccounts[son].parent = parent;
        refAccounts[parent].referralCounter = refAccounts[parent]
            .referralCounter
            .add(1);
        emit RegisteredReferer(parent, son);
    }

    /**
     * @dev Mints the amount of interanl tokens equal to the amount of native tokens into the pool
     * @param staker The address to mint internal tokens to
     * @param nativeTokensAmount The amount of native tokens (e.g. wei)
     */
    function _deposit(address staker, uint256 nativeTokensAmount) internal {
        // 1. nativeTokensAmount.mul(INTERNALS_FOR_NATIVE) - The equivalent of how many internal tokens was provided as native tokens
        // 2. (1).div(_realNativePrice()) - Calibrate the amount on internal tokens based on the real price of the native tokens
        uint256 tokenAmount = nativeTokensAmount.mul(INTERNALS_FOR_NATIVE).div(_realNativePrice());
        pool.nativeTokensTotal = pool.nativeTokensTotal.add(nativeTokensAmount);
        pool.internalToken.mint(staker, tokenAmount);
    }

    /**
     * @notice Checks the amount of tokens a referer won in total and updates 
     *        a bonus percent of his referee
     * @param parent The address of the referee
     */
    function _updateReferralBonusPercent(address parent) internal {
        uint256 currentBonusPercent;
        for (uint256 i = 0; i < referersTotalWinningsMilestones.length; i++) {
            if (
                // If referees total winnings are greater than the milestone,
                // the bonus percent increases
                referersTotalWinningsMilestones[i] < refAccounts[parent].referersTotalWinnings
            ) {
                currentBonusPercent = bonusPercentMilestones[i];
            }
        }
        refAccounts[parent].bonusPercent = currentBonusPercent;
    }

    /**
     * @dev Calculates the price of a signle native token in internal tokens
     * @return The price of a single native tokens in internal tokens
     */
    function _realNativePrice() internal view returns (uint256) {
        // If no internal tokens were minted, the price is equal to the "constant price"
        if (pool.internalToken.totalSupply() == 0) {
            return INTERNALS_FOR_NATIVE;
        }
        // With each minted internal token the price changes
        // 1. (pool.nativeTokensTotal).mul(INTERNALS_FOR_NATIVE) - Equivalent of how many internal tokens is stored as native tokens in the pool
        // 2. (1).div(pool.internalToken.totalSupply()) - Ratio between internal tokens in the pool and the total amount of internal tokens in existence
        return (pool.nativeTokensTotal).mul(INTERNALS_FOR_NATIVE).div(pool.internalToken.totalSupply());
    }

    /**
     * @dev Pays the prize to the provided address
     * @param player The player to pay the prize to
     * @param prize The prize to pay
     */
    function _rewardDistribution(address payable player, uint256 prize)
        internal
    {
        require(
            prize <= address(this).balance,
            "PoolControoller: not enough funds to pay the reward!"
        );
        require(prize <= pool.nativeTokensTotal, "PoolControoller: not enough funds in the pool!");
        pool.nativeTokensTotal = pool.nativeTokensTotal.sub(prize);
        player.transfer(prize);
    }
}
