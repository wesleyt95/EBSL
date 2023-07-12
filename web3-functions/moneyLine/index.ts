import {
  Web3Function,
  Web3FunctionContext,
} from '@gelatonetwork/web3-functions-sdk';
import { Contract } from 'ethers';
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');
import ky from 'ky'; // we recommend using ky as axios doesn't support fetch by default

const ORACLE_ABI = contract.abi;

Web3Function.onRun(async (context: Web3FunctionContext) => {
  const { userArgs, multiChainProvider } = context;

  const provider = multiChainProvider.default();
  // Retrieve Last oracle update time
  const oracleAddress =
    (userArgs.oracle as string) ?? '0x71B9B0F6C999CBbB0FeF9c92B80D54e4973214da';
  let lastUpdated;
  let oracle;
  try {
    oracle = new Contract(oracleAddress, ORACLE_ABI, provider);
    lastUpdated = parseInt(await oracle.lastUpdated());
    console.log(`Last oracle update: ${lastUpdated}`);
  } catch (err) {
    return { canExec: false, message: 'Rpc call failed' };
  }

  // Check if it's ready for a new update
  const nextUpdateTime = lastUpdated + 3600; // 1h
  const timestamp = (await provider.getBlock('latest')).timestamp;
  console.log(`Next oracle update: ${nextUpdateTime}`);
  if (timestamp < nextUpdateTime) {
    return { canExec: false, message: 'Time not elapsed' };
  }

  // Get current price on coingecko
  const currency = (userArgs.currency as string) ?? 'ethereum';
  let price = 0;
  try {
    const coingeckoApi = `https://api.coingecko.com/api/v3/simple/price?ids=${currency}&vs_currencies=usd`;

    const priceData: { [key: string]: { usd: number } } = await ky
      .get(coingeckoApi, { timeout: 5_000, retry: 0 })
      .json();
    price = Math.floor(priceData[currency].usd);
  } catch (err) {
    return { canExec: false, message: 'Coingecko call failed' };
  }
  console.log(`Updating price: ${price}`);

  // Return execution call data
  return {
    canExec: true,
    callData: [
      {
        to: oracleAddress,
        data: oracle.interface.encodeFunctionData('updatePrice', [price]),
      },
    ],
  };
});
