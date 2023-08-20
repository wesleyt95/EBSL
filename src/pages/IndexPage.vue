<script setup>
// import { Todo, Meta } from 'components/models';
// import ExampleComponent from 'components/ExampleComponent.vue';
import { ref, watchEffect } from 'vue';
import { TEAMS } from './teams/nba-teams.js';
import { ethers } from 'ethers';
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');

const provider = new ethers.BrowserProvider(window.ethereum);
const transactionHistory = ref([]);
const transactionHistoryInactive = ref([]);
const transactionHistoryEBSL = ref([]);
const nbaNews = ref([]);

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
  } else {
    if (Number(data) < 99 && betType === 'moneyLineBet') {
      return TEAMS.find((row) => row.TeamID === Number(data)).Name;
    } else if (Number(data) === 99 && betType === 'pointTotalBet') {
      return 'Under';
    } else if (Number(data) === 100 && betType === 'pointTotalBet') {
      return 'Over';
    }
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

watchEffect(async () => {
  if (window.ethereum.chainId === '0x5') {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const data = await betContract.returnReceipts();
    const receipt = data.map((tx) =>
      JSON.stringify(tx, (_, v) => (typeof v === 'bigint' ? v.toString() : v))
    );

    transactionHistory.value = receipt.filter(
      (tx) => JSON.parse(tx)[6] === true
    );
    transactionHistoryInactive.value = receipt.filter(
      (tx) => JSON.parse(tx)[6] === false
    );
  }
  await fetch(
    `https://api-goerli.etherscan.io/api?module=account&action=txlist&address=${process.env.CONTRACT_ADDRESS}&startblock=0&endblock=99999999&page=1&offset=10&sort=desc&apikey=${process.env.ETHERSCAN_API_KEY}`
  )
    .then((response) => response.json())
    .then(
      (data) =>
        (transactionHistoryEBSL.value = data.result.filter(
          (tx) => tx.value !== '0' && tx.functionName !== 'deposit()'
        ))
    );
  await fetch(
    `https://api.sportsdata.io/v3/nba/scores/json/News?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData.json().then((data) => (nbaNews.value = data))
  );
});
const logResult = async () => {
  const betContract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    contract.abi,
    await provider.getSigner()
  );
  try {
    const tx = await betContract.deposit({
      value: ethers.parseEther('0.06'),
    });
    await tx.wait();
    window.location.reload();
    console.log(tx);
  } catch (err) {
    console.log(err);
  }
};
</script>

<template>
  <q-page class="fit bg-grey-1">
    <div class="row q-my-auto">
      <q-card class="newsCard">
        <q-scroll-area style="height: 22.5em">
          <q-card-section>
            <div class="text-h6 mainSign">Recent News</div>
            <div v-for="(news, index) in nbaNews" :key="index">
              <a style="text-decoration: none" :href="news.Url">
                <div class="text-center receiptItem">
                  <div class="text-blue-grey-10 text-weight-bold">
                    {{ news.Title }}
                  </div>
                  <div class="text-grey-6">
                    [{{ ' ' + news.OriginalSource + ' ' }}]
                  </div>
                  <div class="text-red">
                    <div>{{ new Date(news.Updated).toLocaleDateString() }}</div>
                  </div>
                </div>
              </a>
            </div></q-card-section
          >
        </q-scroll-area>
      </q-card>
      <q-card class="receiptCard">
        <q-scroll-area style="height: 22.5em">
          <q-btn @click="logResult">click</q-btn>
          <template v-if="transactionHistory.length > 0">
            <q-card-section>
              <div class="text-h6 mainSign">Active Transactions</div>
              <div v-for="(tx, index) in transactionHistory" :key="index">
                <RouterLink
                  style="text-decoration: none"
                  :to="`/games/${JSON.parse(tx)[3]}`"
                >
                  <div class="receiptItem">
                    <div class="text-center text-red text-weight-bold">
                      {{
                        new Date(
                          Number(JSON.parse(tx)[5]) * 1000
                        ).toLocaleDateString()
                      }}
                    </div>
                    <div class="row justify-between">
                      <div>{{ JSON.parse(tx)[4] }}</div>
                      <div
                        style="float: left; margin-left: -1em"
                        class="text-grey-6"
                      >
                        {{
                          TEAMS.find(
                            (row) => row.TeamID === Number(JSON.parse(tx)[2])
                          )
                            ? TEAMS.find(
                                (row) =>
                                  row.TeamID === Number(JSON.parse(tx)[2])
                              ).Name
                            : Number(JSON.parse(tx)[2]) < 99
                            ? 'Over'
                            : 'Under'
                        }}
                      </div>
                      <div>
                        {{
                          ethers
                            .formatEther(JSON.parse(tx)[1])
                            .substring(0, 6) + ' ETH'
                        }}
                      </div>
                    </div>
                  </div>
                </RouterLink>
              </div>
            </q-card-section>
          </template>
          <template v-if="transactionHistory.length === 0">
            <q-card-section>
              <div class="text-h6 mainSign">Active Transactions</div>
              <div class="receiptItem text-center">No Active Transactions</div>
            </q-card-section>
          </template>
          <template v-if="transactionHistoryInactive.length > 0">
            <q-card-section>
              <div class="text-h6 mainSign">Past Transactions</div>
              <div
                v-for="(tx, index) in transactionHistoryInactive"
                :key="index"
              >
                <RouterLink
                  style="text-decoration: none"
                  :to="`/games/${JSON.parse(tx)[3]}`"
                >
                  <div class="receiptItem">
                    <div class="text-center text-red text-weight-bold">
                      {{
                        new Date(
                          Number(JSON.parse(tx)[5]) * 1000
                        ).toLocaleDateString()
                      }}
                    </div>
                    <div class="row justify-between">
                      <div>{{ JSON.parse(tx)[4] }}</div>
                      <div
                        style="float: left; margin-left: -1em"
                        class="text-grey-6"
                      >
                        {{
                          TEAMS.find(
                            (row) => row.TeamID === Number(JSON.parse(tx)[2])
                          )
                            ? TEAMS.find(
                                (row) =>
                                  row.TeamID === Number(JSON.parse(tx)[2])
                              ).Name
                            : Number(JSON.parse(tx)[2]) < 99
                            ? 'Over'
                            : 'Under'
                        }}
                      </div>
                      <div>
                        {{
                          ethers
                            .formatEther(JSON.parse(tx)[1])
                            .substring(0, 6) + ' ETH'
                        }}
                      </div>
                    </div>
                  </div>
                </RouterLink>
              </div>
            </q-card-section>
          </template>
          <template v-if="transactionHistoryInactive.length === 0">
            <q-card-section>
              <div class="text-h6 mainSign">Inactive Transactions</div>
              <div class="receiptItem text-center">
                No Inactive Transactions
              </div>
            </q-card-section>
          </template>
        </q-scroll-area>
      </q-card>
    </div>
    <q-card class="etherscanCard">
      <q-scroll-area style="height: 20em">
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
                    ` (${ethers.formatEther(receipts.value).substring(0, 6)}` +
                    ' ETH)'
                  }}
                </span>
              </div>
              <div class="row justify-between">
                <div>
                  {{ returnBetType(etherscanBetType(receipts.methodId)) }} ({{
                    etherscanTeamBet(receipts.methodId, receipts.input, 1)
                  }})
                </div>
                <div>
                  {{ etherscanTeam(receipts.methodId, receipts.input, 3) }}
                  @
                  {{ etherscanTeam(receipts.methodId, receipts.input, 2) }}
                </div>
                <div>
                  {{ new Date(receipts.timeStamp * 1000).toLocaleDateString() }}
                  -
                  {{ new Date(receipts.timeStamp * 1000).toLocaleTimeString() }}
                </div>
              </div>
            </div>
          </a>
        </div>
      </q-scroll-area>
    </q-card>
  </q-page>
</template>
<style lang="scss" scoped>
.mainSign {
  border-radius: 5px;
  font-weight: 1000;
  padding: auto;
  margin: auto;
  text-align: center;
}
.receiptCard {
  margin: 1em auto 0.5em auto;
  border: 5px $grey-4 solid;
  border-radius: 10px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
  height: 100%;
  width: 49%;
}
.newsCard {
  margin: 1em auto 0.5em auto;
  border: 5px $grey-4 solid;
  border-radius: 10px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
  height: 100%;
  width: 49%;
}
.etherscanCard {
  margin: 0.5em 1em 0 1em;
  border: 5px $grey-4 solid;
  border-radius: 10px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
  height: 100%;
  width: 98%;
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
}
</style>
