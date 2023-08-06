<script setup>
import { ref, watchEffect, computed } from 'vue';
import { useRoute } from 'vue-router';
import { TEAMS } from '../teams/nba-teams.js';

const router = useRoute();
const playerArray = ref([]);
const regularSeason = ref([]);
const averages = ref([]);
const gamesPlayed = ref();

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
];

watchEffect(async () => {
  await fetch(
    // `https://www.balldontlie.io/api/v1/players/${Number(router.params.id)}`
    `https://api.sportsdata.io/v3/nba/scores/json/Player/${router.params.id}?key=791f4f4fb36a49b69188829ef354d39b`
  ).then((responseData) =>
    responseData.json().then((data) => (playerArray.value = data))
  );

  await fetch(
    `https://api.sportsdata.io/v3/nba/stats/json/PlayerGameStatsBySeason/2023/${router.params.id}/all?key=791f4f4fb36a49b69188829ef354d39b`
  ).then((responseData) =>
    responseData.json().then((data) => {
      regularSeason.value = data;
    })
  );

  await fetch(
    'https://api.sportsdata.io/v3/nba/stats/json/PlayerSeasonStats/2023?key=791f4f4fb36a49b69188829ef354d39b'
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) => (
          (averages.value = data.find(
            (row) => row.PlayerID === Number(router.params.id)
          )),
          (gamesPlayed.value = averages.value.Games)
        )
      )
  );
});
</script>
<template>
  <q-card>
    <q-card-section>
      <div class="row items-center justify-evenly q-ma-auto q-pa-auto fit">
        <q-card class="text-center">
          <q-card-section>
            <q-img :key="playerArray.PhotoUrl" :src="playerArray.PhotoUrl" />
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
            <div :key="playerArray.Team">
              Team:
              <RouterLink :key="team" :to="`/teams/${playerArray.TeamID}`">{{
                (playerArray.Team, team)
              }}</RouterLink>
            </div>
          </q-card-section>
        </q-card>

        <div>
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
        </div>
      </div>
    </q-card-section>
    <q-card-section>
      <div class="q-pa-md">
        <q-table
          title="Box Score"
          :rows="regularSeason"
          :columns="statColumns"
          row-key="id"
          :rows-per-page-options="[0]"
          :auto-width="true"
          virtual-scroll
          style="height: 30em"
          no-data-label="No data available"
          @row-click="
            (evt, row, index) =>
              this.$router.replace({ path: `/games/${row.GameID}` })
          "
        />
      </div>
    </q-card-section>
  </q-card>
</template>
