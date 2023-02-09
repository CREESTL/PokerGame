# PoolController





Controls the tokens pool of the game, distributes rewards.        Controls the referral program payments



## Methods

### addBetToPool

```solidity
function addBetToPool(uint256 betAmount) external payable
```

Adds bet to the pool and pays oracle for services



#### Parameters

| Name | Type | Description |
|---|---|---|
| betAmount | uint256 | The bet to add to the pool |

### addReferer

```solidity
function addReferer(address parent, address child) external nonpayable
```

Adds a new referer to the referee in the referral program



#### Parameters

| Name | Type | Description |
|---|---|---|
| parent | address | The address of the referee |
| child | address | The address of the referer |

### addToJackpot

```solidity
function addToJackpot(uint256 amount) external nonpayable
```

Adds the provided amount of tokens to the jackpot



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount of tokens to add to jackpot |

### addToWhitelist

```solidity
function addToWhitelist(address account) external nonpayable
```

Adds an account to the whitelist



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | The account to add to the whitelist |

### deposit

```solidity
function deposit(address to) external payable
```

Deposits the provided amount of native tokens to the pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| to | address | The address of the staker inside the pool to mint internal tokens to |

### freezeJackpot

```solidity
function freezeJackpot(uint256 amount) external nonpayable
```

Locks a part of jackpot to be paid to the player later in the future



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The amount of tokens to lock |

### freezedJackpot

```solidity
function freezedJackpot() external view returns (uint256)
```

Amount of tokens freezed to be paid some time in the future




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getAvailableJackpot

```solidity
function getAvailableJackpot() external view returns (uint256)
```

Returns the amount of non-freezed jackpot available




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The amount of available jackpot |

### getBonusPercentMilestones

```solidity
function getBonusPercentMilestones() external view returns (uint256[7])
```

Returns referral program bonus percent milestones




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[7] | Referral program bonus percent milestones |

### getGame

```solidity
function getGame() external view returns (address)
```

Returns the address of the game that is using this pool controller




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the game that is using this pool controller |

### getNativeTokensTotal

```solidity
function getNativeTokensTotal() external view returns (uint256)
```

Returns the total amount of native tokens paid to the pool




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The total amount of native tokens paid to the pool |

### getOracleGasFee

```solidity
function getOracleGasFee() external view returns (uint256)
```

Returns the gas fee paid for oracle services




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The gas fee paid for oracle services |

### getOracleOperator

```solidity
function getOracleOperator() external view returns (address)
```

Returns the address of the oracle operator




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the oracle operator |

### getPoolInfo

```solidity
function getPoolInfo() external view returns (address, uint256, uint256, uint256)
```

Returns information about the current pool




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | - The Address of internal token         - The total amount of native tokens paid to the pool         - The gas fee paid for oracle services         - The total amount of fees paid to the |
| _1 | uint256 | undefined |
| _2 | uint256 | undefined |
| _3 | uint256 | undefined |

### getReferralStats

```solidity
function getReferralStats(address referee) external view returns (address, uint256, uint256, uint256, uint256)
```

Shows information about the referral program referee



#### Parameters

| Name | Type | Description |
|---|---|---|
| referee | address | The address of the referee to check |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | - The address of the referee&#39;s parent         - The bonus percent for the referee         - The total amount of tokens won while using referral program         - The amount of referers of the referee |
| _1 | uint256 | undefined |
| _2 | uint256 | undefined |
| _3 | uint256 | undefined |
| _4 | uint256 | undefined |

### getTokenAddress

```solidity
function getTokenAddress() external view returns (address)
```

Returns the address of the internal token of the pool




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the internal token of the pool |

### getTotalWinningsMilestones

```solidity
function getTotalWinningsMilestones() external view returns (uint256[7])
```

Returns referral program winnings milestones




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[7] | Referral program winnings milestones |

### getWithDrawableNatives

```solidity
function getWithDrawableNatives(uint256 internalTokensAmount) external view returns (uint256)
```

Calculates the amount of native tokens ready to be withdrawn from the pool based        on the provided amount of internal tokens



#### Parameters

| Name | Type | Description |
|---|---|---|
| internalTokensAmount | uint256 | The amount of internal tokens used to calculate the withdrawable amount of native tokens |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The withdrawable amount of native tokens |

### jackpotDistribution

```solidity
function jackpotDistribution(address payable player, uint256 prize) external nonpayable
```

Pays the prize to the jackpot winner



#### Parameters

| Name | Type | Description |
|---|---|---|
| player | address payable | The jackpot winner address |
| prize | uint256 | The prize to pay |

### jackpotLimit

```solidity
function jackpotLimit() external view returns (uint256)
```

The maximum amount of tokens to be stored for jackpot payments




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### owner

```solidity
function owner() external view returns (address)
```



*Returns the address of the current owner.*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### receiveFundsFromGame

```solidity
function receiveFundsFromGame() external payable
```

Receives tokens from game and stores them on the contract&#39;s balance




### refAccounts

```solidity
function refAccounts(address) external view returns (address parent, uint256 bonusPercent, uint256 referersTotalWinnings, uint256 referralEarningsBalance, uint256 referralCounter)
```

All account taking part in the referral program



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| parent | address | undefined |
| bonusPercent | uint256 | undefined |
| referersTotalWinnings | uint256 | undefined |
| referralEarningsBalance | uint256 | undefined |
| referralCounter | uint256 | undefined |

### refereesBonusPercentMilestones

```solidity
function refereesBonusPercentMilestones(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### referersTotalWinningsMilestones

```solidity
function referersTotalWinningsMilestones(uint256) external view returns (uint256)
```

Each milestone reached by the referee increases his bonus percent

*{refereesBonusPercentMilestones[i]} corresponds to {referersTotalWinningsMilestones[i]} and vice versa*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### removeFromWhitelist

```solidity
function removeFromWhitelist(address account) external nonpayable
```

Removes the account from the whitelist



#### Parameters

| Name | Type | Description |
|---|---|---|
| account | address | The account to remove from the whitelist |

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### rewardDistribution

```solidity
function rewardDistribution(address payable player, uint256 prize) external nonpayable
```

Pays the prize to the player



#### Parameters

| Name | Type | Description |
|---|---|---|
| player | address payable | The player receiving the prize |
| prize | uint256 | The prize to be paid |

### setBonusPercentMilestones

```solidity
function setBonusPercentMilestones(uint256[] newBonusPercents) external nonpayable
```

Sets new milestones for bonus percents of the referral program winnings



#### Parameters

| Name | Type | Description |
|---|---|---|
| newBonusPercents | uint256[] | New milestones to be set |

### setGame

```solidity
function setGame(address gameAddress) external nonpayable
```

Changes the address of the game using this pool controller



#### Parameters

| Name | Type | Description |
|---|---|---|
| gameAddress | address | The new address of the game |

### setJackpotLimit

```solidity
function setJackpotLimit(uint256 jackpotLimit_) external nonpayable
```

Changes the jackpot limit of the game



#### Parameters

| Name | Type | Description |
|---|---|---|
| jackpotLimit_ | uint256 | The new jackpot limit |

### setOracleGasFee

```solidity
function setOracleGasFee(uint256 oracleGasFee) external nonpayable
```

Changes oracle gas fee



#### Parameters

| Name | Type | Description |
|---|---|---|
| oracleGasFee | uint256 | A new oracle gas fee |

### setOracleOperator

```solidity
function setOracleOperator(address oracleOperator) external nonpayable
```

Changes the oracle operator



#### Parameters

| Name | Type | Description |
|---|---|---|
| oracleOperator | address | The address of the new oracle operator |

### setTotalJackpot

```solidity
function setTotalJackpot(uint256 jackpot) external nonpayable
```

Changes the jackpot amount of the game



#### Parameters

| Name | Type | Description |
|---|---|---|
| jackpot | uint256 | The new jackpot |

### setTotalWinningsMilestones

```solidity
function setTotalWinningsMilestones(uint256[] newTotalWinningMilestones) external nonpayable
```

Sets new milestones for referral program winnings



#### Parameters

| Name | Type | Description |
|---|---|---|
| newTotalWinningMilestones | uint256[] | New milestones to be set |

### supportsIPool

```solidity
function supportsIPool() external pure returns (bool)
```

Should be called by other contracts to check that the contract with the given        address supports the {IPool} interface




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | Always True |

### takeOracleFee

```solidity
function takeOracleFee() external nonpayable
```

Transfers oracle gas fee to the oracle operator and resets the fee




### totalJackpot

```solidity
function totalJackpot() external view returns (uint256)
```

The total amount of tokens stored to be paid as jackpot




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |

### updateRefereeStats

```solidity
function updateRefereeStats(address referer, uint256 winAmount, uint256 refAmount) external nonpayable
```

Updates referral program information of the referee of the provided member (referer)



#### Parameters

| Name | Type | Description |
|---|---|---|
| referer | address | The member taking part on the referral program |
| winAmount | uint256 | The amount the referer won in the game |
| refAmount | uint256 | The amount used to calculcate the payment for the refere |

### whitelist

```solidity
function whitelist(address) external view returns (bool)
```

The list of addresses that can deposit funds into the pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### withdrawNativeForInternal

```solidity
function withdrawNativeForInternal(uint256 internalTokensAmount) external nonpayable
```

Withdraws the amount of native tokens from the pool equal to the provided amount of internal tokens of the pool



#### Parameters

| Name | Type | Description |
|---|---|---|
| internalTokensAmount | uint256 | The amount of internal tokens used to calculate the amount of native tokens to be withdrawn |

### withdrawReferralEarnings

```solidity
function withdrawReferralEarnings(address payable player) external nonpayable
```

Transfers referral earnings of the referee to the provided player



#### Parameters

| Name | Type | Description |
|---|---|---|
| player | address payable | The receiver of withdrawn referral earnings |



## Events

### JackpotWin

```solidity
event JackpotWin(address player, uint256 amount)
```

Indicates that a player won a jackpot



#### Parameters

| Name | Type | Description |
|---|---|---|
| player  | address | undefined |
| amount  | uint256 | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### RegisteredReferer

```solidity
event RegisteredReferer(address referee, address referral)
```

Indicates that a new referer has been registered



#### Parameters

| Name | Type | Description |
|---|---|---|
| referee  | address | undefined |
| referral  | address | undefined |



