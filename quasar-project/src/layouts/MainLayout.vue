<script setup>
import { ref, watchEffect } from 'vue';
import { ethers } from 'ethers';
import EssentialLink from 'components/EssentialLink.vue';

const provider = new ethers.BrowserProvider(window.ethereum);
const isConnected = ref(false);
const balance = ref(BigInt(0));
const searchValue = ref('');
const searchArray = ref([]);

const datesArray = ref([]);
const selectedDate = ref(new Date(Date.now()).toISOString().split('T')[0]);
const gamesArray = ref([]);

function getDatesArray() {
  const dates = [];
  const today = new Date(Date.now());
  const todayFormatted = today.toISOString().split('T')[0];
  dates.push(todayFormatted);
  for (let i = -7; i <= 7; i++) {
    const nextDay = new Date(today);
    nextDay.setDate(today.getDate() + i);
    const nextDayFormatted = nextDay.toISOString().split('T')[0];
    if (!dates.includes(nextDayFormatted)) {
      dates.push(nextDayFormatted);
    }
  }
  dates.sort();
  datesArray.value = dates;
}
const currentAccounts = () => {
  return window.ethereum._state.accounts;
};

const getCurrentChain = () => {
  return window.ethereum.chainId;
};

const getSigner = async () => {
  if (window.ethereum == null) {
    console.log('MetaMask not installed; using read-only defaults');
    await ethers.getDefaultProvider();
  } else {
    await provider.getSigner();
  }
};

const getSearchResults = async () => {
  await fetch(
    `https://www.balldontlie.io/api/v1/players?search=${searchValue.value}`
  ).then((responseData) =>
    responseData.json().then((data) => (searchArray.value = data.data))
  );
};
watchEffect(async () => {
  if (datesArray.value?.length === 0) {
    getDatesArray();
  }
  await fetch(
    `https://www.balldontlie.io/api/v1/games?start_date=${selectedDate.value}&end_date=${selectedDate.value}`
  ).then((responseData) =>
    responseData.json().then((data) => (gamesArray.value = data.data))
  );

  if (window.ethereum != null) {
    isConnected.value = true;
    try {
      await provider.getBalance(currentAccounts()[0]).then((currentBalance) => {
        balance.value = currentBalance;
      });
    } catch (error) {
      alert(error);
    }
  } else {
    isConnected.value = false;
    balance.value = BigInt(0);
  }
});

const essentialLinks = [
  {
    title: 'Home',
    caption: 'Dashboard',
    icon: 'home',
    link: '/',
  },
  {
    title: 'Github',
    caption: 'github.com/quasarframework',
    icon: 'code',
    link: 'https://github.com/quasarframework',
  },
  {
    title: 'Discord Chat Channel',
    caption: 'chat.quasar.dev',
    icon: 'chat',
    link: 'https://chat.quasar.dev',
  },
  {
    title: 'Forum',
    caption: 'forum.quasar.dev',
    icon: 'record_voice_over',
    link: 'https://forum.quasar.dev',
  },
  {
    title: 'Twitter',
    caption: '@quasarframework',
    icon: 'rss_feed',
    link: 'https://twitter.quasar.dev',
  },
  {
    title: 'Facebook',
    caption: '@QuasarFramework',
    icon: 'public',
    link: 'https://facebook.quasar.dev',
  },
  {
    title: 'Quasar Awesome',
    caption: 'Community Quasar projects',
    icon: 'favorite',
    link: 'https://awesome.quasar.dev',
  },
];

const leftDrawerOpen = ref(false);

function toggleLeftDrawer() {
  leftDrawerOpen.value = !leftDrawerOpen.value;
}
</script>

<template>
  <q-layout view="lHh Lpr lFf">
    <q-header class="bg-grey-4" elevated>
      <q-toolbar class="bg-blue-grey-10">
        <q-btn
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          @click="toggleLeftDrawer"
        />

        <q-toolbar-title> EBSL </q-toolbar-title>
        <div v-if="isConnected == false">
          <q-btn
            disabled
            color="white"
            text-color="black"
            label="MetaMask Undetected"
          />
        </div>
        <div
          v-else-if="
            isConnected == true &&
            getCurrentChain() !== '0x1' &&
            currentAccounts().length > 0
          "
        >
          <q-btn
            disabled
            color="white"
            text-color="red"
            label="Invalid Network"
          />
        </div>
        <div
          v-else-if="
            isConnected == true &&
            currentAccounts().length > 0 &&
            getCurrentChain() === '0x1'
          "
        >
          <span class="menuWallet">Escrow: 0 |Balance: {{ balance }}</span>
        </div>
        <div v-else-if="isConnected == true && currentAccounts().length === 0">
          <q-btn
            @click="getSigner"
            color="white"
            text-color="blue"
            label="Connect Wallet"
          />
        </div>
      </q-toolbar>
      <div class="text-center">
        <div class="q-my-md">
          <span class="todaySign bg-blue-grey-10 q-pa-sm">
            Today's Games: (<span class="text-red">{{ selectedDate }}</span
            >)
          </span>
        </div>

        <q-carousel
          v-model="selectedDate"
          swipeable
          animated
          infinite
          control-color="red"
          arrows
          height="150px"
        >
          >
          <q-carousel-slide
            v-for="date in datesArray"
            :key="date"
            :name="date"
            class="text-center"
          >
            <q-scroll-area class="fit" style="height: 100px; max-width: auto">
              <div class="row no-wrap bg-grey-1 gameRow">
                <template v-if="gamesArray.length > 0">
                  <div v-for="game in gamesArray" :key="game.id">
                    <RouterLink
                      style="text-decoration: none"
                      :to="`/games/${game.id}`"
                    >
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
                          <span v-if="game.period > 0"
                            >: {{ game.home_team_score }}</span
                          >
                        </div>
                      </div>
                    </RouterLink>
                  </div>
                </template>
                <template v-else>
                  <div class="text-blue-grey-10 text-center q-mx-auto q-py-lg">
                    No games scheduled today
                  </div>
                </template>
              </div>
            </q-scroll-area>
          </q-carousel-slide>
        </q-carousel>
      </div>
    </q-header>

    <q-drawer v-model="leftDrawerOpen" show-if-above bordered>
      <q-list>
        <q-item-label class="text-center" header> Menu </q-item-label>
        <q-input
          square
          outlined
          v-model="searchValue"
          label="Search Players"
          type="search"
        >
          <template v-slot:append>
            <q-icon
              name="search"
              class="cursor-pointer"
              @click="getSearchResults"
            >
              <q-popup-proxy cover :breakpoint="600">
                <div>
                  <div class="text-h6 text-center">Results</div>
                  <div v-for="player in searchArray" :key="player.id">
                    <q-card>
                      <q-card-section>
                        <q-item-label>{{ player.team.full_name }}</q-item-label>
                        <div>
                          {{ player.first_name }}{{ ' ' + player.last_name }}
                        </div>
                      </q-card-section>
                    </q-card>
                  </div>
                </div>
              </q-popup-proxy>
            </q-icon>
          </template>
        </q-input>

        <EssentialLink
          v-for="link in essentialLinks"
          :key="link.title"
          v-bind="link"
        />
      </q-list>
    </q-drawer>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<style lang="scss" scoped>
.menuWallet {
  color: $blue-grey-10;
  background-color: $grey-1;
  border: 2px red solid;
  border-radius: 5px;
  padding: 5px;
}

.gameCard {
  color: $grey-1;
  margin: 5px;
  background-color: $blue-grey-10;
  border: 2px red solid;
  border-radius: 5px;
  padding: 5px;
  width: 8em;
}

.gameRow {
  border: 2px $blue-grey-10 solid;
  border-radius: 5px;
  width: 92%;
  margin: auto;
  padding: 5px;
  height: 100px;
}

.todaySign {
  color: $yellow-14;
  border: 3px red solid;
  border-radius: 5px;
  font-weight: 1000;
}
</style>
