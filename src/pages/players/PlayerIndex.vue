<script setup>
import { ref, watchEffect, computed } from 'vue';
import { useRoute } from 'vue-router';
import { TEAMS } from '../teams/nba-teams.js';

const router = useRoute();
const playerArray = ref([]);
const regularSeason = ref([]);
const postSeason = ref([]);
const averages = ref([]);

const fullName = computed(() => {
  return playerArray.value.first_name + ' ' + playerArray.value.last_name;
});

const position = computed(() => {
  return playerArray.value.position;
});

const height = computed(() => {
  return playerArray.value.height_feet + '\`' + playerArray.value.height_inches;
});

const weight = computed(() => {
  return playerArray.value.weight_pounds + ' lbs';
});

const team = computed(() => {
  return playerArray.value.team?.full_name;
});

const teamID = computed(() => {
  return playerArray.value.team?.id;
});

const statColumns = [
  {
    name: 'game',
    label: 'Game',
    field: 'game',
    format: (val) =>
      `${TEAMS.find((row) => row.id === val.visitor_team_id).name} @ ${
        TEAMS.find((row) => row.id === val.home_team_id).name
      }` + ` (${new Date(val.date).toLocaleDateString()})`,
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

const averageColumns = [
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
    `https://www.balldontlie.io/api/v1/players/${Number(router.params.id)}`
  ).then((responseData) =>
    responseData.json().then((data) => (playerArray.value = data))
  );

  await fetch(
    `https://www.balldontlie.io/api/v1/stats?seasons[]=2022&player_ids[]=${Number(
      router.params.id
    )}&per_page=100&postseason=false`
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) =>
          (regularSeason.value = data.data.sort(
            (a, b) => new Date(b.game.date) - new Date(a.game.date)
          ))
      )
  );

  await fetch(
    `https://www.balldontlie.io/api/v1/stats?seasons[]=2022&player_ids[]=${Number(
      router.params.id
    )}&per_page=100&postseason=true`
  ).then((responseData) =>
    responseData
      .json()
      .then(
        (data) =>
          (postSeason.value = data.data.sort(
            (a, b) => new Date(b.game.date) - new Date(a.game.date)
          ))
      )
  );

  await fetch(
    `https://www.balldontlie.io/api/v1/season_averages?player_ids[]=${Number(
      router.params.id
    )}`
  ).then((responseData) =>
    responseData.json().then((data) => (averages.value = data.data))
  );
});
</script>
<template>
  <q-card>
    <q-card-section>
      <div class="row items-center justify-evenly q-ma-auto q-pa-auto fit">
        <q-card class="text-center">
          <q-card-section>
            <div>
              Name:
              {{ fullName }}
            </div>
            <div
              v-if="playerArray.position != null && playerArray.position !== ''"
            >
              Position: {{ position }}
            </div>
            <div v-if="playerArray.height_feet != null">
              Height:
              {{ height }}
            </div>
            <div v-if="playerArray.weight_pounds != null">
              Weight: {{ weight }}
            </div>
            <div>
              Team:
              <RouterLink :to="`/teams/${teamID}`">{{ team }}</RouterLink>
            </div>
          </q-card-section>
        </q-card>

        <div>
          <q-table
            title="Regular Season Averages"
            :rows="averages"
            :columns="averageColumns"
            row-key="id"
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
            (evt, row, index) =>
              this.$router.replace({ path: `/games/${row.game.id}` })
          "
        />
      </div>
      <div class="q-pa-md">
        <q-table
          title="Playoffs"
          :rows="postSeason"
          :columns="statColumns"
          row-key="id"
          :rows-per-page-options="[0]"
          :auto-width="true"
          virtual-scroll
          style="height: 30em"
          no-data-label="No data available"
          @row-click="
            (evt, row, index) =>
              this.$router.replace({ path: `/games/${row.game.id}` })
          "
        />
      </div>
    </q-card-section>
  </q-card>
</template>
