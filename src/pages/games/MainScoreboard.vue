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
    `https://www.balldontlie.io/api/v1/games?start_date=${selectedDate.value}&end_date=${selectedDate.value}`
  ).then((responseData) =>
    responseData.json().then((data) => (gamesArray.value = data.data))
  );
});
</script>
<template>
  <div class="text-h4 text-center q-my-xl">
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
          <div class="text-center" v-for="games in gamesArray" :key="games.id">
            <RouterLink
              style="text-decoration: none"
              :to="`/games/${games.id}`"
            >
              <div class="gameCard">
                <div>
                  {{
                    games.period === 0
                      ? new Date(games.date).toLocaleTimeString([], {
                          hour: '2-digit',
                          minute: '2-digit',
                        })
                      : games.status
                  }}
                </div>
                <div>
                  {{ games.visitor_team.abbreviation }}
                  <span v-if="games.period > 0"
                    >: {{ games.visitor_team_score }}</span
                  >
                </div>
                <q-separator color="white" />
                <div>
                  <span class="text-yellow-14">@</span>
                  {{ games.home_team.abbreviation }}
                  <span v-if="games.period > 0"
                    >: {{ games.home_team_score }}</span
                  >
                </div>
              </div>
            </RouterLink>
          </div>
        </div>
      </q-card-section>
    </q-card>
    <div v-else class="text-h6 text-center">{{ 'No Games Today' }}</div>
  </div>
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
.respons {
  width: 15em;
  height: 10em;
}
</style>
