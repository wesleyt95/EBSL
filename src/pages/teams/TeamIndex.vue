<script setup>
import { watchEffect, ref } from 'vue';
import { TEAMS } from './nba-teams.js';
import { useRoute, useRouter } from 'vue-router';

const router = useRoute();
const pushRoute = useRouter();
const team = TEAMS.find((row) => row.TeamID === Number(router.params.id));
const playersArray = ref([]);
const gamesArray = ref([]);
const gamesArrayPlayoffs = ref([]);
const today = new Date(Date.now());
const year = today.getFullYear();
const month = (today.getMonth() + 1).toString().padStart(2, '0');
const day = today.getDate().toString().padStart(2, '0');
const todayFormatted = ref(`${year}-${month}-${day}`);
const selectedDate = ref(todayFormatted.value);

const getGameID = async (date) => {
  await fetch(
    `https://api.sportsdata.io/v3/nba/scores/json/GamesByDate/${date}?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData.json().then((data) => {
      const filteredData = data.filter((game) => {
        return game.HomeTeam === team.Key || game.AwayTeam === team.Key;
      })[0].GameID;

      pushRoute.push({
        path: `/games/${filteredData}`,
      });
    })
  );
};
const gameDate = (date) => {
  if (date.split('T')[0] === selectedDate.value) {
    return new Date(date).toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
    });
  } else {
    return date.split('T')[0];
  }
};

watchEffect(async () => {
  await fetch(
    `https://www.balldontlie.io/api/v1/games?seasons[]=${
      Number(process.env.SPORTSDATA_API_YEAR) - 1
    }&team_ids[]=${team.id}&per_page=100&postseason=false`
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) =>
          (gamesArray.value = data.data
            .sort((a, b) => new Date(b.date) - new Date(a.date))
            .reverse())
      )
  );
  await fetch(
    `https://www.balldontlie.io/api/v1/games?seasons[]=${
      Number(process.env.SPORTSDATA_API_YEAR) - 1
    }&team_ids[]=${team.id}&per_page=100&postseason=true`
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) =>
          (gamesArrayPlayoffs.value = data.data
            .sort((a, b) => new Date(b.date) - new Date(a.date))
            .reverse())
      )
  );
  await fetch(
    `https://api.sportsdata.io/v3/nba/scores/json/PlayersBasic/${team.Key}?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData.json().then((data) => (playersArray.value = data))
  );
});

const playerColumns = [
  {
    name: 'Position',
    label: '',
    field: 'Position',
    align: 'right',
  },
  {
    name: 'FirstName',
    label: '',
    field: 'FirstName',
    align: 'right',
  },
  {
    name: 'LastName',
    label: 'Name',
    field: 'LastName',
    align: 'left',
  },

  {
    name: 'BirthCountry',
    label: 'Country',
    field: 'BirthCountry',
  },
  {
    name: 'BirthDate',
    label: 'Birth Date',
    field: 'BirthDate',
    format: (val) => new Date(val).toLocaleDateString(),
  },
  { name: 'Status', label: 'Status', field: 'Status' },
];
</script>
<template>
  <h3 class="q-mb-xs text-center">
    <q-img
      fit="contain"
      style="max-height: 2em; max-width: 2em"
      :src="team.WikipediaLogoUrl"
    />
  </h3>
  <h2 class="text-center q-mt-xs">{{ team.City }} {{ team.Name }}</h2>
  <q-card>
    <q-card-section>
      <div>
        <q-table
          title="Current Roster"
          :rows="playersArray"
          :columns="playerColumns"
          :row-key="(row) => row.PlayerID"
          :rows-per-page-options="[0]"
          :auto-width="true"
          virtual-scroll
          style="height: 30em"
          @row-click="
            (evt, row, index) =>
              $router.push({ path: `/players/${row.PlayerID}` })
          "
        />
      </div>
    </q-card-section>
  </q-card>
  <q-card v-if="gamesArrayPlayoffs.length > 0" class="text-center">
    <div class="text-h4 q-pt-md">Playoffs</div>
    <q-card-section class="row">
      <div v-for="game in gamesArrayPlayoffs" :key="game.id">
        <div
          class="gameCard shadow-2"
          @click="getGameID(new Date(game.date).toISOString().split('T')[0])"
        >
          <div>
            {{ game.period === 0 ? gameDate(game.date) : game.status }}
          </div>
          <div>
            {{ game.visitor_team.abbreviation }}
            <span v-if="game.period > 0">: {{ game.visitor_team_score }}</span>
          </div>
          <q-separator color="white" />
          <div>
            <span class="text-red">@</span>
            {{ game.home_team.abbreviation }}
            <span v-if="game.period > 0">: {{ game.home_team_score }}</span>
          </div>
        </div>
      </div>
    </q-card-section>
  </q-card>
  <q-card class="text-center">
    <div class="text-h4 q-pt-md">Regular Season</div>
    <q-card-section class="row">
      <div v-for="game in gamesArray" :key="game.id">
        <div
          class="gameCard"
          @click="getGameID(new Date(game.date).toISOString().split('T')[0])"
        >
          <div>
            {{ game.period === 0 ? gameDate(game.date) : game.status }}
          </div>
          <div>
            {{ game.visitor_team.abbreviation }}
            <span v-if="game.period > 0">: {{ game.visitor_team_score }}</span>
          </div>
          <q-separator color="white" />
          <div>
            <span class="text-red">@</span>
            {{ game.home_team.abbreviation }}
            <span v-if="game.period > 0">: {{ game.home_team_score }}</span>
          </div>
        </div>
      </div>
    </q-card-section>
  </q-card>
</template>
<style scoped lang="scss">
.gameCard {
  color: $blue-grey-10;
  margin: 5px;
  background-color: $grey-1;
  border: 2px $grey-6 solid;
  border-radius: 5px;
  padding: 5px;
  width: 8em;
}
.gameCard:hover {
  cursor: pointer;
  background-color: $grey-2;
}
</style>
