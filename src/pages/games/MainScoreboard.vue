<script setup>
import { ref, watchEffect } from 'vue';
const today = new Date(Date.now());
const year = today.getFullYear();
const month = (today.getMonth() + 1).toString().padStart(2, '0');
const day = today.getDate().toString().padStart(2, '0');
const todayFormatted = ref(`${year}-${month}-${day}`);
const selectedDate = ref(todayFormatted.value);
const date = ref(todayFormatted.value);
const gamesArray = ref([]);
watchEffect(async () => {
  selectedDate.value = date.value.replace(/\//g, '-');
  await fetch(
    `https://api.sportsdata.io/v3/nba/scores/json/GamesByDate/${selectedDate.value}?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData.json().then((data) => (gamesArray.value = data))
  );
});
</script>
<template>
  <div class="text-h5 text-center q-my-xl">
    Game Schedule: {{ selectedDate }}
    <q-icon name="event" class="cursor-pointer">
      <q-popup-proxy cover :breakpoint="600">
        <q-date v-model="date" minimal />
      </q-popup-proxy>
    </q-icon>
  </div>
  <div class="q-mt-xl">
    <q-card v-if="gamesArray.length > 0">
      <q-card-section>
        <div class="row">
          <div
            class="text-center"
            v-for="games in gamesArray"
            :key="games.GameID"
          >
            <RouterLink
              style="text-decoration: none"
              :to="`/games/${games.GameID}`"
            >
              <div class="gameCard">
                <div>
                  {{
                    games.Status === 'Scheduled'
                      ? new Date(games.DateTime).toLocaleTimeString([], {
                          hour: '2-digit',
                          minute: '2-digit',
                        })
                      : games.Status
                  }}
                </div>
                <div>
                  {{ games.AwayTeam }}
                  <span v-if="games.AwayTeamScore > 0"
                    >: {{ games.AwayTeamScore }}</span
                  >
                </div>
                <q-separator color="white" />
                <div>
                  <span class="text-red">@</span>
                  {{ games.HomeTeam }}
                  <span v-if="games.HomeTeamScore > 0"
                    >: {{ games.HomeTeamScore }}</span
                  >
                </div>
              </div>
            </RouterLink>
          </div>
        </div>
      </q-card-section>
    </q-card>
    <div v-else class="text-h4 text-bold text-center">
      {{ 'No Games Today' }}
    </div>
  </div>
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
  background-color: $grey-2;
}
</style>
