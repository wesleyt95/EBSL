<script setup>
import { ref, watchEffect, computed } from 'vue';
import { useWalletStore } from 'stores/web3wallet';
import { ethers } from 'ethers';
import { TEAMS } from '../pages/teams/nba-teams.js';
import EssentialLink from 'components/EssentialLink.vue';
const store = useWalletStore();
const provider = new ethers.BrowserProvider(window.ethereum);
const user = store.user;
const userRef = ref(user);
const chainId = store.chainID;
const chainIdRef = ref(chainId);
const isConnected = store.isConnected;
const isConnectedRef = ref(store.isConnected);
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');

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
  if (store.user != undefined) {
    return store.user;
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

const height = (height) => {
  if (height > 0) {
    return Math.floor(height / 12) + "'" + (height % 12);
  } else return null;
};
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
      'https://api.sportsdata.io/v3/nba/scores/json/PlayersActiveBasic?key=186578d61751474db1ac789b9613a9b1'
    ).then((responseData) =>
      responseData.json().then(
        (data) =>
          (searchArray.value = data.filter((obj) => {
            const combinedValues =
              obj.FirstName.toLowerCase().replace(/[-. ]/g, '') +
              obj.LastName.toLowerCase().replace(/[-. ]/g, '');
            return combinedValues.includes(
              searchValue.value.toLowerCase().replace(/[-. ]/g, '')
            );
          }))
      )
    );
  }
};

watchEffect(async () => {
  if (user == undefined && window.ethereum._state.accounts) {
    userRef.value = window.ethereum._state.accounts[0];
    store.user = userRef.value;
  }
  if (chainId == undefined && window.ethereum.chainId) {
    chainIdRef.value = window.ethereum.chainId;
    store.chainID = chainIdRef.value;
  }
  if (isConnected !== true && window.ethereum.isConnected()) {
    isConnectedRef.value = true;
    store.isConnected = isConnectedRef.value;
  }
  window.ethereum.on('accountsChanged', (accounts) => {
    userRef.value = accounts[0];
    store.user = userRef.value;
  });
  window.ethereum.on('chainChanged', (chainId) => {
    chainIdRef.value = chainId;
    store.chainID = chainIdRef.value;
    window.location.reload();
  });

  window.ethereum.on(
    'connect',
    () => (
      (isConnectedRef.value = true),
      (store.isConnected = isConnectedRef.value = true)
    )
  );
  window.ethereum.on(
    'disconnect',
    () => (
      (isConnectedRef.value = false), (store.isConnected = isConnectedRef.value)
    )
  );
  if (datesArray.value.length === 0) {
    getDatesArray();
  }
  await fetch(
    `https://api.sportsdata.io/v3/nba/scores/json/GamesByDate/${selectedDate.value}?key=186578d61751474db1ac789b9613a9b1`
  ).then((responseData) =>
    responseData.json().then((data) => (gamesArray.value = data))
  );

  if (isConnected === true) {
    if (user != undefined && balance.value === undefined) {
      const weiBalance = await provider.getBalance(user);
      balance.value = ethers.formatEther(weiBalance).substring(0, 6);
    }
  }

  if (escrow.value == undefined && user != undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const value = await betContract.returnEscrow();
    escrow.value = ethers.formatEther(value).substring(0, 6);
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
    caption: 'Community',
    icon: 'rss_feed',
    link: 'https://discord.gg/jEw3eFYUpC',
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
          ><RouterLink style="text-decoration: none; color: white" to="/">
            <q-avatar>
              <q-img
                src="https://content.sportslogos.net/logos/6/982/full/8147__national_basketball_association-primary-2018.png"
                fit="contain"
              /> </q-avatar
            >EBSL</RouterLink
          >
        </q-toolbar-title>
        <template
          v-if="isConnected === true && user !== undefined && chainId === '0x5'"
        >
          <div :key="user">
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
            isConnected === true && chainId === '0x5' && user === undefined
          "
        >
          <div :key="user">
            <q-btn
              @click="getSigner"
              text-color="grey-1"
              label="Connect Ethereum"
            />
          </div>
        </template>

        <template
          v-else-if="
            isConnected === true && chainId !== '0x5' && user !== undefined
          "
        >
          <div :key="chainId">
            <q-btn
              disabled
              color="white"
              text-color="red"
              label="Invalid Network"
            />
          </div>
        </template>
        <template v-else-if="isConnected === false">
          <div :key="isConnected">
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
                  <div v-for="game in gamesArray" :key="game.GameID">
                    <RouterLink
                      style="text-decoration: none"
                      :to="`/games/${game.GameID}`"
                    >
                      <div class="gameCard">
                        <div>
                          {{
                            game.Quarter === 0
                              ? new Date(game.DateTimeUTC).toLocaleTimeString(
                                  [],
                                  {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                  }
                                )
                              : game.Status
                          }}
                        </div>
                        <div>
                          {{ game.AwayTeam }}
                          <span v-if="game.AwayTeamScore > 0"
                            >: {{ game.AwayTeamScore }}</span
                          >
                        </div>
                        <q-separator color="white" />
                        <div>
                          <span class="text-yellow-14">@</span>
                          {{ game.HomeTeam }}
                          <span v-if="game.HomeTeamScore > 0"
                            >: {{ game.HomeTeamScore }}</span
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
        <q-item-label :key="user" class="text-center menuAddress" header>
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
                  <q-card-section
                    style="
                      position: sticky;
                      top: 0px;
                      z-index: 1;
                      background-color: white;
                    "
                    ><q-input
                      square
                      outlined
                      v-model="searchValue"
                      label="Search Players"
                      type="search"
                      class="dialogSearchInput"
                      @keyup.enter="getSearchResults"
                  /></q-card-section>

                  <q-card-section
                    class="scroll"
                    v-for="(player, index) in searchArray"
                    :key="index"
                  >
                    <RouterLink
                      style="text-decoration: none"
                      :to="`/players/${player.PlayerID}`"
                      replace
                    >
                      <q-card
                        class="text-blue-grey-10 text-center bg-grey-1 searchCard"
                      >
                        <q-img
                          :src="
                            TEAMS.find((t) => t.TeamID === player.TeamID)
                              .WikipediaLogoUrl
                          "
                          style="
                            max-height: 70px;
                            max-width: 90px;
                            float: left;
                            margin-top: auto;
                          "
                          fit="contain"
                        />
                        <q-card-section>
                          <q-item-label
                            >{{ player.FirstName
                            }}{{ ' ' + player.LastName + ' ' }}
                            <span
                              class="text-yellow-14 bg-blue-grey-10 text-bold q-ma-sm q-pa-xs"
                            >
                              {{ player.Position }}
                            </span>
                          </q-item-label>
                          <div :key="player.Height">
                            {{ player.Weight }} lbs |
                            {{ height(player.Height) }}
                          </div>
                          <div>
                            {{ player.BirthCity }}, {{ player.BirthCountry }}
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
.dialogSearchInput {
  border: 2px $blue-grey-10 solid;
}
.searchCard {
  border: 3px $grey-4 solid;
}
</style>
