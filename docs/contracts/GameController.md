# GameController



> Controls game state





## Methods

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


### setOracle

```solidity
function setOracle(address oracleAddress) external nonpayable
```

Sets a new oracle



#### Parameters

| Name | Type | Description |
|---|---|---|
| oracleAddress | address | the address of the oracle to be used |

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

### OwnershipTransferred

```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| previousOwner `indexed` | address | undefined |
| newOwner `indexed` | address | undefined |



