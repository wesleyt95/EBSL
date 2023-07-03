require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();
const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
module.exports = {
  solidity: '0.8.0',
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY], // TODO: fill the private key
    },
  },
};
