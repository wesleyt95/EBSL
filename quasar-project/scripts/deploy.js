const { waffle } = require('hardhat');
const { deployContract } = waffle;
require('dotenv').config();
async function main() {
  const contract = await deployContract(process.env.GOERLI_PRIVATE_KEY, 'Bet');

  await contract.waitForDeployment();

  console.log(`Contract deployed to ${contract.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
