<script setup>
import { ref, watchEffect, computed } from 'vue';
import { ethers } from 'ethers';
import EssentialLink from 'components/EssentialLink.vue';

const provider = new ethers.BrowserProvider(window.ethereum);
const user = ref();
const chainId = ref();
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');
const betContract = new ethers.Contract(
  process.env.CONTRACT_ADDRESS,
  contract.abi,
  provider
);

const isConnected = ref(false);
const balance = ref(BigInt(0));
const escrow = ref();

const searchValue = ref('');
const searchArray = ref([]);
const datesArray = ref([]);
const today = new Date(Date.now());
const year = today.getFullYear();
const month = (today.getMonth() + 1).toString().padStart(2, '0');
const day = today.getDate().toString().padStart(2, '0');
const todayFormatted = ref(`${year}-${month}-${day}`);
const selectedDate = ref(todayFormatted.value);
const gamesArray = ref([]);

function getDatesArray() {
  const dates = [];
  dates.push(todayFormatted.value);
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
const currentAccount = computed(() => {
  return user.value;
});

const getCurrentChain = computed(() => {
  return chainId.value;
});

const returnETH = computed(() => {
  return balance.value;
});
const returnEscrow = computed(() => {
  return escrow.value;
});

const returnSelectedDate = computed(() => {
  return selectedDate.value;
});
const getSigner = async () => {
  if (window.ethereum == null) {
    console.log('MetaMask not installed; using read-only defaults');
    ethers.getDefaultProvider();
  } else {
    await provider.getSigner();
  }
};

const getSearchResults = async () => {
  if (searchValue.value.length > 0) {
    await fetch(
      `https://www.balldontlie.io/api/v1/players?search=${searchValue.value}`
    ).then((responseData) =>
      responseData.json().then((data) => (searchArray.value = data.data))
    );
  }
};
watchEffect(async () => {
  if (
    window.ethereum._state.accounts &&
    window.ethereum._state.accounts.length > 0
  ) {
    user.value = window.ethereum._state.accounts[0];
  }
  if (chainId.value == undefined && window.ethereum.chainId) {
    chainId.value = window.ethereum.chainId;
  }
  if (datesArray.value.length === 0) {
    getDatesArray();
  }
  await fetch(
    `https://www.balldontlie.io/api/v1/games?start_date=${selectedDate.value}&end_date=${selectedDate.value}`
  ).then((responseData) =>
    responseData.json().then((data) => (gamesArray.value = data.data))
  );

  if (window.ethereum) {
    isConnected.value = true;
    if (typeof user.value === 'string') {
      try {
        const weiBalance = await provider.getBalance(currentAccount.value);
        balance.value = ethers.formatEther(weiBalance).substring(0, 6);
      } catch (error) {
        console.log(error);
      }
    }
  } else {
    isConnected.value = false;
    balance.value = BigInt(0);
  }

  if (escrow.value == undefined && user.value != undefined) {
    escrow.value = await betContract.returnEscrow();
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
    title: 'Games',
    caption: 'Recent & Upcoming Games',
    icon: 'scoreboard',
    link: '/#/games',
  },
  {
    title: 'Teams',
    caption: 'NBA Teams',
    icon: 'sports_basketball',
    link: '/#/teams',
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
            getCurrentChain !== '0x5' &&
            currentAccount.length > 0
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
            currentAccount.length > 0 &&
            getCurrentChain === '0x5'
          "
        >
          <span class="menuWallet">
            Escrow: <span class="text-grey-1">{{ returnEscrow + ' ETH' }}</span>
            | Balance:
            <span class="text-grey-1">{{ returnETH + ' ETH' }}</span>
          </span>
        </div>
        <div v-else-if="isConnected == true && currentAccount.length === 0">
          <q-btn
            @click="getSigner"
            color="purple"
            text-color="grey-1"
            label="Connect zkEVM"
          />
        </div>
      </q-toolbar>
      <div class="text-center">
        <div class="q-my-md">
          <span
            v-if="selectedDate === todayFormatted"
            class="todaySign bg-blue-grey-10 q-pa-sm"
          >
            Today's Games: (<span class="text-red">{{
              returnSelectedDate
            }}</span
            >)
          </span>
          <span v-else class="todaySign bg-blue-grey-10 q-pa-sm">
            (<span class="text-red">{{ returnSelectedDate }}</span
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
            v-for="(date, index) in datesArray"
            :key="index"
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
        <q-item-label class="text-center" header> {{ user }} </q-item-label>
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
                    <RouterLink
                      style="text-decoration: none"
                      :to="`/players/${player.id}`"
                      replace
                    >
                      <q-card class="text-red bg-blue-grey-10">
                        <q-card-section>
                          <q-item-label>{{
                            player.team.full_name
                          }}</q-item-label>
                          <div>
                            {{ player.first_name
                            }}{{ ' ' + player.last_name }}|{{
                              player.height_feet +
                              "'" +
                              player.height_inches +
                              ' ' +
                              player.position
                            }}
                          </div>
                        </q-card-section>
                      </q-card>
                    </RouterLink>
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
  color: $lime-12;
  background-color: black;
  border: 3px $grey-1 solid;
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
