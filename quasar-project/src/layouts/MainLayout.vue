<script setup>
import { ref, watchEffect } from 'vue';
import { ethers } from 'ethers';
import EssentialLink from 'components/EssentialLink.vue';

const provider = new ethers.BrowserProvider(window.ethereum);
const isConnected = ref(false);
const balance = ref(BigInt(0));

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
//
watchEffect(async () => {
  if (datesArray.value.length === 0) {
    getDatesArray();
  }
  await fetch(
    `https://www.balldontlie.io/api/v1/games?start_date=${selectedDate.value}&end_date=${selectedDate.value}`
  ).then((responseData) =>
    responseData
      .json()
      .then((data) => (gamesArray.value = data.data), console.log(gamesArray))
  );

  if (window.ethereum != null) {
    isConnected.value = true;
    try {
      await provider.getBalance(currentAccounts()[0]).then((currentBalance) => {
        balance.value = currentBalance;
      });
    } catch (error) {
      console.log(error);
    }
  } else {
    isConnected.value = false;
    balance.value = BigInt(0);
  }
});

const essentialLinks = [
  {
    title: 'Docs',
    caption: 'quasar.dev',
    icon: 'school',
    link: 'https://quasar.dev',
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
                    <div class="gameCard">
                      <div>
                        {{
                          new Date(game.date).toLocaleTimeString([], {
                            hour: '2-digit',
                            minute: '2-digit',
                          })
                        }}
                      </div>
                      <div>
                        {{ game.visitor_team.abbreviation }}
                      </div>
                      <q-separator color="white" />
                      <div>
                        <span class="text-yellow-14">@</span>
                        {{ game.home_team.abbreviation }}
                      </div>
                    </div>
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
        <q-item-label header> Essential Links </q-item-label>
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
  color: $blue-8;
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
