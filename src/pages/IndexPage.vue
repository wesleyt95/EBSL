<script setup>
// import { Todo, Meta } from 'components/models';
// import ExampleComponent from 'components/ExampleComponent.vue';
import { ref, watchEffect } from 'vue';
import { TEAMS } from './teams/nba-teams.js';
import { ethers } from 'ethers';

const provider = new ethers.BrowserProvider(window.ethereum);
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');

const transactionHistory = ref();

watchEffect(async () => {
  const betContract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    contract.abi,
    await provider.getSigner()
  );
  const data = await betContract.returnReceipts();
  transactionHistory.value = data.map((tx) =>
    JSON.stringify(tx, (_, v) => (typeof v === 'bigint' ? v.toString() : v))
  );
});

const getETH = async () => {
  const betContract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    contract.abi,
    await provider.getSigner()
  );
  await betContract.transferEther();
};
</script>

<template>
  <q-page class="fit">
    <q-card class="mainCard">
      <q-scroll-area style="height: 48em">
        <q-card-section>
          <div class="text-h4 mainSign" @click="getETH">
            Active Transactions
          </div>
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
                      TEAMS.find((row) => row.id === Number(JSON.parse(tx)[2]))
                        .name
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
          <div class="text-h4 mainSign" @click="getETH">Past Transactions</div>
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
                      TEAMS.find((row) => row.id === Number(JSON.parse(tx)[2]))
                        .name
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
        </q-card-section>
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
.mainCard {
  margin: 1em 0.5em 0 0;
  border: 5px $grey-4 solid;
  border-radius: 5px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
  height: 100%;
  width: 25%;
  float: right;
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
