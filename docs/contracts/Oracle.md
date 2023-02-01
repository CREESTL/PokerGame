# Oracle



> Provides random numbers to contracts.        Converts array of cards into binary format





## Methods

### cardsToBits

```solidity
function cardsToBits(uint8[] cards) external pure returns (uint256)
```

Converts an array of numbers (cards) into a single array of bits (binary number)



#### Parameters

| Name | Type | Description |
|---|---|---|
| cards | uint8[] | The array of cards to convert to an array of bits |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | Binary representation of an array of cards |

### checkPending

```solidity
function checkPending(uint256 gameId) external view returns (bool)
```

Checks if a request is pending



#### Parameters

| Name | Type | Description |
|---|---|---|
| gameId | uint256 | The ID of the request to look for |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | True if request is pending. False if it is not |

### generateRandomGameId

```solidity
function generateRandomGameId() external nonpayable returns (uint256)
```

Creates a request for random number generation         which is then handled by the backend




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | The ID of the created request |

### getGame

```solidity
function getGame() external view returns (address)
```

Returns the address of the current game that is using the oracle




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of the game contract |

### getOperator

```solidity
function getOperator() external view returns (address)
```

Returns the address of current operator




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | The address of current operator |

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


### setGame

```solidity
function setGame(address gameAddress) external nonpayable
```

Sets the address of the poker game for this oracle         to provide random numbers for



#### Parameters

| Name | Type | Description |
|---|---|---|
| gameAddress | address | The address of the game contract |

### setOperator

```solidity
function setOperator(address operatorAddress) external nonpayable
```

Sets a new operator



#### Parameters

| Name | Type | Description |
|---|---|---|
| operatorAddress | address | The address of a new operator |

### supportsIOracle

```solidity
function supportsIOracle() external pure returns (bool)
```

Indicates that the contract supports {IOracle} interface




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

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |

### RandomNumberEvent

```solidity
event RandomNumberEvent(uint256 cardsBits, address indexed callerAddress, uint256 indexed gameId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| cardsBits  | uint256 | undefined |
| callerAddress `indexed` | address | undefined |
| gameId `indexed` | uint256 | undefined |

### RandomNumberRequested

```solidity
event RandomNumberRequested(address indexed callerAddress, uint256 indexed gameId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| callerAddress `indexed` | address | undefined |
| gameId `indexed` | uint256 | undefined |



