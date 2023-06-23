<script setup>
import { TEAMS } from './nba-teams.js';
</script>
<template>
  <div class="q-pa-sm row justify-evenly">
    <div v-for="team in TEAMS" :key="team.id">
      <RouterLink style="text-decoration: none" :to="`/teams/${team.id}`">
        <q-card class="tile">
          <q-card-section>
            <q-img style="max-width: 12em" :src="team.logo" />
          </q-card-section>
          <q-card-section>
            <div class="text-h6">{{ team.full_name }}</div>
          </q-card-section>
        </q-card>
      </RouterLink>
    </div>
  </div>
</template>
<style lang="scss" scoped>
.tile {
  width: 20em;
  height: 20em;
  border-radius: 5px;
  background: $grey-1;
  color: $blue-grey-10;
  border: 4px $grey-4 solid;
  text-align: center;
  margin: 2em;
}
</style>
