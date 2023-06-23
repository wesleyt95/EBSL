<script setup>
import { ref, watchEffect } from 'vue';
import { useRoute } from 'vue-router';
import { ethers } from 'ethers';

const router = useRoute();
const gameTotal = ref();
const provider = new ethers.BrowserProvider(window.ethereum);
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');
const gameArray = ref([]);
const statsArrayAway = ref([]);
const statsArrayHome = ref([]);
const statColumns = [
  {
    name: 'player',
    label: 'Name',
    field: 'player',
    format: (val) => `${val.first_name} ${val.last_name}`,
    align: 'left',
  },
  {
    name: 'min',
    label: 'Minutes',
    field: 'min',
  },
  {
    name: 'pts',
    label: 'Points',
    field: 'pts',
  },
  { name: 'reb', label: 'Rebounds', field: 'reb' },
  { name: 'ast', label: 'Assists', field: 'ast' },
  { name: 'stl', label: 'Steals', field: 'stl' },
  { name: 'blk', label: 'Blocks', field: 'blk' },
];

watchEffect(async () => {
  await fetch(
    `https://www.balldontlie.io/api/v1/games/${Number(router.params.id)}`
  ).then((responseData) =>
    responseData.json().then((data) => (gameArray.value = data))
  );

  await fetch(
    `https://www.balldontlie.io/api/v1/stats?game_ids[]=${Number(
      router.params.id
    )}`
  ).then((responseData) =>
    responseData.json().then((data) => {
      statsArrayAway.value = data.data.filter(
        (row) => row.team.id === gameArray.value.visitor_team.id
      );
      statsArrayHome.value = data.data.filter(
        (row) => row.team.id === gameArray.value.home_team.id
      );
    })
  );
  if (gameTotal.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      provider
    );

    gameTotal.value = await betContract.totalBetOnGame(
      Number(router.params.id)
    );
    console.log(gameTotal.value);
  }
});
</script>
<template>
  <q-page>
    <div>
      <q-card class="mainCard">
        <q-card-section>
          <div class="row items-center justify-evenly text-h3 text-center">
            <div style="width: 40%">
              {{ gameArray.visitor_team?.full_name }}
            </div>
            <div style="width: 10%">@</div>
            <div style="width: 40%">
              {{ gameArray.home_team?.full_name }}
            </div>
          </div>
        </q-card-section>
        <q-card-section v-if="gameArray.period === 0">
          <div class="row items-center justify-evenly text-center">
            <div>
              {{ gameArray.visitor_team?.division }} Division|{{
                gameArray.visitor_team?.conference
              }}ern Conference
            </div>
            <div class="text-md align-center">
              <div v-if="gameArray.postseason === true">Playoffs</div>
              <div>{{ new Date(gameArray.date).toLocaleTimeString() }}</div>
              <div>{{ new Date(gameArray.date).toLocaleDateString() }}</div>
            </div>
            <div>
              {{ gameArray.home_team?.division }} Division|{{
                gameArray.home_team?.conference
              }}ern Conference
            </div>
          </div>
        </q-card-section>
        <q-card-section v-else>
          <div
            style="width: 80%"
            class="row items-center justify-evenly text-center q-mx-auto"
          >
            <div>
              <q-btn>Place Bet</q-btn>
            </div>
            <div class="row items-center justify-evenly text-center score">
              <div>
                <span>Away</span>
                <div style="font-weight: 800" class="text-h3">
                  {{ gameArray.visitor_team_score }}
                </div>
              </div>
              <div class="text-md align-center">
                <div v-if="gameArray.postseason === true">Playoffs</div>
                <div v-if="gameArray.status !== 'Final'">
                  {{ gameArray.time }}
                </div>
                <div>{{ gameArray.status }}</div>
                <div>{{ `${gameTotal} ETH` }}</div>
              </div>
              <div>
                <span>Home</span>
                <div style="font-weight: 800" class="text-h3">
                  {{ gameArray.home_team_score }}
                </div>
              </div>
            </div>
            <div>
              <q-btn>Place Bet</q-btn>
            </div>
          </div>
        </q-card-section>
        <q-card-section v-if="gameArray.period > 0">
          <div class="row items-center justify-evenly">
            <div>
              <q-table
                :title="gameArray.visitor_team.full_name"
                :rows="statsArrayAway"
                :columns="statColumns"
                :row-key="(row) => row.id"
                :rows-per-page-options="[0]"
                :auto-width="true"
                virtual-scroll
                style="height: 30em"
                @row-click="
                  (evt, row, index) =>
                    this.$router.replace({ path: `/players/${row.player.id}` })
                "
              />
            </div>
            <div>
              <q-table
                :title="gameArray.home_team.full_name"
                :rows="statsArrayHome"
                :columns="statColumns"
                :row-key="(row) => row.id"
                :rows-per-page-options="[0]"
                :auto-width="true"
                virtual-scroll
                style="height: 30em; width: 45em"
                @row-click="
                  (evt, row, index) =>
                    this.$router.replace({ path: `/players/${row.player.id}` })
                "
              />
            </div>
          </div>
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>
<style lang="scss" scoped>
.mainCard {
  margin: 2em;
  color: $blue-grey-10;
  background-color: $grey-1;
  border: 4px $grey-4 solid;
  border-radius: 5px;
  padding: 1em;
}
.score {
  color: $lime-12;
  background-color: black;
  border: 3px $lime-12 solid;
  border-radius: 10px;
  padding: 2em;
  margin: auto;
  width: 50%;
}
</style>
