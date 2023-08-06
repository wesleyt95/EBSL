<script setup>
import { watchEffect, ref } from 'vue';
import { TEAMS } from './nba-teams.js';
import { useRoute } from 'vue-router';

const router = useRoute();
const team = TEAMS.find((row) => row.TeamID === Number(router.params.id));
const playersArray = ref([]);
const gamesArray = ref([]);
const gamesArrayPlayoffs = ref([]);

watchEffect(async () => {
  await fetch(
    `https://www.balldontlie.io/api/v1/games?seasons[]=2022&team_ids[]=${team.id}&per_page=100&postseason=false`
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
    `https://www.balldontlie.io/api/v1/games?seasons[]=2022&team_ids[]=${team.id}&per_page=100&postseason=true`
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
  await fetch(
    `https://api.sportsdata.io/v3/nba/scores/json/PlayersBasic/${team.Key}?key=791f4f4fb36a49b69188829ef354d39b`
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
  <h3 class="text-center">
    {{ team.Name
    }}<q-img height="1.7em" width="1.7em" :src="team.WikipediaLogoUrl"></q-img>
  </h3>
  <q-card
    ><q-card-section>
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
              this.$router.replace({ path: `/players/${row.PlayerID}` })
          "
        /></div></q-card-section
  ></q-card>
  <q-card v-if="gamesArrayPlayoffs.length > 0" class="text-center">
    <div class="text-h4 q-pt-md">Playoffs</div>
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
