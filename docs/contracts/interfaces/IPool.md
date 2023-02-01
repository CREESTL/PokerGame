# IPool









## Methods

### addBetToPool

```solidity
function addBetToPool(uint256 betAmount) external payable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| betAmount | uint256 | undefined |

### addToJackpot

```solidity
function addToJackpot(uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### freezeJackpot

```solidity
function freezeJackpot(uint256 amount) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

### getAvailableJackpot

```solidity
function getAvailableJackpot() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getNativeTokensTotal

```solidity
function getNativeTokensTotal() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getOracleGasFee

```solidity
function getOracleGasFee() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### jackpotDistribution

```solidity
function jackpotDistribution(address payable player, uint256 prize) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| player | address payable | undefined |
| prize | uint256 | undefined |

### jackpotLimit

```solidity
function jackpotLimit() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### receiveFundsFromGame

```solidity
function receiveFundsFromGame() external payable
```






### rewardDistribution

```solidity
function rewardDistribution(address payable player, uint256 prize) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| player | address payable | undefined |
| prize | uint256 | undefined |

### supportsIPool

```solidity
function supportsIPool() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### totalJackpot

```solidity
function totalJackpot() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### updateRefereeStats

```solidity
function updateRefereeStats(address player, uint256 amount, uint256 betEdge) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| player | address | undefined |
| amount | uint256 | undefined |
| betEdge | uint256 | undefined |




