<script setup>
// import { Todo, Meta } from 'components/models';
// import ExampleComponent from 'components/ExampleComponent.vue';
import { ref } from 'vue';

const history = ref('Example');
</script>

<template>
  <q-page class="row items-center justify-evenly bg-grey-4">
    <q-card class="mainCard">
      <q-card-section>
        <div class="text-h4 mainSign">Past Transactions</div>
        <div class="text-subtitle2">by John Doe</div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ history }}</div>
      </q-card-section>
    </q-card>
    <q-card class="mainCard">
      <q-card-section>
        <div class="text-h4 mainSign">Active Transactions</div>
        <div class="text-subtitle2">by John Doe</div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ history }}</div>
      </q-card-section>
    </q-card>
    <q-card class="mainCard">
      <q-card-section>
        <div class="text-h4 mainSign">EBSL Leaderboard</div>
        <div class="text-subtitle2">by John Doe</div>
      </q-card-section>

      <q-card-section class="q-pt-none">
        <div>{{ history }}</div>
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
  border: 2px $blue-grey-10 solid;
  border-radius: 5px;
  padding: 1em;
  color: $blue-grey-10;
  background: $grey-1;
}
</style>
