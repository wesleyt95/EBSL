<script setup>
// import { Todo, Meta } from 'components/models';
// import ExampleComponent from 'components/ExampleComponent.vue';
import { ref, watchEffect } from 'vue';
import { TEAMS } from './teams/nba-teams.js';
import { ethers } from 'ethers';

const provider = new ethers.BrowserProvider(window.ethereum);
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');
const transactionHistory = ref([]);
const transactionHistoryInactive = ref([]);
const nbaNews = ref([]);

watchEffect(async () => {
  const betContract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    contract.abi,
    await provider.getSigner()
  );
  const data = await betContract.returnReceipts();
  const receipt = data.map((tx) =>
    JSON.stringify(tx, (_, v) => (typeof v === 'bigint' ? v.toString() : v))
  );

  transactionHistory.value = receipt.filter((tx) => JSON.parse(tx)[6] === true);
  transactionHistoryInactive.value = receipt.filter(
    (tx) => JSON.parse(tx)[6] === false
  );
  await fetch(
    'https://api.sportsdata.io/v3/nba/scores/json/News?key=186578d61751474db1ac789b9613a9b1'
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
  <q-page class="fit">
    <q-card class="newsCard">
      <q-scroll-area style="height: 48em">
        <q-card-section>
          <div class="text-h6 mainSign">Recent News</div>
          <div v-for="(news, index) in nbaNews" :key="index">
            <a style="text-decoration: none" :href="news.Url">
              <div class="text-center receiptItem">
                <div class="text-yellow-14 text-weight-bold">
                  {{ news.Title }}
                </div>
                <div class="text-grey-1">
                  [{{ ' ' + news.OriginalSource + ' ' }}]
                </div>
                <div class="text-red">
                  <div>{{ new Date(news.Updated).toLocaleDateString() }}</div>
                </div>
              </div></a
            >
          </div></q-card-section
        >
      </q-scroll-area>
    </q-card>
    <q-card class="receiptCard">
      <q-btn @click="logResult">click</q-btn>
      <q-scroll-area style="height: 48em">
        <template v-if="transactionHistory.length > 0"
          ><q-card-section>
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
                      class="text-grey-1"
                    >
                      {{
                        TEAMS.find(
                          (row) => row.TeamID === Number(JSON.parse(tx)[2])
                        ).Name
                      }}
                    </div>
                    <div>
                      {{
                        ethers.formatEther(JSON.parse(tx)[1]).substring(0, 6) +
                        ' ETH'
                      }}
                    </div>
                  </div>
                </div>
              </RouterLink>
            </div></q-card-section
          ></template
        >
        <template v-if="transactionHistoryInactive.length > 0"
          ><q-card-section>
            <div class="text-h6 mainSign">Past Transactions</div>
            <div v-for="(tx, index) in transactionHistoryInactive" :key="index">
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
                      class="text-grey-1"
                    >
                      {{
                        TEAMS.find(
                          (row) => row.TeamID === Number(JSON.parse(tx)[2])
                        ).Name
                      }}
                    </div>
                    <div>
                      {{
                        ethers.formatEther(JSON.parse(tx)[1]).substring(0, 6) +
                        ' ETH'
                      }}
                    </div>
                  </div>
                </div>
              </RouterLink>
            </div>
          </q-card-section></template
        >
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
  margin: 1em 0.5em 0 0;
  border: 5px $grey-4 solid;
  border-radius: 5px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
  height: 100%;
  width: 25%;
  min-width: 25em;
  float: right;
}
.newsCard {
  margin: 1em 0 0 0.5em;
  border: 5px $grey-4 solid;
  border-radius: 5px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
  height: 100%;
  width: 25%;
  min-width: 25em;
  float: left;
}
.receiptItem {
  border: 4px red solid;
  border-radius: 5px;
  color: $yellow-14;
  background: $blue-grey-10;
  margin: 1em 0;
  padding: 0.5em;
}
</style>
