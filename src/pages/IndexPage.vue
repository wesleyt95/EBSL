<script setup>
import { useWalletStore } from 'stores/web3wallet';
import { ref, watchEffect } from 'vue';
import { TEAMS } from './teams/nba-teams.js';
import { ethers } from 'ethers';
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');
const store = useWalletStore();
const chainIdRef = ref(store.chainID);
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
const returnBetType = (betType) => {
  if (betType === 'moneyLineBet') {
    return 'Money Line';
  } else if (betType === 'pointSpreadBet') {
    return 'Point Spread';
  } else if (betType === 'pointTotalBet') {
    return 'Point Total';
  }
};

window.ethereum.on('accountsChanged', async () => {
  if (chainIdRef.value === process.env.CHAIN_ID) {
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
});

watchEffect(async () => {
  if (chainIdRef.value === process.env.CHAIN_ID) {
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
    `https://api-goerli.etherscan.io/api?module=account&action=txlist&address=${process.env.CONTRACT_ADDRESS}&startblock=0&endblock=99999999&page=1&offset=100&sort=desc&apikey=${process.env.ETHERSCAN_API_KEY}`
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
  await fetch(
    `https://api.sportsdata.io/v3/nba/scores/json/News?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) =>
          (nbaNews.value = data.map((row) => ({ ...row, modalValue: false })))
      )
  );
});
</script>

<template>
  <q-page class="fit bg-grey-1">
    <div class="row q-my-auto">
      <q-card class="newsCard shadow-6">
        <q-scroll-area style="height: 22.5em">
          <q-card-section>
            <div class="text-h6 mainSign">Recent News</div>
            <div v-for="(news, index) in nbaNews" :key="index">
              <div
                class="text-center receiptItem shadow-3"
                @click="news.modalValue = true"
              >
                <div class="text-blue-grey-10 text-weight-bold">
                  {{ news.Title }}
                </div>
                <div v-if="news.OriginalSource !== null" class="text-grey-6">
                  [{{ ' ' + news.OriginalSource + ' ' }}]
                </div>
                <div class="text-red">
                  <div>{{ new Date(news.Updated).toLocaleDateString() }}</div>
                </div>
                <q-dialog v-model="news.modalValue">
                  <q-card>
                    <q-card-section>
                      <div class="text-h6">{{ news.Title }}</div>
                    </q-card-section>

                    <q-card-section class="q-pt-none">
                      {{ news.Content }}
                    </q-card-section>
                    <q-card-section
                      class="text-center text-bold"
                      v-if="news.OriginalSource !== null"
                    >
                      Source: {{ news.OriginalSource }}
                      <div class="text-red q-mt-sm">
                        - {{ new Date(news.Updated).toLocaleDateString() }}
                      </div>
                    </q-card-section>
                    <q-card-actions align="right">
                      <q-btn
                        label="Close"
                        color="blue-grey-10"
                        size="sm"
                        v-close-popup
                      />
                    </q-card-actions>
                  </q-card>
                </q-dialog>
              </div>
            </div>
          </q-card-section>
        </q-scroll-area>
      </q-card>
      <q-card class="receiptCard shadow-6">
        <q-scroll-area style="height: 22.5em">
          <template v-if="transactionHistory.length > 0">
            <q-card-section>
              <div class="text-h6 mainSign">Active Transactions</div>
              <div v-for="(tx, index) in transactionHistory" :key="index">
                <RouterLink
                  style="text-decoration: none"
                  :to="`/games/${JSON.parse(tx)[3]}`"
                >
                  <div class="receiptItem shadow-3">
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
              <div class="receiptItem text-center shadow-3">None</div>
            </q-card-section>
          </template>
          <template v-if="transactionHistoryInactive.length > 0">
            <q-card-section>
              <div class="text-h6 mainSign">Transaction History</div>
              <div
                v-for="(tx, index) in transactionHistoryInactive"
                :key="index"
              >
                <RouterLink
                  style="text-decoration: none"
                  :to="`/games/${JSON.parse(tx)[3]}`"
                >
                  <div class="receiptItem shadow-3">
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
              <div class="text-h6 mainSign">Transaction History</div>
              <div class="receiptItem text-center shadow-3">None</div>
            </q-card-section>
          </template>
        </q-scroll-area>
      </q-card>
    </div>
    <q-card class="etherscanCard shadow-6">
      <q-scroll-area style="height: 22em">
        <template v-if="transactionHistoryEBSL.length > 0">
          <div class="text-h6 mainSign row items-center justify-center">
            <q-icon name="language" class="text-light-blue-2 q-mr-sm" />
            <div>EBSL Transactions</div>
          </div>
          <div v-for="(receipts, index) in transactionHistoryEBSL" :key="index">
            <a
              style="text-decoration: none"
              :href="`https://goerli.etherscan.io/tx/${receipts.hash}`"
              ><div class="text-center receiptItemEtherScan shadow-3">
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
        </template>
        <template v-if="transactionHistoryEBSL.length === 0">
          <q-card-section>
            <div class="text-h6 mainSign row items-center justify-center">
              <q-icon name="language" class="text-light-blue-2 q-mr-sm" />
              <div>EBSL Transactions</div>
            </div>
            <div class="receiptItemEtherScan text-center shadow-3">None</div>
          </q-card-section>
        </template>
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
  margin: 0.5em auto 0 auto;
  border: 5px $grey-4 solid;
  border-radius: 10px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
  height: 100%;
  width: 99%;
}
.receiptItem {
  border: 5px $grey-4 solid;
  border-radius: 10px;
  color: $blue-grey-10;
  background: $grey-1;
  margin: 1em 0;
  padding: 0.5em;
}
.receiptItemEtherScan {
  border: 7px $grey-4 solid;
  border-radius: 10px;
  color: $blue-grey-10;
  background: $grey-1;
  margin: 1em 2em;
  padding: 0.5em;
}
.receiptItem:hover {
  background: $grey-2;
  cursor: pointer;
}
</style>
