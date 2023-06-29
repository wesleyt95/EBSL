<script setup>
// import { Todo, Meta } from 'components/models';
// import ExampleComponent from 'components/ExampleComponent.vue';
import { ref, watchEffect } from 'vue';
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
  <q-page class="row items-center justify-evenly">
    <q-card class="mainCard">
      <q-card-section>
        <div class="text-h4 mainSign" @click="getETH">Past Transactions</div>
        <div v-for="(tx, index) in transactionHistory" :key="index">
          <div>{{ JSON.parse(tx)[1] + ' ETH' }} | {{ JSON.parse(tx)[4] }}</div>
        </div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ null }}</div>
      </q-card-section>
    </q-card>
    <q-card class="mainCard">
      <q-card-section>
        <div class="text-h4 mainSign">Active Transactions</div>
        <div class="text-subtitle2">by John Doe</div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ null }}</div>
      </q-card-section>
    </q-card>
    <q-card class="mainCard">
      <q-card-section>
        <div class="text-h4 mainSign">EBSL Leaderboard</div>
        <div class="text-subtitle2">by John Doe</div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ null }}</div>
      </q-card-section>
    </q-card>
  </q-page>
</template>
<style lang="scss" scoped>
.mainSign {
  color: $yellow-14;
  border: 3px red solid;
  border-radius: 5px;
  font-weight: 1000;
  background: $blue-grey-10;
  padding: auto;
  margin: auto;
  text-align: center;
}
.mainCard {
  margin: 1em;
  border: 3px $grey-4 solid;
  border-radius: 5px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
}
</style>
