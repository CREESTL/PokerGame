import 'hardhat-typechain';
import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-solhint";
import '@nomiclabs/hardhat-ethers';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-etherscan';
import "solidity-coverage";

export default {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: false,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  solidity: {
    version: '0.5.12',
    settings: {
      optimizer: {
        enabled: true,
        runs: 999999,
      },
    },
  },
}