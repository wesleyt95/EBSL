<script setup>
import { ref, watchEffect } from 'vue';
import { ethers } from 'ethers';
import EssentialLink from 'components/EssentialLink.vue';

const provider = new ethers.BrowserProvider(window.ethereum);

const gamesArray = ref([]);
const isConnected = ref(false);
const balance = ref(BigInt(0));

function formatDate() {
  const d = new Date(Date.now());
  let month = '' + (d.getMonth() + 1);
  let day = '' + d.getDate();
  const year = d.getFullYear();

  if (month.length < 2) {
    month = '0' + month;
  }
  if (day.length < 2) {
    day = '0' + day;
  }

  return [year, month, day].join('-');
}

const getGames = async () => {
  await fetch(
    `https://www.balldontlie.io/api/v1/games?start_date=${formatDate()}&end_date=${formatDate()}`
  ).then((responseData) =>
    responseData
      .json()
      .then((data) => (gamesArray.value = data.data), console.log(gamesArray))
  );
};

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

watchEffect(async () => {
  if (gamesArray.value.length === 0) {
    await getGames();
  }
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
    <q-header elevated>
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
          <span class="todaySign bg-grey-1 text-black q-pa-sm">
            Today's Games: (<span class="text-red">{{
              new Date(Date.now()).toLocaleDateString()
            }}</span
            >)
          </span>
        </div>
        <template v-if="gamesArray.length > 0">
          <div class="row bg-grey-1 q-mt-sm q-mb-md gameRow">
            <div class="gameCard" v-for="game in gamesArray" :key="game.id">
              <div class="q-my-auto">
                <div>
                  {{
                    new Date(game.date).toLocaleTimeString([], {
                      hour: '2-digit',
                      minute: '2-digit',
                    })
                  }}
                </div>
                <div>
                  <span class="text-yellow-14">@</span>
                  {{ game.home_team.abbreviation }}
                </div>

                <q-separator color="white" />
                <div>
                  {{ game.visitor_team.abbreviation }}
                </div>
              </div>
            </div>
          </div>
        </template>
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
  border-top: 2px $blue-grey-10 solid;
  border-bottom: 2px $blue-grey-10 solid;
}

.todaySign {
  color: $blue-grey-10;
  border: 3px $yellow-14 solid;
  border-radius: 5px;
  font-weight: 1000;
}
</style>
