<script setup>
import { ref, watchEffect, computed } from 'vue';
import { ethers } from 'ethers';
import EssentialLink from 'components/EssentialLink.vue';

const provider = new ethers.BrowserProvider(window.ethereum);
const user = ref('');
const chainId = ref();
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');

const isConnected = ref(false);
const balance = ref();
const escrow = ref();

const searchValue = ref('');
const searchArray = ref([]);
const searchDialog = ref(false);
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
  if (user.value.length > 0) {
    return user.value;
  } else {
    return 'Menu';
  }
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
    searchDialog.value = true;
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
    try {
      user.value = window.ethereum._state.accounts[0];
    } catch (error) {
      console.log(error);
    }
  }
  if (chainId.value === undefined && window.ethereum.chainId) {
    try {
      chainId.value = window.ethereum.chainId;
    } catch (error) {
      console.log(error);
    }
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
    if (user.value.length > 0 && balance.value === undefined) {
      try {
        const weiBalance = await provider.getBalance(user.value);
        balance.value = ethers.formatEther(weiBalance).substring(0, 6);
      } catch (error) {
        console.log(error);
      }
    }
  }

  if (escrow.value === undefined && user.value.length > 0) {
    try {
      const betContract = new ethers.Contract(
        process.env.CONTRACT_ADDRESS,
        contract.abi,
        await provider.getSigner()
      );
      const value = await betContract.returnEscrow();
      escrow.value = ethers.formatEther(value).substring(0, 6);
    } catch (error) {
      console.log(error);
    }
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
    title: 'Discord',
    caption: 'forum.quasar.dev',
    icon: 'rss_feed',
    link: 'https://forum.quasar.dev',
  },
  {
    title: 'Twitter',
    caption: '@EBSLeague',
    icon: 'public',
    link: 'https://twitter.com/EBSLeague',
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

        <q-toolbar-title
          ><RouterLink style="text-decoration: none; color: white" to="/"
            >EBSL</RouterLink
          >
        </q-toolbar-title>
        <template
          v-if="isConnected === true && user.length > 0 && chainId === '0x5'"
        >
          <div>
            <span class="menuWallet">
              Escrow:
              <span class="text-grey-1">{{ returnEscrow + ' ETH' }}</span>
              | Balance:
              <span class="text-grey-1">{{ returnETH + ' ETH' }}</span>
            </span>
          </div>
        </template>

        <template
          v-else-if="
            isConnected === true && chainId === '0x5' && user.length === 0
          "
        >
          <div>
            <q-btn
              @click="getSigner"
              text-color="grey-1"
              label="Connect Ethereum"
            />
          </div>
        </template>

        <template
          v-else-if="
            isConnected === true && chainId !== '0x5' && user.length > 0
          "
        >
          <div>
            <q-btn
              disabled
              color="white"
              text-color="red"
              label="Invalid Network"
            />
          </div>
        </template>

        <template v-else-if="isConnected === false && user.length === 0">
          <div>
            <q-btn
              disabled
              color="white"
              text-color="black"
              label="MetaMask Undetected"
            />
          </div>
        </template>
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
        <q-item-label class="text-center menuAddress" header>
          <span class="text-red">@</span>{{ currentAccount }}
        </q-item-label>
        <q-input
          square
          outlined
          v-model="searchValue"
          label="Search Players"
          type="search"
          @keyup.enter="getSearchResults"
        >
          <template v-slot:append>
            <q-icon
              name="search"
              class="cursor-pointer"
              @click="getSearchResults"
            >
              <q-dialog v-model="searchDialog">
                <q-card style="width: 700px; max-width: 80vw; height: 50vh">
                  <div class="text-h2 text-center">Search Results</div>
                  <q-card-section
                    class="scroll"
                    v-for="player in searchArray"
                    :key="player.id"
                  >
                    <RouterLink
                      style="text-decoration: none"
                      :to="`/players/${player.id}`"
                      replace
                    >
                      <q-card class="text-white text-center bg-blue-grey-10">
                        <q-card-section>
                          <q-item-label
                            >{{ player.first_name
                            }}{{ ' ' + player.last_name + ' ' }}
                            <span class="text-yellow-14">{{
                              player.position
                            }}</span>
                          </q-item-label>
                          <div>
                            {{ player.team.full_name }}
                          </div>
                          <div v-if="player.height_feet != null">
                            {{
                              player.height_feet + "'" + player.height_inches
                            }}
                          </div>
                        </q-card-section>
                      </q-card>
                    </RouterLink>
                  </q-card-section>
                </q-card>
              </q-dialog>
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

.menuAddress {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
