<script setup>
import { useWalletStore } from 'stores/web3wallet';
import { ethers } from 'ethers';
import { watchEffect, ref } from 'vue';
import { TEAMS } from './teams/nba-teams';
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');
const store = useWalletStore();
const provider = new ethers.BrowserProvider(window.ethereum);
const admin = process.env.ADMIN_ADDRESS.toLowerCase();
const transactionHistoryEBSL = ref([]);
const userBlock = ref('');
const depositAmount = ref(0);

const blockUser = async (user) => {
  const betContract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    contract.abi,
    await provider.getSigner()
  );
  try {
    const tx = await betContract.blockUser(user);
    await tx.wait();
    window.location.reload(true);
    console.log(tx);
  } catch (err) {
    console.log(err);
  }
};
const returnBetType = (betType) => {
  if (betType === 'moneyLineBet') {
    return 'Money Line';
  } else if (betType === 'pointSpreadBet') {
    return 'Point Spread';
  } else if (betType === 'pointTotalBet') {
    return 'Point Total';
  }
};
const etherscanBetType = (methodID) => {
  return ethers.Interface.from(contract.abi).getFunctionName(methodID);
};

const etherscanTeam = (methodID, input, teamID) => {
  const betType = etherscanBetType(methodID);
  const data = ethers.Interface.from(contract.abi).decodeFunctionData(
    betType,
    input
  )[teamID];

  if (Number(data) < 99) {
    return TEAMS.find((row) => row.TeamID === Number(data)).Name;
  } else if (Number(data) === 99) {
    return 'Under';
  } else if (Number(data) === 100) {
    return 'Over';
  }
};
const etherscanTeamBet = (methodID, input, teamID) => {
  const betType = etherscanBetType(methodID);
  const data = ethers.Interface.from(contract.abi).decodeFunctionData(
    betType,
    input
  )[teamID];
  if (betType === 'pointSpreadBet') {
    const spreadData = ethers.Interface.from(contract.abi).decodeFunctionData(
      betType,
      input
    )[4];
    return (
      TEAMS.find((row) => row.TeamID === Number(data)).Name +
      ' ' +
      (spreadData > 0 ? '+' : '') +
      Number(spreadData) / 10
    );
  } else if (betType === 'pointTotalBet') {
    const totalData = ethers.Interface.from(contract.abi).decodeFunctionData(
      betType,
      input
    )[4];
    if (Number(data) === 99) {
      return 'Under' + ' ' + Number(totalData) / 10;
    } else if (Number(data) === 100) {
      return 'Over' + ' ' + Number(totalData) / 10;
    }
  } else {
    return TEAMS.find((row) => row.TeamID === Number(data)).Name;
  }
};

watchEffect(async () => {
  await fetch(
    `https://api-goerli.etherscan.io/api?module=account&action=txlist&address=${process.env.CONTRACT_ADDRESS}&startblock=0&endblock=99999999&page=1&offset=10&sort=desc&apikey=${process.env.ETHERSCAN_API_KEY}`
  )
    .then((response) => response.json())
    .then(
      (data) =>
        (transactionHistoryEBSL.value = data.result.filter(
          (tx) =>
            tx.methodId === '0xf12b2a8b' ||
            tx.methodId === '0xb1a374dd' ||
            tx.methodId === '0x753dc3b8'
        ))
    );
});
</script>
<template>
  <div>
    <div v-if="store.user === admin">
      <div class="text-center text-h4 q-my-sm">Admin Page</div>

      <q-card class="etherscanCard">
        <q-scroll-area style="height: 40em">
          <div class="text-h6 mainSign">EBSL Transactions</div>
          <div v-for="(receipts, index) in transactionHistoryEBSL" :key="index">
            <a
              style="text-decoration: none"
              :href="`https://goerli.etherscan.io/tx/${receipts.hash}`"
              ><div class="text-center receiptItem">
                <div class="text-red text-weight-bold">
                  {{ receipts.from }}
                  <span class="text-grey-6">
                    {{
                      ` (${ethers
                        .formatEther(receipts.value)
                        .substring(0, 6)}` + ' ETH)'
                    }}
                  </span>
                </div>
                <div class="row justify-between">
                  <div>
                    {{ returnBetType(etherscanBetType(receipts.methodId)) }} ({{
                      etherscanTeamBet(receipts.methodId, receipts.input, 1)
                    }})
                  </div>
                  <div class="text-bold">
                    {{ etherscanTeam(receipts.methodId, receipts.input, 3) }}
                    <span class="text-yellow-14">@</span>
                    {{ etherscanTeam(receipts.methodId, receipts.input, 2) }}
                  </div>
                  <div>
                    {{
                      new Date(receipts.timeStamp * 1000).toLocaleDateString()
                    }}
                    -
                    {{
                      new Date(receipts.timeStamp * 1000).toLocaleTimeString()
                    }}
                  </div>
                </div>
              </div>
            </a>
          </div>
        </q-scroll-area>
      </q-card>
      <div class="text-center q-ma-md">
        <q-input
          v-model="userBlock"
          label="Block User"
          filled
          dense
          class="q-mx-auto"
          style="width: 20em"
        />
        <q-btn class="q-my-md" @click="blockUser(userBlock)">Block</q-btn>
      </div>
    </div>
    <div class="text-h2 text-center q-ma-md" v-else>Unauthorized</div>
  </div>
</template>
<style lang="scss" scoped>
.etherscanCard {
  margin: 0.5em auto 0 auto;
  border: 5px $grey-4 solid;
  border-radius: 10px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
  height: 100%;
  width: 99%;
}
.mainSign {
  border-radius: 5px;
  font-weight: 1000;
  padding: auto;
  margin: auto;
  text-align: center;
}
.receiptItem {
  border: 5px $grey-4 solid;
  border-radius: 10px;
  color: $blue-grey-10;
  background: $grey-1;
  margin: 1em 0;
  padding: 0.5em;
}
.receiptItem:hover {
  background: $grey-2;
  cursor: pointer;
}
</style>
