<script setup>
import { ref, watchEffect, computed } from 'vue';
import { useRoute } from 'vue-router';
import { TEAMS } from '../teams/nba-teams.js';

const router = useRoute();
const playerArray = ref([]);
const regularSeason = ref([]);
const postSeason = ref([]);
const averages = ref([]);
const averagesPlayoffs = ref([]);
const gamesPlayed = ref();
const gamesPlayedPlayoffs = ref();

const fullName = computed(() => {
  return playerArray.value.FirstName + ' ' + playerArray.value.LastName;
});

const team = computed(() => {
  if (playerArray.value.Team) {
    return (
      TEAMS.find((row) => row.Key === playerArray.value.Team).City +
      ' ' +
      TEAMS.find((row) => row.Key === playerArray.value.Team).Name
    );
  } else return null;
});

const height = computed(() => {
  if (playerArray.value.Height) {
    return (
      Math.floor(playerArray.value.Height / 12) +
      "'" +
      (playerArray.value.Height % 12)
    );
  } else return null;
});

const statColumns = [
  {
    name: 'HomeOrAway',
    label: '',
    field: 'HomeOrAway',
    align: 'right',
    format: (val) => (val === 'AWAY' ? '@' : 'vs'),
  },
  {
    name: 'Opponent',
    label: '',
    field: 'Opponent',
    align: 'left',
    format: (val) => {
      const team = TEAMS.find((row) => row.Key === val);
      return team.City + ' ' + team.Name;
    },
  },
  {
    name: 'Minutes',
    label: 'Minutes',
    field: 'Minutes',
  },
  {
    name: 'Points',
    label: 'Points',
    field: 'Points',
  },
  { name: 'Rebounds', label: 'Rebounds', field: 'Rebounds' },
  { name: 'Assists', label: 'Assists', field: 'Assists' },
  { name: 'Steals', label: 'Steals', field: 'Steals' },
  { name: 'BlockedShots', label: 'Blocks', field: 'BlockedShots' },
];

const averageColumns = [
  {
    name: 'Points',
    label: 'Points',
    field: 'Points',
    format: (val) => (val / gamesPlayed.value).toFixed(1),
  },
  {
    name: 'Rebounds',
    label: 'Rebounds',
    field: 'Rebounds',
    format: (val) => (val / gamesPlayed.value).toFixed(1),
  },
  {
    name: 'Assists',
    label: 'Assists',
    field: 'Assists',
    format: (val) => (val / gamesPlayed.value).toFixed(1),
  },
  {
    name: 'Steals',
    label: 'Steals',
    field: 'Steals',
    format: (val) => (val / gamesPlayed.value).toFixed(1),
  },
  {
    name: 'BlockedShots',
    label: 'Blocks',
    field: 'BlockedShots',
    format: (val) => (val / gamesPlayed.value).toFixed(1),
  },
  {
    name: 'FieldGoalsPercentage',
    label: 'FG %',
    field: 'FieldGoalsPercentage',
  },
  {
    name: 'ThreePointersPercentage',
    label: '3pt %',
    field: 'ThreePointersPercentage',
  },
  {
    name: 'FreeThrowsPercentage',
    label: 'FT %',
    field: 'FreeThrowsPercentage',
  },
  {
    name: 'PlayerEfficiencyRating',
    label: 'PER',
    field: 'PlayerEfficiencyRating',
  },
];

watchEffect(async () => {
  await fetch(
    `https://api.sportsdata.io/v3/nba/scores/json/Player/${router.params.id}?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData.json().then((data) => (playerArray.value = data))
  );

  await fetch(
    `https://api.sportsdata.io/v3/nba/stats/json/PlayerGameStatsBySeason/${process.env.SPORTSDATA_API_YEAR}/${router.params.id}/all?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData.json().then((data) => {
      regularSeason.value = data;
    })
  );

  await fetch(
    `https://api.sportsdata.io/v3/nba/stats/json/PlayerSeasonStats/${process.env.SPORTSDATA_API_YEAR}?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) => (
          (averages.value = data.find(
            (row) => row.PlayerID === Number(router.params.id)
          )),
          (gamesPlayed.value = averages.value?.Games)
        )
      )
  );
  await fetch(
    `https://api.sportsdata.io/v3/nba/stats/json/PlayerGameStatsBySeason/${process.env.SPORTSDATA_API_YEAR}POST/${router.params.id}/all?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData.json().then((data) => {
      postSeason.value = data;
    })
  );
  if (postSeason.value.length > 0) {
    await fetch(
      `https://api.sportsdata.io/v3/nba/stats/json/PlayerSeasonStats/${process.env.SPORTSDATA_API_YEAR}POST?key=${process.env.SPORTSDATA_API_KEY}`
    ).then((responseData) =>
      responseData
        .json()
        .then(
          (data) => (
            (averagesPlayoffs.value = data.find(
              (row) => row.PlayerID === Number(router.params.id)
            )),
            (gamesPlayedPlayoffs.value = averagesPlayoffs.value.Games)
          )
        )
    );
  }
});
</script>
<template>
  <q-card>
    <q-card-section>
      <div class="row items-center justify-evenly q-ma-auto q-pa-auto fit">
        <q-card class="text-center">
          <q-card-section>
            <q-img
              style="max-width: 8em"
              fit="contain"
              :key="playerArray.PhotoUrl"
              :src="playerArray.PhotoUrl"
            />
            <div :key="playerArray.FirstName">
              Name:
              {{ fullName }}
            </div>
            <div :key="playerArray.Position">
              Position: {{ playerArray.Position }}
            </div>
            <div :key="playerArray.Height">
              Height:
              {{ height }}
            </div>
            <div :key="playerArray.Weight">
              Weight: {{ playerArray.Weight }}
            </div>
            <div :key="playerArray.BirthCity">
              Born: {{ playerArray.BirthCity }}, {{ playerArray.BirthCountry }}
            </div>
            <div
              v-if="playerArray.College !== 'None'"
              :key="playerArray.College"
            >
              College: {{ playerArray.College }}
            </div>
            <div :key="playerArray.Team">
              Team:
              <RouterLink :key="team" :to="`/teams/${playerArray.TeamID}`">{{
                (playerArray.Team, team)
              }}</RouterLink>
            </div>
          </q-card-section>
        </q-card>

        <div v-if="regularSeason.length > 0">
          <q-table
            title="Regular Season Averages"
            :rows="[averages]"
            :columns="averageColumns"
            row-key="PlayerID"
            :rows-per-page-options="[0]"
            :auto-width="true"
            virtual-scroll
            style="height: 10em"
            no-data-label="No data available"
            :dense="true"
          />
          <q-table
            v-if="postSeason.length > 0"
            title="Post Season Averages"
            :rows="[averagesPlayoffs]"
            :columns="averageColumns"
            row-key="PlayerID"
            :rows-per-page-options="[0]"
            :auto-width="true"
            virtual-scroll
            style="height: 10em; margin-top: 1em"
            no-data-label="No data available"
            :dense="true"
          />
        </div>
      </div>
    </q-card-section>
    <q-card-section v-if="regularSeason.length > 0">
      <div class="q-pa-md">
        <q-table
          title="Regular Season"
          :rows="regularSeason"
          :columns="statColumns"
          row-key="id"
          :rows-per-page-options="[0]"
          :auto-width="true"
          virtual-scroll
          style="height: 30em"
          no-data-label="No data available"
          @row-click="
            (evt, row, index) => $router.push({ path: `/games/${row.GameID}` })
          "
        />
        <q-table
          v-if="postSeason.length > 0"
          title="Post Season"
          :rows="postSeason"
          :columns="statColumns"
          row-key="id"
          :rows-per-page-options="[0]"
          :auto-width="true"
          virtual-scroll
          style="height: 30em; margin-top: 2em"
          no-data-label="No data available"
          @row-click="
            (evt, row, index) => $router.push({ path: `/games/${row.GameID}` })
          "
        />
      </div>
    </q-card-section>
  </q-card>
</template>
