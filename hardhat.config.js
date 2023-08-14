require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const ZKEVM_RPC_URL_TEST = process.env.ZKEVM_RPC_URL_TEST;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
module.exports = {
  solidity: {
    settings: {
      optimizer: {
        enabled: true,
        runs: 0,
      },
      viaIR: true,
    },
    compilers: [
      {
        version: '0.8.21',
      },
    ],
  },
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY], // TODO: fill the private key
    },
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 5,
      allowUnlimitedContractSize: true,
    },
    zkEvmTestnet: {
      url: ZKEVM_RPC_URL_TEST,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 1442,
    },
  },
};
