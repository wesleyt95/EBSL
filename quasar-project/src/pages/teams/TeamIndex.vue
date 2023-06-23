<script setup>
import { watchEffect, ref } from 'vue';
import { TEAMS } from './nba-teams.js';
import { useRoute } from 'vue-router';

const router = useRoute();
const gamesArray = ref([]);

watchEffect(async () => {
  await fetch(
    `https://www.balldontlie.io/api/v1/games?seasons[]=2022&team_ids[]=${router.params.id}&per_page=100`
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) =>
          (gamesArray.value = data.data.sort(
            (a, b) => new Date(b.date) - new Date(a.date)
          ))
      )
  );
});
</script>
<template>
  <h1>
    {{ TEAMS.find((row) => row.id === Number($route.params.id)).full_name }}
  </h1>
  <div v-for="game in gamesArray" :key="game.id">
    <RouterLink style="text-decoration: none" :to="`/games/${game.id}`" replace>
      <q-card class="text-red bg-blue-grey-10 q-ma-md text-center">
        <q-card-section>
          <q-item-label>{{
            game.home_team.full_name + ' vs. ' + game.visitor_team.full_name
          }}</q-item-label>
          <div>
            {{ game.home_team_score + ' - ' + game.visitor_team_score }}
          </div>
        </q-card-section>
      </q-card>
    </RouterLink>
  </div>
</template>
