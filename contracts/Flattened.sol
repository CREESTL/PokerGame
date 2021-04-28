// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Interfaces.sol

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
    function acceptRandomNumberRequest(uint256 requestId) external;
}

// File: contracts/Oracle.sol

pragma solidity >0.4.18 < 0.6.0;





contract Oracle is IOracle, Ownable {
    IGame internal _games;
    address internal _operator;
    string internal _owner;
    uint256 internal _nonce;

    mapping(uint256 => bool) internal _pendingRequests;

    event RandomNumberRequestEvent(address indexed callerAddress, uint256 indexed requestId);
    event RandomNumberEvent(uint bitCards, address indexed callerAddress, uint256 indexed requestId);

    modifier onlyGame(address sender) {
        require(sender == address(_games), "caller is not allowed to do some");
        _;
    }

    modifier onlyOperator() {
        require(_msgSender() == _operator, "caller is not the operator");
        _;
    }

    constructor (address operatorAddress) public {
        _nonce = 0;
        _setOperatorAddress(operatorAddress);
    }

    function supportsIOracle() external view returns (bool) {
        return true;
    }

    function getOperatorAddress() external view onlyOwner returns (address) {
        return _operator;
    }

    function setOperatorAddress(address operatorAddress) external onlyOwner {
        _setOperatorAddress(operatorAddress);
    }

    function setGame(address gameAddress) external onlyOwner {
        IGame game = IGame(gameAddress);
        _games = game;
    }

    function getPendingRequests(uint256 requestId) external view onlyOwner returns (bool) {
        return _pendingRequests[requestId];
    }

    function createRandomNumberRequest() external onlyGame(_msgSender()) returns (uint256) {
        uint256 requestId = 0;
        do {
            _nonce++;
            requestId = uint256(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _nonce)));
        } while (_pendingRequests[requestId]);
        _pendingRequests[requestId] = true;
        return requestId;
    }

    function acceptRandomNumberRequest(uint256 requestId) external onlyGame(_msgSender()) {
        emit RandomNumberRequestEvent(_msgSender(), requestId);
    }

    function publishRandomNumber(uint8[] calldata cards, address callerAddress, uint256 requestId) external onlyOperator {
        require(_pendingRequests[requestId], "request isn't in pending list");
        delete _pendingRequests[requestId];

        uint bitCards = toBit(cards);
        IGame(callerAddress).__callback(cards, requestId, bitCards);
        emit RandomNumberEvent(bitCards, callerAddress, requestId);
    }

    function getGame() public view returns (address) {
        return address(_games);
    }

    function toBit(uint8[] memory cards) public pure returns(uint) {
        uint bitCards;
        for (uint i = 0; i < cards.length; i++) {
            bitCards |= (uint256(cards[i]) << (6 * i));
        }
        return bitCards;
    }

    function _setOperatorAddress(address operatorAddress) internal {
        require(operatorAddress != address(0), "invalid operator address");
        _operator = operatorAddress;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

// File: contracts/PoolController.sol

pragma solidity >=0.4.4 < 0.6.0;








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
    uint256[7] private _totalWinningsMilestones;
    uint256[7] private _bonusPercentMilestones;

    uint256 private constant PERCENT100 = 10 ** 6; // 100 %

    // jackpot
    uint256 private _jackpot;
    uint256 private _jackpotLimit; 

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
    // maybe take all of this as arguments for constructor
    constructor (
        address xEthTokenAddress
    ) public {
        IInternalToken xEthCandidate = IInternalToken(xEthTokenAddress);
        require(xEthCandidate.supportsIInternalToken(), "invalid xETH address");
        pool.internalToken = xEthCandidate;
        pool.oracleGasFee = 12000000;
        whitelist[_msgSender()] = true;
        _totalWinningsMilestones = [0, 20000000000, 60000000000, 100000000000, 140000000000, 180000000000, 220000000000];
        _bonusPercentMilestones = [1, 2, 4, 6, 8, 10, 12];
        _jackpot = 500000; // TODO: change to 78000000000 on deploy for test/prod
        _jackpotLimit = 1000000; // TODO: change to 1950000000000 on deploy for test/prod
    }

    function getTotalWinningsMilestones() external view returns(uint[7] memory) {
        return _totalWinningsMilestones;
    }

    function getBonusPercentMilestones() external view returns(uint[7] memory) {
        return _bonusPercentMilestones;
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

    // setters
    function setTotalWinningsMilestones(uint256[] calldata newTotalWinningMilestones) external onlyOwner {
        for(uint256 i = 0; i < 7; i++) {
            _totalWinningsMilestones[i] = newTotalWinningMilestones[i];
        }
    }

    function setBonusPercentMilestones(uint256[] calldata newBonusPercent) external onlyOwner {
        for(uint256 i = 0; i < 7; i++) {
            _bonusPercentMilestones[i] = newBonusPercent[i];
        }
    }

    function setJackpot(uint256 jackpot) external onlyOwner {
        _jackpot = jackpot;
    }

    function setJackpotLimit(uint256 jackpotLimit) external onlyOwner {
        _jackpotLimit = jackpotLimit;
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

    function updateReferralStats(address referral, uint256 amount, uint256 betEdge) external onlyGame {
        // update data first for correct referralEarningsBalance distribution
        address parent = refAccounts[referral].parent;
        refAccounts[parent].totalWinnings = refAccounts[parent].totalWinnings.add(amount);
        _updateReferralBonusRank(parent);

        uint256 referralEarnings = betEdge.mul(refAccounts[parent].bonusPercent).div(100);
        refAccounts[parent].referralEarningsBalance = refAccounts[parent].referralEarningsBalance.add(referralEarnings);
            
    }

    function addBetToPool(uint256 betAmount) external onlyGame payable {
        uint256 oracleFeeAmount = pool.oracleGasFee;
        pool.amount = pool.amount.add(betAmount).sub(oracleFeeAmount);
        pool.oracleFeeAmount = pool.oracleFeeAmount.add(oracleFeeAmount);
    }

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
        require(refAccounts[son].parent == address(0), "Already a referral");
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
        for (uint i = 0; i < _totalWinningsMilestones.length; i++) {
            if (_totalWinningsMilestones[i] < refAccounts[parent].totalWinnings) {
                currentBonus = _bonusPercentMilestones[i];
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
        player.transfer(prize);
        return true;
    }
}

// File: contracts/GameController.sol

pragma solidity >0.4.18 < 0.6.0;





contract GameController is IGame, Ownable {
    using SafeMath for uint256;

    enum Status { Unknown, Pending, Result }

    struct Numbers {
        uint8[] result;
        uint64 timestamp;
        Status status;
    }

    uint256 constant private MIN_TIME_TO_HISTORY_OF_REQUESTS = 7 * 86400; // 1 week

    IOracle internal _oracle;
    uint256 internal _lastRequestId;
    mapping(uint256 => Numbers) internal _randomNumbers; // requestId -> Numbers

    modifier onlyOracle() {
        require(msg.sender == address(_oracle), "caller is not the oracle");
        _;
    }

    constructor (address oracleAddress) public {
        _setOracle(oracleAddress);
    }

    function supportsIGame() external view returns (bool) {
        return true;
    }

    function getOracle() external view returns (address) {
        return address(_oracle);
    }

    function setOracle(address oracleAddress) external onlyOwner {
        _setOracle(oracleAddress);
    }

    function getLastRequestId() external view onlyOwner returns (uint256) {
        return _lastRequestId;
    }

    function __callback(uint8[] calldata cards, uint256 requestId, uint256 bitCards) external onlyOracle {
        Numbers storage number = _randomNumbers[requestId];
        number.timestamp = uint64(block.timestamp);
        require(number.status == Status.Pending, "request already closed");
        number.status = Status.Result;
        number.result = cards;
        _publishResults(cards, requestId, bitCards);
    }

    function _updateRandomNumber() internal {
        uint256 requestId = _oracle.createRandomNumberRequest();
        require(_randomNumbers[requestId].timestamp <= (uint64(block.timestamp) - MIN_TIME_TO_HISTORY_OF_REQUESTS), "requestId already used");
        _oracle.acceptRandomNumberRequest(requestId);
        _randomNumbers[requestId].status = Status.Pending;
        _lastRequestId = requestId;
    }

    function _setOracle(address oracleAddress) internal {
        IOracle iOracleCandidate = IOracle(oracleAddress);
        require(iOracleCandidate.supportsIOracle(), "invalid IOracle address");
        _oracle = iOracleCandidate;
    }

    function _publishResults(uint8[] memory cards, uint256 gameId, uint256 bitCards) internal {}
}

// File: contracts/Poker.sol

pragma solidity >0.4.18 < 0.6.0;

// import "@openzeppelin/contracts/lifecycle/Pausable.sol";




contract Poker is GameController {
    using SafeMath for uint256;
    using SafeMath for uint8;

    enum GameResults { Lose, Draw, Win, Jackpot }

    struct Hand {
        uint8[7] ranks;
        uint8[7] cards;
        int8[7] kickers;
        uint8 hand;
    }

    struct Game {
        // uint id;
        uint256 betColor;
        uint256 betPoker;
        uint256 chosenColor;
        address payable player;
    }

    // maxbet calc
    uint256 internal _gamesCounter;
    uint256 internal _betFlip;
    uint256 internal _betColor;
    uint256 internal _betFlipSquare;
    uint256 internal _betColorSquare;
    uint256 internal _betFlipVariance;
    uint256 internal _betColorVariance;
    uint256 internal _maxBet;

    uint256 private _houseEdge;
    uint256 private _jackpotFeeMultiplier;
    address payable private _poolControllerPayable;

    event PokerResult(uint256 winAmount, bool winColor, GameResults winPoker, uint256 requestId, uint256 cards, address player);
    event GameStart(address player, uint256 requestId, uint256 betPoker, uint256 betColor, uint256 chosenColor);

    IPool private _poolController;
    mapping(uint256 => Game) private games;

    constructor (address oracleAddress, address poolControllerAddress) public GameController(oracleAddress){
        _setPoolController(poolControllerAddress);
        _houseEdge = 15;
        _jackpotFeeMultiplier = 2;
        _poolControllerPayable = address(uint160(poolControllerAddress));
        // pause();
    }

    function getMaxBet() external view returns(uint256) {
        return _maxBet;
    }

    function getPoolController() external view returns(address) {
        return address(_poolController);
    }

    function getHouseEdge() external view returns(uint256) {
        return _houseEdge;
    }
    function getJackpotFeeMultiplier() external view returns(uint256) {
        return _jackpotFeeMultiplier;
    }

    function getGameInfo(uint256 requestId) external view returns (uint256, uint256, uint256, address) {
        return (
            games[requestId].betColor,
            games[requestId].betPoker,
            games[requestId].chosenColor,
            games[requestId].player
        );
    }

    function setPoolController(address poolControllerAddress) external onlyOwner {
        _setPoolController(poolControllerAddress);
    }

    // function pauseGame() external onlyOwner {
    //     pause();
    // }

    // function unPauseGame() external onlyOwner {
    //     unpause();
    // }

    function setMaxBet(uint256 maxBet) external onlyOwner {
        _maxBet = maxBet;
    }

    function setHouseEdge(uint256 houseEdge) external onlyOwner {
        _houseEdge = houseEdge;
    }

    function setJackpotFeeMultiplier(uint256 jackpotFeeMultiplier) external onlyOwner {
        _jackpotFeeMultiplier = jackpotFeeMultiplier;
    }

    function play(uint256 betColor, uint256 chosenColor) external payable {
        uint256 betPoker = uint256(msg.value.sub(betColor));
        _maxBetCalc(betPoker, betColor);
        uint256 gasFee = _poolController.getOracleGasFee();
        require(msg.value > gasFee.mul(1015).div(1000), 'Bet too small');
        require(msg.value < _maxBet, 'Bet too big');
        address payable player = msg.sender;
        _poolController.addBetToPool.value(msg.value)(msg.value);
        // if (_randomNumbers[_lastRequestId].status != Status.Pending) {
        super._updateRandomNumber();
        // }
        emit GameStart(player, _lastRequestId, betPoker, betColor, chosenColor);
        games[_lastRequestId] = Game(
            betColor,
            betPoker,
            chosenColor,
            player);
    }

    function getLastGamePlayer() external view returns(address) {
        return games[_lastRequestId].player;
    }

    function _publishResults(uint8[] memory cards, uint256 requestId, uint256 bitCards) internal {
        uint256 winAmount = 0;
        uint256 betColorEdge;
        uint256 jackPotAdder = games[requestId].betPoker.mul(_jackpotFeeMultiplier).div(1000);
        uint256 betPokerEdge = games[requestId].betPoker.mul(_houseEdge).div(1000);
        bool colorWin = false;
        _poolController.updateJackpot(jackPotAdder);
        if (games[requestId].betColor > 0) {
            uint8[] memory colorCards = new uint8[](3);
            for (uint256 i = 2; i < 5; i++) {
                colorCards[i - 2] = cards[i];
            }
            if (_determineWinnerColor(colorCards, games[requestId].chosenColor)) {
                betColorEdge = games[requestId].betColor.mul(_houseEdge).div(1000);
                winAmount = games[requestId].betColor.mul(_jackpotFeeMultiplier).sub(betColorEdge);
                colorWin = true;
            }
        }
        GameResults winPoker = _setCards(cards);

        if (winPoker == GameResults.Draw) {
            winAmount = winAmount.add(games[requestId].betPoker.sub(betPokerEdge + jackPotAdder));
        } else if (winPoker == GameResults.Win) {
            winAmount = winAmount.add(games[requestId].betPoker.mul(2).sub(betPokerEdge + jackPotAdder));
        } else if (winPoker == GameResults.Jackpot) {
            _poolController.jackpotDistribution(games[requestId].player);
        }

        if (winAmount > 0) {
            _poolController.rewardDisribution(games[requestId].player, winAmount);
            if (winPoker != GameResults.Draw) {
                _poolController.updateReferralStats(games[requestId].player, winAmount, betPokerEdge.add(betColorEdge));
            }
        }
        emit PokerResult(winAmount, colorWin, winPoker, requestId, bitCards, games[requestId].player);
    }

    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(poolCandidate.supportsIPool(), "poolAddress must be IPool");
        _poolController = poolCandidate;
    }

    function _setCards(uint8[] memory _cardsArray) private pure returns(GameResults) {
        Hand memory player;
        Hand memory computer;
        for (uint256 i = 0; i < _cardsArray.length; i++) {
            if (i < 7) { // player cards 0 - 6
                player.cards[i] = _cardsArray[i];
                player.ranks[i] = _cardsArray[i] % 13;
            }
            if (i > 1) { // computer cards 2 - 8
                computer.cards[i - 2] = _cardsArray[i];
                computer.ranks[i - 2] = _cardsArray[i] % 13;
            }
        }
        _sort(player.ranks, player.cards, 0, 6);
        _sort(computer.ranks, computer.cards, 0, 6);
        (player.hand, player.kickers) = _evaluateHand(player.cards, player.ranks);
        (computer.hand, computer.kickers) = _evaluateHand(computer.cards, computer.ranks);
        return _determineWinnerPoker(
            player.hand,
            player.kickers,
            computer.hand,
            computer.kickers);
    }

    function _sort(
        uint8[7] memory dataRanks,
        uint8[7] memory dataCards,
        uint256 low,
        uint256 high) private pure
    {
        if (low < high) {
            uint256 pivotVal = dataRanks[(low + high) / 2];
            uint256 low1 = low;
            uint256 high1 = high;
            for (;;) {
                while (dataRanks[low1] > pivotVal) low1++;
                while (dataRanks[high1] < pivotVal) high1--;
                if (low1 >= high1) break;
                (dataRanks[low1], dataRanks[high1]) = (dataRanks[high1], dataRanks[low1]);
                (dataCards[low1], dataCards[high1]) = (dataCards[high1], dataCards[low1]);
                low1++;
                high1--;
            }
            if (low < high1) _sort(dataRanks,dataCards, low, high1);
            high1++;
            if (high1 < high) _sort(dataRanks,dataCards, high1, high);
        }
    }

    function _determineWinnerPoker(
        uint8 playerHand,
        int8[7] memory playerKickers,
        uint8 computerHand,
        int8[7] memory computerKickers
    ) private pure returns (GameResults)
    {
        if (playerHand > computerHand) {
            if (playerHand == 9) return GameResults.Jackpot;
            return GameResults.Win;
        }
        if (playerHand == computerHand) {
            for (uint256 i = 0; i < 7; i++) {
                if (playerKickers[i] > computerKickers[i]) return GameResults.Win;
                if (playerKickers[i] < computerKickers[i]) return GameResults.Lose;
            }
            return GameResults.Draw;
        }
        return GameResults.Lose;
    }

    function _determineWinnerColor(uint8[] memory colorCards, uint256 chosenColor) private pure returns (bool) {
        uint256 colorCounter = 0;
        for (uint256 i = 0; i < colorCards.length; i++) {
            if ((colorCards[i] / 13) % 2 == chosenColor) {
                colorCounter++;
            }
            if (colorCounter >= 2) return true;
        }
        return false;
    }

    function _evaluateHand(uint8[7] memory cardsArray, uint8[7] memory ranksArray) private pure returns (uint8, int8[7] memory) {
        uint8 strongestHand = 0;
        // get kickers
        int8[7] memory retOrder = [-1, -1, -1, -1, -1, -1, -1];
        // check for flush
        uint8[4] memory suits = [0, 0, 0, 0];
        // check for pairs, 3oaK, 4oaK
        uint8[13] memory valuesMatch = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // for loop
        uint256 i;
        // write pairs and triples, triple always 1st
        int8[2] memory pairs = [-1, -1];
        uint256 streetChecker = 1;
        // check for street flush
        uint256 flushWinSuit;
        int8[7] memory streetFlushCards = [-1, -1, -1, -1, -1, -1, -1];

        for (i = 0; i < 7; i++) {
            valuesMatch[ranksArray[i]]++;
            // check for street
            if (i < 6) {
                if (ranksArray[i] == ranksArray[i + 1] + 1) {
                    streetChecker++;
                    if (streetChecker == 5) {
                        strongestHand = 4;
                        retOrder[0] = int8(ranksArray[i + 1]) + 4;
                    }
                }
                if (ranksArray[i] > ranksArray[i + 1] + 1) {
                    streetChecker = 1;
                }
            }
            // check for 4oaK
            if (valuesMatch[ranksArray[i]] == 4 && strongestHand < 7) {
                strongestHand = 7;
                retOrder[0] = int8(ranksArray[i]);
                break;
                // check for 3oaK
            } else if (valuesMatch[ranksArray[i]] == 3 && strongestHand < 3) {
                strongestHand = 3;
                retOrder[0] = int8(ranksArray[i]);
            } else if (valuesMatch[ranksArray[i]] == 2) {
                if (pairs[0] == -1) {
                    pairs[0] = int8(ranksArray[i]);
                } else if (pairs[1] == -1) {
                    pairs[1] = int8(ranksArray[i]);
                }
            }
            suits[(cardsArray[i] / 13)]++;
        }

        if (strongestHand == 7) {
            for (i = 0; i < 7; i++) {
                // find kicker
                if (int8(ranksArray[i]) != retOrder[0]) {
                    retOrder[1] = int8(ranksArray[i]);
                    return (strongestHand, retOrder);
                }
            }
        }
    
        // check for flush
        if (strongestHand < 5) {
            for (i = 0; i < 4; i++) {
                if (suits[i] >= 5) {
                    flushWinSuit = i;
                    uint8 cnt = 0;
                    for (i = 0; i < 7; i++) {
                        if (cardsArray[i] / 13 == flushWinSuit) {
                            streetFlushCards[cnt] = int8(ranksArray[i]);
                            retOrder[cnt] = int8(ranksArray[i]);
                            cnt++;
                            retOrder[6] = 50;
                        }
                    }
                    if (strongestHand == 4) {
                        for (i = 0; i < 3; i++) {
                            if (streetFlushCards[i] - streetFlushCards[i + 4] == 4 && streetFlushCards[i + 4] != -1) {
                                strongestHand = 8;
                                retOrder = [int8(streetFlushCards[i]), -1, -1, -1, -1, -1, -1];
                                if (streetFlushCards[i] == 12) {
                                    strongestHand = 9;
                                }
                                return (strongestHand, retOrder);
                            } 
                        }
                    }
                    strongestHand = 5;
                    retOrder[5] = -1;
                    retOrder[6] = -1;
                    return (strongestHand, retOrder);
                }
            }
            
        }
    

        if (strongestHand == 3) {
            // check for full house
            if (pairs[1] > -1) {
                strongestHand = 6;
                if (valuesMatch[uint256(pairs[0])] >= valuesMatch[uint256(pairs[1])]) {
                    // retOrder[0] = pairs[0];
                    retOrder[1] = pairs[1];
                } else {
                    // retOrder[0] = pairs[1];
                    retOrder[1] = pairs[0];
                }
                return (strongestHand, retOrder);
            }
            // check for 3oaK
            for (i = 0; i < 5; i++) {
                // find kickers
                if (int8(ranksArray[i]) != retOrder[0]) {
                    retOrder[i + 1] = int8(ranksArray[i]);
                    if(retOrder[2] != -1) break;
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
                for (i = 0; i < 7; i++) {
                    if (int8(ranksArray[i]) != pairs[0] && int8(ranksArray[i]) != pairs[1]) {
                        retOrder[2] = int8(ranksArray[i]);
                        break;
                    }
                }
                return (strongestHand, retOrder);
            }
            // one pair
            if (pairs[0] != -1) {
                strongestHand = 1;
                retOrder[0] = pairs[0];
                uint8 cnt = 1;
                for (i = 0; i < 7; i++) {
                    if (int8(ranksArray[i]) != pairs[0]) {
                        retOrder[cnt] = int8(ranksArray[i]);
                        cnt++;
                    }
                    if (retOrder[3] != -1) {
                        return (strongestHand, retOrder);
                    }
                }
            } else {
                strongestHand = 0;
                for (i = 0; i < 5; i++) {
                    retOrder[i] = int8(ranksArray[i]);
                }
                return (strongestHand, retOrder);
            }
        }
        return (strongestHand, retOrder);
    }

    function _maxBetCalc(uint pokerB, uint colorB) internal {
        uint256 poolAmount = _poolController.getPoolAmount();
        _gamesCounter = _gamesCounter.add(1);
        if (_gamesCounter == 1) {
            if (_maxBet == 0) _maxBet = poolAmount.div(230);
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

            if (_gamesCounter >= 100 && (Fn < poolAmount.div(230) || Cn < poolAmount.div(230))) {
                _gamesCounter = 0;

                if (_maxBet > poolAmount.div(109)) {
                    _maxBet = poolAmount.div(109);
                    return;
                }

                if (_maxBet < poolAmount.div(230)) {
                    _maxBet = poolAmount.div(230);
                    return;
                }

                if (Fn > Cn) {
                    _maxBet = _maxBet.mul(_maxBet).div(Fn);
                } else {
                    _maxBet = _maxBet.mul(_maxBet).div(Cn);
                }
                
            }
        }
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

// File: contracts/XETHToken.sol

pragma solidity >=0.4.4 < 0.6.0;








contract XETHToken is ERC20Detailed, IInternalToken, ERC20Burnable, Ownable {
    using SafeMath for uint256;

//    mapping (address => bool) internal _burnerAddresses; // TODO: remove all unused code
    address internal _poolController;

//    modifier isBurner() {
//        require(_burnerAddresses[_msgSender()], "Caller is not burner");
//        _;
//    }

    modifier onlyPoolController() {
        require(_msgSender() == _poolController, "Caller is not pool controller");
        _;
    }

    constructor() ERC20Detailed("xEthereum", "xETH", 18) public {
//        _burnerAddresses[_msgSender()] = true;
    }

    function supportsIInternalToken() external view returns (bool) {
        return true;
    }

    function getPoolController() external view returns (address) {
        return _poolController;
    }

    function setPoolController(address poolControllerAddress) external onlyOwner {
        IPool iPoolCandidate = IPool(poolControllerAddress);
        require(iPoolCandidate.supportsIPool(), "Invalid IPool address");
        _poolController = poolControllerAddress;
    }

//    function isBurnAllowed(address account) external view returns(bool) {
//        return _burnerAddresses[account];
//    }
//
//    function addBurner(address account) external onlyOwner {
//        require(!_burnerAddresses[account], "Already burner");
//        require(account != address(0), "Cant add zero address");
//        _burnerAddresses[account] = true;
//    }
//
//    function removeBurner(address account) external onlyOwner {
//        require(_burnerAddresses[account], "Isnt burner");
//        delete  _burnerAddresses[account];
//    }

    function mint(address recipient, uint256 amount) external onlyPoolController {
        _mint(recipient, amount);
    }

//    function burn(uint256 amount) external isBurner {
//        _burn(_msgSender(), amount);
//    }
//
//    function burnFrom(address account, uint256 amount) external isBurner {
//        super.burnFrom(account, amount);
//    }

    function burnTokenFrom(address account, uint256 amount) external onlyPoolController {
        _burn(account, amount);
    }
}

// File: contracts/testContracts/FakePoker.sol

pragma solidity >0.4.18 < 0.6.0;





contract FakePoker is GameController {
    using SafeMath for uint256;
    using SafeMath for uint8;

    enum GameResults { Lose, Draw, Win, Jackpot }

    struct Hand {
        uint8[7] ranks;
        uint8[7] cards;
        int8[7] kickers;
        uint8 hand;
    }

    struct Game {
        // uint id;
        uint256 betColor;
        uint256 betPoker;
        uint256 chosenColor;
        address payable player;
    }

    // maxbet calc
    uint256 public _gamesCounter;
    uint256 public _betFlip;
    uint256 public _betColor;
    uint256 public _betFlipSquare;
    uint256 public _betColorSquare;
    uint256 public _betFlipVariance;
    uint256 public _betColorVariance;
    uint256 public _maxBet;

    event PokerResult(bool winColor, GameResults winPoker, uint256 requestId, uint256 cards, address player);
    event GameStart(address player);

    IPool public _poolController;
    mapping(uint256 => Game) private games;

    constructor (address oracleAddress, address poolControllerAddress) public GameController(oracleAddress){
        _setPoolController(poolControllerAddress);
        // pause();
    }

    function getMaxBet() external view returns(uint) {
        return (_maxBet);
    }

    function getPoolController() external view returns(address) {
        return address(_poolController);
    }

    function getMyAddress() external view returns(address) {
        return(msg.sender);
    }

    function getGameInfo(uint256 requestId) external view returns (uint, uint, uint, address) {
        return (
            games[requestId].betColor,
            games[requestId].betPoker,
            games[requestId].chosenColor,
            games[requestId].player
        );
    }

    function setPoolController(address poolControllerAddress) external onlyOwner {
        _setPoolController(poolControllerAddress);
    }

    // function pauseGame() external onlyOwner {
    //     pause();
    // }

    // function unPauseGame() external onlyOwner {
    //     unpause();
    // }

    function setMaxBet(uint256 maxBet) external onlyOwner {
        _maxBet = maxBet;
    }

    function play(uint256 betColor, uint256 chosenColor) public payable {
        // uint256 gasFee = _poolController.getOracleGasFee();

        // // TODO: maxWin adn maxBet
        // uint256 maxWin = _poolController.maxBet(10); // pseudocode
        // uint256 potentialWin = msg.value.mul(2);
        // require(potentialWin <= maxWin, "incorrectly large bet");

        address payable player = msg.sender;
        emit GameStart(player);
        _poolController.addBetToPool(msg.value);
        if (_randomNumbers[_lastRequestId].status != Status.Pending) {
            super._updateRandomNumber();
        }
        games[_lastRequestId] = Game(
            betColor,
            uint256(msg.value.sub(betColor)),
            chosenColor,
            player);
    }

    function getLastGamePlayer() public view returns(address) {
        return games[_lastRequestId].player;
    }

    function _setPoolController(address poolAddress) internal {
        IPool poolCandidate = IPool(poolAddress);
        require(poolCandidate.supportsIPool(), "poolAddress must be IPool");
        _poolController = poolCandidate;
    }

    function setCards(uint8[] memory _cardsArray) public pure returns(GameResults) {
        Hand memory player;
        Hand memory computer;
        for (uint256 i = 0; i < _cardsArray.length; i++) {
            if (i < 7) { // player cards 0 - 6
                player.cards[i] = _cardsArray[i];
                player.ranks[i] = _cardsArray[i] % 13;
            }
            if (i > 1) { // computer cards 2 - 8
                computer.cards[i - 2] = _cardsArray[i];
                computer.ranks[i - 2] = _cardsArray[i] % 13;
            }
        }
        sort(player.ranks, player.cards, 0, 6);
        sort(computer.ranks, computer.cards, 0, 6);
        (player.hand, player.kickers) = evaluateHand(player.cards, player.ranks);
        (computer.hand, computer.kickers) = evaluateHand(computer.cards, computer.ranks);
        return determineWinnerPoker(
            player.hand,
            player.kickers,
            computer.hand,
            computer.kickers);
    }

    function checkCombinationResult(uint8[] memory _cardsArray) public pure returns(uint256, int8[7] memory, uint256, int8[7] memory, GameResults) {
        Hand memory player;
        Hand memory computer;
        for (uint256 i = 0; i < _cardsArray.length; i++) {
            if (i < 7) { // player cards 0 - 6
                player.cards[i] = _cardsArray[i];
                player.ranks[i] = _cardsArray[i] % 13;
            }
            if (i > 1) { // computer cards 2 - 8
                computer.cards[i - 2] = _cardsArray[i];
                computer.ranks[i - 2] = _cardsArray[i] % 13;
            }
        }
        sort(player.ranks, player.cards, 0, 6);
        sort(computer.ranks, computer.cards, 0, 6);
        (player.hand, player.kickers) = evaluateHand(player.cards, player.ranks);
        (computer.hand, computer.kickers) = evaluateHand(computer.cards, computer.ranks);
        GameResults winPoker = setCards(_cardsArray);
        return (
            player.hand,
            player.kickers,
            computer.hand,
            computer.kickers,
            winPoker
            );
    }

    function sort(
        uint8[7] memory dataRanks,
        uint8[7] memory dataCards,
        uint256 low,
        uint256 high) public pure
    {
        if (low < high) {
            uint256 pivotVal = dataRanks[(low + high) / 2];
            uint256 low1 = low;
            uint256 high1 = high;
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

    function determineWinnerPoker(
        uint8 playerHand,
        int8[7] memory playerKickers,
        uint8 computerHand,
        int8[7] memory computerKickers
    ) public pure returns (GameResults)
    {
        if (playerHand > computerHand) {
            if (playerHand == 9) return GameResults.Jackpot;
            return GameResults.Win;
        }
        if (playerHand == computerHand) {
            for (uint256 i = 0; i < 5; i++) {
                if (playerKickers[i] > computerKickers[i]) return GameResults.Win;
                if (playerKickers[i] < computerKickers[i]) return GameResults.Lose;
            }
            return GameResults.Draw;
        }
        return GameResults.Lose;
    }

    function determineWinnerColor(uint8[] memory colorCards, uint256 chosenColor) public pure returns (bool) {
        uint256 colorCounter = 0;
        for (uint256 i = 0; i < colorCards.length; i++) {
            if ((colorCards[i] / 13) % 2 == chosenColor) {
                colorCounter++;
            }
            if (colorCounter >= 2) return true;
        }
        return false;
    }
    
    function evaluateHand(uint8[7] memory cardsArray, uint8[7] memory ranksArray) public pure returns (uint8, int8[7] memory) {
        uint8 strongestHand = 0;
        // get kickers
        int8[7] memory retOrder = [-1, -1, -1, -1, -1, -1, -1];
        // check for flush
        uint8[4] memory suits = [0, 0, 0, 0];
        // check for pairs, 3oaK, 4oaK
        uint8[13] memory valuesMatch = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        // for loop
        uint256 i;
        // write pairs and triples, triple always 1st
        int8[2] memory pairs = [-1, -1];
        uint256 streetChecker = 1;
        // check for street flush
        uint256 flushWinSuit;
        int8[7] memory streetFlushCards = [-1, -1, -1, -1, -1, -1, -1];

        for (i = 0; i < 7; i++) {
            valuesMatch[ranksArray[i]]++;
            // check for street
            if (i < 6) {
                if (ranksArray[i] == ranksArray[i + 1] + 1) {
                    streetChecker++;
                    if (streetChecker == 5) {
                        strongestHand = 4;
                        retOrder[0] = int8(ranksArray[i + 1]) + 4;
                    }
                }
                if (ranksArray[i] > ranksArray[i + 1] + 1) {
                    streetChecker = 1;
                }
            }
            // check for 4oaK
            if (valuesMatch[ranksArray[i]] == 4 && strongestHand < 7) {
                strongestHand = 7;
                retOrder[0] = int8(ranksArray[i]);
                break;
                // check for 3oaK
            } else if (valuesMatch[ranksArray[i]] == 3 && strongestHand < 3) {
                strongestHand = 3;
                retOrder[0] = int8(ranksArray[i]);
            } else if (valuesMatch[ranksArray[i]] == 2) {
                if (pairs[0] == -1) {
                    pairs[0] = int8(ranksArray[i]);
                } else if (pairs[1] == -1) {
                    pairs[1] = int8(ranksArray[i]);
                }
            }
            suits[(cardsArray[i] / 13)]++;
        }

        if (strongestHand == 7) {
            for (i = 0; i < 7; i++) {
                // find kicker
                if (int8(ranksArray[i]) != retOrder[0]) {
                    retOrder[1] = int8(ranksArray[i]);
                    return (strongestHand, retOrder);
                }
            }
        }
    
        // check for flush
        if (strongestHand < 5) {
            for (i = 0; i < 4; i++) {
                if (suits[i] >= 5) {
                    flushWinSuit = i;
                    uint8 cnt = 0;
                    for (i = 0; i < 7; i++) {
                        if (cardsArray[i] / 13 == flushWinSuit) {
                            streetFlushCards[cnt] = int8(ranksArray[i]);
                            retOrder[cnt] = int8(ranksArray[i]);
                            cnt++;
                            retOrder[6] = 50;
                        }
                    }
                    if (strongestHand == 4) {
                        for (i = 0; i < 3; i++) {
                            if (streetFlushCards[i] - streetFlushCards[i + 4] == 4 && streetFlushCards[i + 4] != -1) {
                                strongestHand = 8;
                                retOrder = [int8(streetFlushCards[i]), -1, -1, -1, -1, -1, -1];
                                if (streetFlushCards[i] == 12) {
                                    strongestHand = 9;
                                }
                                return (strongestHand, retOrder);
                            } 
                        }
                    }
                    strongestHand = 5;
                    retOrder[5] = -1;
                    retOrder[6] = -1;
                    return (strongestHand, retOrder);
                }
            }
            
        }
    

        if (strongestHand == 3) {
            // check for full house
            if (pairs[1] > -1) {
                strongestHand = 6;
                if (valuesMatch[uint256(pairs[0])] >= valuesMatch[uint256(pairs[1])]) {
                    // retOrder[0] = pairs[0];
                    retOrder[1] = pairs[1];
                } else {
                    // retOrder[0] = pairs[1];
                    retOrder[1] = pairs[0];
                }
                return (strongestHand, retOrder);
            }
            // check for 3oaK
            for (i = 0; i < 5; i++) {
                // find kickers
                if (int8(ranksArray[i]) != retOrder[0]) {
                    retOrder[i + 1] = int8(ranksArray[i]);
                    if(retOrder[2] != -1) break;
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
                for (i = 0; i < 7; i++) {
                    if (int8(ranksArray[i]) != pairs[0] && int8(ranksArray[i]) != pairs[1]) {
                        retOrder[2] = int8(ranksArray[i]);
                        break;
                    }
                }
                return (strongestHand, retOrder);
            }
            // one pair
            if (pairs[0] != -1) {
                strongestHand = 1;
                retOrder[0] = pairs[0];
                uint8 cnt = 1;
                for (i = 0; i < 7; i++) {
                    if (int8(ranksArray[i]) != pairs[0]) {
                        retOrder[cnt] = int8(ranksArray[i]);
                        cnt++;
                    }
                    if (retOrder[3] != -1) {
                        return (strongestHand, retOrder);
                    }
                }
            } else {
                strongestHand = 0;
                for (i = 0; i < 5; i++) {
                    retOrder[i] = int8(ranksArray[i]);
                }
                return (strongestHand, retOrder);
            }
        }
        return (strongestHand, retOrder);
    }

    function maxBetCalc(uint pokerB, uint colorB) public {
        uint256 poolAmount = _poolController.getPoolAmount();
        _gamesCounter = _gamesCounter.add(1);
        if (_gamesCounter == 1) {
            if (_maxBet == 0) _maxBet = poolAmount.div(230);
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
            if (_gamesCounter > 2 && Fn < poolAmount.div(230) && Cn < poolAmount.div(230)) {
                if (Fn > Cn) {
                    _maxBet = _maxBet.mul(_maxBet).div(Fn);
                } else {
                    _maxBet = _maxBet.mul(_maxBet).div(Cn);
                }
                _gamesCounter = 0;
                if (_maxBet > poolAmount.div(109)) _maxBet = poolAmount.div(109);
                else if (_maxBet < poolAmount.div(230)) _maxBet = poolAmount.div(230);
            }
        }
    }

    function sqrt(uint x) public pure returns (uint y) { // TODO: move Poker contract
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

// File: contracts/ForFlattened.sol

pragma solidity >0.4.18 < 0.6.0;
