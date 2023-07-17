<script setup>
import { watchEffect, ref } from 'vue';
import { TEAMS } from './nba-teams.js';
import { useRoute } from 'vue-router';

const router = useRoute();
const gamesArray = ref([]);
const gamesArrayPlayoffs = ref([]);

watchEffect(async () => {
  await fetch(
    `https://www.balldontlie.io/api/v1/games?seasons[]=2022&team_ids[]=${router.params.id}&per_page=100&postseason=false`
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
  await fetch(
    `https://www.balldontlie.io/api/v1/games?seasons[]=2022&team_ids[]=${router.params.id}&per_page=100&postseason=true`
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) =>
          (gamesArrayPlayoffs.value = data.data.sort(
            (a, b) => new Date(b.date) - new Date(a.date)
          ))
      )
  );
});
</script>
<template>
  <h3 class="text-center">
    {{ TEAMS.find((row) => row.id === Number($route.params.id)).full_name
    }}<q-img
      height="1.7em"
      width="1.7em"
      :src="TEAMS.find((row) => row.id === Number($route.params.id)).logo"
    ></q-img>
  </h3>
  <q-card v-if="gamesArrayPlayoffs.length > 0" class="text-center">
    <div class="text-h4 q-pt-md">Post Season</div>
    <q-card-section class="row">
      <div v-for="game in gamesArrayPlayoffs" :key="game.id">
        <RouterLink style="text-decoration: none" :to="`/games/${game.id}`">
          <div class="gameCard">
            <div>
              {{
                game.period === 0
                  ? new Date(game.date).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })
                  : game.status
              }}
            </div>
            <div>
              {{ game.visitor_team.abbreviation }}
              <span v-if="game.period > 0"
                >: {{ game.visitor_team_score }}</span
              >
            </div>
            <q-separator color="white" />
            <div>
              <span class="text-yellow-14">@</span>
              {{ game.home_team.abbreviation }}
              <span v-if="game.period > 0">: {{ game.home_team_score }}</span>
            </div>
          </div>
        </RouterLink>
      </div>
    </q-card-section>
  </q-card>
  <q-card class="text-center">
    <div class="text-h4 q-pt-md">Regular Season</div>
    <q-card-section class="row">
      <div v-for="game in gamesArray" :key="game.id">
        <RouterLink style="text-decoration: none" :to="`/games/${game.id}`">
          <div class="gameCard">
            <div>
              {{
                game.period === 0
                  ? new Date(game.date).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })
                  : game.status
              }}
            </div>
            <div>
              {{ game.visitor_team.abbreviation }}
              <span v-if="game.period > 0"
                >: {{ game.visitor_team_score }}</span
              >
            </div>
            <q-separator color="white" />
            <div>
              <span class="text-yellow-14">@</span>
              {{ game.home_team.abbreviation }}
              <span v-if="game.period > 0">: {{ game.home_team_score }}</span>
            </div>
          </div>
        </RouterLink>
      </div>
    </q-card-section>
  </q-card>
</template>
<style scoped lang="scss">
.gameCard {
  color: $grey-1;
  margin: 5px;
  background-color: $blue-grey-10;
  border: 2px red solid;
  border-radius: 5px;
  padding: 5px;
  width: 8em;
}
</style>
