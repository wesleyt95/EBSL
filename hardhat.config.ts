import '@nomicfoundation/hardhat-toolbox';
import 'dotenv';
import '@gelatonetwork/web3-functions-sdk/hardhat-plugin';
import { HardhatUserConfig } from 'hardhat/config';
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const config: HardhatUserConfig = {
  solidity: {
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
    compilers: [
      {
        version: '0.8.12',
      },
      {
        version: '0.8.14',
      },
    ],
  },
  w3f: {
    rootDir: './web3-functions',
    debug: false,
    networks: ['goerli'], //(multiChainProvider) injects provider for these networks
  },
  defaultNetwork: 'goerli',
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 5,
      allowUnlimitedContractSize: true,
    },
  },
  typechain: {
    outDir: 'typechain',
    target: 'ethers-v5',
  },
};
export default config;
