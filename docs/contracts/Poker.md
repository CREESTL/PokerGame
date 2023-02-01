# Poker



> Main Texas Hold`em game logic





## Methods

### _maxBet

```solidity
function _maxBet() external view returns (uint256)
```



*Maximum amount of tokens to bet*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _operator

```solidity
function _operator() external view returns (address)
```



*The address of the operator capable      of calling specific functions*


#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### calculateWinAmount

```solidity
function calculateWinAmount(uint256 gameId, enum Poker.GameResult result, bool winColor) external view returns (uint256, uint256, uint256)
```

Calculates the amount of tokens to be paid for:         - Poker win         - Color bet win         - Referral program membership



#### Parameters

| Name | Type | Description |
|---|---|---|
| gameId | uint256 | The ID of the game |
| result | enum Poker.GameResult | The result of the game with the provided ID |
| winColor | bool | True if a player won a color bet. False - if he lost |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The amount of tokens to be paid for:         - Poker win         - Color bet win         - Referral program membership |
| _1 | uint256 | undefined |
| _2 | uint256 | undefined |

### claimWinAmount

```solidity
function claimWinAmount(uint256 gameId) external nonpayable
```

Allows player to claim tokens he won in the game



#### Parameters

| Name | Type | Description |
|---|---|---|
| gameId | uint256 | The ID of the game request |

### endGame

```solidity
function endGame(uint256 gameId, uint256 winAmount, uint128 refAmount, bool isJackpot, uint64 cardsBits) external nonpayable
```

Called by the backend to set the game result



#### Parameters

| Name | Type | Description |
|---|---|---|
| gameId | uint256 | The ID of the game |
| winAmount | uint256 | The amount that will be given to the winner (for winning the game and guessing the color) |
| refAmount | uint128 | The amount that will be given to the member of referral program |
| isJackpot | bool | True if one of the players won a jackpot |
| cardsBits | uint64 | Binary number representing an array of cards |

### games

```solidity
function games(uint256) external view returns (uint128 colorBet, uint128 pokerBet, uint256 winAmount, uint128 refAmount, address payable player, uint8 chosenColor, bool isWinAmountClaimed, bool isJackpot)
```



*Mapping from request IDs to games*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| colorBet | uint128 | undefined |
| pokerBet | uint128 | undefined |
| winAmount | uint256 | undefined |
| refAmount | uint128 | undefined |
| player | address payable | undefined |
| chosenColor | uint8 | undefined |
| isWinAmountClaimed | bool | undefined |
| isJackpot | bool | undefined |

### getColorResult

```solidity
function getColorResult(uint256 gameId, uint8[] cardColors) external view returns (bool)
```

Checks if player guessed the dominant color correctly



#### Parameters

| Name | Type | Description |
|---|---|---|
| gameId | uint256 | The ID of the game |
| cardColors | uint8[] | Colors of cards |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | True if player guessed the dominant color. False - if he did not |

### getLastRequestId

```solidity
function getLastRequestId() external view returns (uint256)
```

Returns the ID of the last closed request




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The ID of the last closed request |

### getOracle

```solidity
function getOracle() external view returns (address)
```

Returns the address of the current oracle




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the current oracle |

### getPokerResult

```solidity
function getPokerResult(uint8[] _cards) external pure returns (enum Poker.GameResult)
```

Distributes cards between a player and a computer, compares their hands and determines the winner



#### Parameters

| Name | Type | Description |
|---|---|---|
| _cards | uint8[] | The array of cards to play TODO          Does it have the length of 7 or 8? |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum Poker.GameResult | Game result for the *person*: Win, Jackpot, Lose or Draw |

### getPoolController

```solidity
function getPoolController() external view returns (address)
```

Returns the address of the current pool controller




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the current pool controller |

### getRequest

```solidity
function getRequest(uint256 gameId) external view returns (uint64, uint64, enum GameController.Status)
```

Returns the request with the provided ID



#### Parameters

| Name | Type | Description |
|---|---|---|
| gameId | uint256 | The ID of the request to look for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint64 | Full info about the request |
| _1 | uint64 | undefined |
| _2 | enum GameController.Status | undefined |

### houseEdge

```solidity
function houseEdge() external view returns (uint256)
```

House edge is the mathematical advantage that a casino has on a player’s bet that ensures the casino makes a profit over the long run.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### jackpotFeeMultiplier

```solidity
function jackpotFeeMultiplier() external view returns (uint256)
```



*Bet amount gets multiplied by {jackpotFeeMultiplier}      if a player wins a jackpot*


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

### renounceOwnership

```solidity
function renounceOwnership() external nonpayable
```



*Leaves the contract without owner. It will not be possible to call `onlyOwner` functions anymore. Can only be called by the current owner. NOTE: Renouncing ownership will leave the contract without an owner, thereby removing any functionality that is only available to the owner.*


### sendFundsToPool

```solidity
function sendFundsToPool() external nonpayable
```

Sends tokens from the game to the pool controller




### setHouseEdge

```solidity
function setHouseEdge(uint256 _houseEdge) external nonpayable
```

Changes the house edge of the game



#### Parameters

| Name | Type | Description |
|---|---|---|
| _houseEdge | uint256 | A new house edge |

### setJackpotFeeMultiplier

```solidity
function setJackpotFeeMultiplier(uint256 _jackpotFeeMultiplier) external nonpayable
```

Changes the current jackpot multiplier



#### Parameters

| Name | Type | Description |
|---|---|---|
| _jackpotFeeMultiplier | uint256 | A new jackpot multiplier to use |

### setMaxBet

```solidity
function setMaxBet(uint256 maxBet) external nonpayable
```

Changes the maxximum amount of tokens to bet



#### Parameters

| Name | Type | Description |
|---|---|---|
| maxBet | uint256 | The maximum amount of tokens to bets |

### setOperator

```solidity
function setOperator(address operatorAddress) external nonpayable
```

Changes the address of the game operator



#### Parameters

| Name | Type | Description |
|---|---|---|
| operatorAddress | address | The address of the new operator |

### setOracle

```solidity
function setOracle(address oracleAddress) external nonpayable
```

Sets a new oracle



#### Parameters

| Name | Type | Description |
|---|---|---|
| oracleAddress | address | the address of the oracle to be used |

### setPoolController

```solidity
function setPoolController(address poolControllerAddress) external nonpayable
```

Changes the address of the pool controller



#### Parameters

| Name | Type | Description |
|---|---|---|
| poolControllerAddress | address | A new address of the pool controller |

### startGame

```solidity
function startGame(uint256 colorBet, uint256 chosenColor) external payable
```

User pays tokens, makes bets and starts a game



#### Parameters

| Name | Type | Description |
|---|---|---|
| colorBet | uint256 | The amount of tokens at stake for a chosen color |
| chosenColor | uint256 | The color a player chose |

### supportsIGame

```solidity
function supportsIGame() external pure returns (bool)
```

Indicates that the contract supports {IGame} interface




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | True in any case |

### transferOwnership

```solidity
function transferOwnership(address newOwner) external nonpayable
```



*Transfers ownership of the contract to a new account (`newOwner`). Can only be called by the current owner.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| newOwner | address | undefined |



## Events

### GameFinished

```solidity
event GameFinished(uint256 winAmount, bool winColor, enum Poker.GameResult result, uint256 gameId, uint256 cards, address player)
```

TODO not used - emit it!

*Indicates that the game has finished      Shows the result of a single game*

#### Parameters

| Name | Type | Description |
|---|---|---|
| winAmount  | uint256 | undefined |
| winColor  | bool | undefined |
| result  | enum Poker.GameResult | undefined |
| gameId  | uint256 | undefined |
| cards  | uint256 | undefined |
| player  | address | undefined |

### GameStart

```solidity
event GameStart(uint256 gameId)
```



*Indicates that the game has started*

#### Parameters

| Name | Type | Description |
|---|---|---|
| gameId  | uint256 | undefined |

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### WinAmountClaimed

```solidity
event WinAmountClaimed(uint256 gameId)
```



*Indicates that someone claimed the amount he won*

#### Parameters

| Name | Type | Description |
|---|---|---|
| gameId  | uint256 | undefined |



