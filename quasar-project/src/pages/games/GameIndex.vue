<script setup>
import { ref, watchEffect } from 'vue';
import { useRoute } from 'vue-router';
const router = useRoute();

const gameArray = ref([]);
const statsArray = ref([]);

watchEffect(async () => {
  if (gameArray.value?.length === 0) {
    await fetch(
      `https://www.balldontlie.io/api/v1/games/${Number(router.params.id)}`
    ).then((responseData) =>
      responseData.json().then((data) => (gameArray.value = data))
    );
  }

  if (statsArray.value?.length === 0) {
    await fetch(
      `https://www.balldontlie.io/api/v1/stats?game_ids[]=${Number(
        router.params.id
      )}`
    ).then((responseData) =>
      responseData
        .json()
        .then((data) => (statsArray.value = data.data), console.log(statsArray))
    );
  }
});
</script>
<template>
  <q-page class="bg-grey-4">
    <div class="bg-grey-4">
      <q-card class="mainCard">
        <q-card-section
          class="row items-center flex-center justify-between text-h3"
        >
          <div>{{ gameArray.visitor_team?.full_name }}</div>
          <div class="align-center">@</div>
          <div>{{ gameArray.home_team?.full_name }}</div>
        </q-card-section>
        <q-card-section
          v-if="gameArray.period === 0"
          class="row items-center flex-center justify-between"
        >
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
        </q-card-section>
        <q-card-section class="row items-center justify-between" v-else>
          <div class="text-h3">
            {{ gameArray.visitor_team_score }}
          </div>
          <div class="text-md align-center">
            <div v-if="gameArray.postseason === true">Playoffs</div>
            <div>{{ gameArray.time }}</div>
            <div>{{ gameArray.status }}</div>
          </div>
          <div class="text-h3">
            {{ gameArray.home_team_score }}
          </div>
        </q-card-section>
        <q-card-section v-if="gameArray.period > 0">
          <div v-for="stat in statsArray" :key="stat.player.id">
            <div
              v-if="gameArray.visitor_team?.full_name === stat.team.full_name"
              class="float-left"
            >
              <ul style="display: block">
                <li style="display: list-item">
                  <div>{{ stat.player.first_name }}</div>
                </li>
              </ul>
            </div>
            <div v-else class="float-right">
              <ul style="display: block">
                <li style="display: list-item">
                  <div>{{ stat.player.first_name }}</div>
                </li>
              </ul>
            </div>
          </div>
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>
<style lang="scss" scoped>
.mainCard {
  margin: auto;
  color: $blue-grey-10;
  background-color: $grey-1;
  border: 2px red solid;
  border-radius: 5px;
  padding: 5px;
  width: 95%;
}
</style>
