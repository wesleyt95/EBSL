require('dotenv').config();
const hre = require('hardhat');
const { ethers } = hre;
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log('Deploying contracts with the account:', deployer.address);

  const contract = await ethers.deployContract('Bet', [
    process.env.MONEYLINE_ADDRESS,
    process.env.POINTSPREAD_ADDRESS,
    process.env.POINTTOTAL_ADDRESS,
  ]);
  contract.waitForDeployment();
  console.log('Contract address:', contract.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
