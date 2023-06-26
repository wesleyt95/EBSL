// import('hardhat/config').HardhatUserConfig;
require('dotenv').config();
require('@nomiclabs/hardhat-waffle');
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL;
const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY;
module.exports = {
  solidity: '0.8.0',
  networks: {
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: [GOERLI_PRIVATE_KEY], // TODO: fill the private key
    },
  },
};
