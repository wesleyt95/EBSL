<script setup>
import { ref, watchEffect, computed } from 'vue';
import { useRoute } from 'vue-router';
import { ethers } from 'ethers';
import { TEAMS } from '../teams/nba-teams.js';
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');

const router = useRoute();
const provider = new ethers.BrowserProvider(window.ethereum);

const betContractNoSigner = new ethers.Contract(
  process.env.CONTRACT_ADDRESS,
  contract.abi,
  provider
);
const paramData = ethers.Interface.from(contract.abi).encodeFunctionData(
  'getWeb3FunctionArgsHex',
  [process.env.CONTRACT_ADDRESS, Number(router.params.id)]
);

const homeDialog = ref(false);
const awayDialog = ref(false);

const gameArray = ref([]);
const gameTotal = ref();
const homeTotalBet = ref();
const awayTotalBet = ref();
const homeOdds = ref();
const awayOdds = ref();
const statsArrayAway = ref([]);
const statsArrayHome = ref([]);
const homeBetType = ref();
const homeMoneyline = ref();
const homeSpread = ref();
const homeTotal = ref();
const awayBetType = ref();
const awayMoneyline = ref();
const awaySpread = ref();
const awayTotal = ref();
const overUnderHome = ref();
const overUnderAway = ref();
const awayCurrentMoneyline = ref();
const homeCurrentMoneyline = ref();
const awayCurrentPointSpread = ref();
const homeCurrentPointSpread = ref();
const awayCurrentPointTotal = ref();
const homeCurrentPointTotal = ref();
const awayCurrentMoneylineUser = ref();
const homeCurrentMoneylineUser = ref();
const awayCurrentPointSpreadUser = ref();
const homeCurrentPointSpreadUser = ref();
const awayCurrentPointTotalUser = ref();
const homeCurrentPointTotalUser = ref();

const returnGameTotal = computed(() => {
  return gameTotal.value;
});
const returnHomeTotal = computed(() => {
  return homeTotalBet.value;
});
const returnAwayTotal = computed(() => {
  return awayTotalBet.value;
});
const returnHomeOdds = computed(() => {
  if (homeOdds.value == undefined) {
    return 0;
  } else return homeOdds.value;
});
const returnAwayOdds = computed(() => {
  if (awayOdds.value == undefined) {
    return 0;
  } else return awayOdds.value;
});
const returnAwayMoneylineUser = computed(() => {
  if (awayCurrentMoneylineUser.value == undefined) {
    return null;
  } else {
    return `(${ethers
      .formatEther(JSON.parse(awayCurrentMoneylineUser.value)[1])
      .substring(0, 5)})`;
  }
});
const returnHomeMoneylineUser = computed(() => {
  if (homeCurrentMoneylineUser.value == undefined) {
    return null;
  } else {
    return `(${ethers
      .formatEther(JSON.parse(homeCurrentMoneylineUser.value)[1])
      .substring(0, 5)})`;
  }
});

const returnAwayMoneyline = computed(() => {
  if (awayCurrentMoneyline.value == undefined) {
    return null;
  } else {
    return (
      ethers
        .formatEther(JSON.parse(awayCurrentMoneyline.value))
        .substring(0, 5) + ' ETH'
    );
  }
});
const returnHomeMoneyline = computed(() => {
  if (homeCurrentMoneyline.value == undefined) {
    return null;
  } else {
    return (
      ethers
        .formatEther(JSON.parse(homeCurrentMoneyline.value))
        .substring(0, 5) + ' ETH'
    );
  }
});

const returnAwayPointSpreadUser = computed(() => {
  if (awayCurrentPointSpreadUser.value == undefined) {
    return null;
  } else {
    return `(${ethers
      .formatEther(JSON.parse(awayCurrentPointSpreadUser.value)[1])
      .substring(0, 5)})`;
  }
});
const returnHomePointSpreadUser = computed(() => {
  if (homeCurrentPointSpreadUser.value == undefined) {
    return null;
  } else {
    return `(${ethers
      .formatEther(JSON.parse(homeCurrentPointSpreadUser.value)[1])
      .substring(0, 5)})`;
  }
});

const returnAwayPointSpread = computed(() => {
  if (awayCurrentPointSpread.value == undefined) {
    return null;
  } else {
    return (
      ethers
        .formatEther(JSON.parse(awayCurrentPointSpread.value))
        .substring(0, 5) + ' ETH'
    );
  }
});
const returnHomePointSpread = computed(() => {
  if (homeCurrentPointSpread.value == undefined) {
    return null;
  } else {
    return (
      ethers
        .formatEther(JSON.parse(homeCurrentPointSpread.value))
        .substring(0, 5) + ' ETH'
    );
  }
});

const returnAwayPointTotalUser = computed(() => {
  if (awayCurrentPointTotalUser.value == undefined) {
    return null;
  } else {
    return `(${ethers
      .formatEther(JSON.parse(awayCurrentPointTotalUser.value)[1])
      .substring(0, 5)})`;
  }
});
const returnHomePointTotalUser = computed(() => {
  if (homeCurrentPointTotalUser.value == undefined) {
    return null;
  } else {
    return `(${ethers
      .formatEther(JSON.parse(homeCurrentPointTotalUser.value)[1])
      .substring(0, 5)})`;
  }
});

const returnAwayPointTotal = computed(() => {
  if (awayCurrentPointTotal.value == undefined) {
    return null;
  } else {
    return (
      ethers
        .formatEther(JSON.parse(awayCurrentPointTotal.value))
        .substring(0, 5) + ' ETH'
    );
  }
});
const returnHomePointTotal = computed(() => {
  if (homeCurrentPointTotal.value == undefined) {
    return null;
  } else {
    return (
      ethers
        .formatEther(JSON.parse(homeCurrentPointTotal.value))
        .substring(0, 5) + ' ETH'
    );
  }
});

const statColumns = [
  {
    name: 'Name',
    label: 'Name',
    field: 'Name',
    align: 'left',
  },
  {
    name: 'Minutes',
    label: 'Minutes',
    field: 'Minutes',
  },
  {
    name: 'Points',
    label: 'Points',
    field: 'Points',
  },
  { name: 'Rebounds', label: 'Rebounds', field: 'Rebounds' },
  { name: 'Assists', label: 'Assists', field: 'Assists' },
  { name: 'Steals', label: 'Steals', field: 'Steals' },
  { name: 'BlockedShots', label: 'Blocks', field: 'BlockedShots' },
];

watchEffect(async () => {
  await fetch(
    `https://api.sportsdata.io/v3/nba/stats/json/BoxScore/${router.params.id}?key=${process.env.SPORTSDATA_API_KEY}`
  ).then((responseData) =>
    responseData.json().then(async (data) => {
      gameArray.value = data.Game;
      statsArrayAway.value = await data.PlayerGames?.filter(
        (row) => row.TeamID === gameArray.value.AwayTeamID
      );
      statsArrayHome.value = await data.PlayerGames?.filter(
        (row) => row.TeamID === gameArray.value.HomeTeamID
      );
    })
  );
  if (window.ethereum.chainId === '0x5') {
    if (gameTotal.value == undefined) {
      gameTotal.value = await betContractNoSigner.totalBetOnGame(
        Number(router.params.id)
      );
    }
    if (homeTotalBet.value == undefined) {
      homeTotalBet.value = await betContractNoSigner.totalBetOnTeam(
        Number(router.params.id),
        gameArray.value.HomeTeamID
      );
    }
    if (awayTotalBet.value == undefined) {
      awayTotalBet.value = await betContractNoSigner.totalBetOnTeam(
        Number(router.params.id),
        gameArray.value.AwayTeamID
      );
    }
    if (homeOdds.value == undefined) {
      homeOdds.value = await betContractNoSigner.returnOdds(
        Number(router.params.id),
        gameArray.value.HomeTeamID
      );
    }
    if (awayOdds.value == undefined) {
      awayOdds.value = await betContractNoSigner.returnOdds(
        Number(router.params.id),
        gameArray.value.AwayTeamID
      );
    }
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    if (homeCurrentMoneylineUser.value == undefined) {
      const receipt = await betContract.returnMoneyLineBetReceipt(
        Number(router.params.id),
        gameArray.value.HomeTeamID
      );
      homeCurrentMoneylineUser.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (awayCurrentMoneylineUser.value == undefined) {
      const receipt = await betContract.returnMoneyLineBetReceipt(
        Number(router.params.id),
        gameArray.value.AwayTeamID
      );
      awayCurrentMoneylineUser.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (homeCurrentMoneyline.value == undefined) {
      const receipt = await betContract.returnMoneyLineBetTotal(
        Number(router.params.id),
        gameArray.value.HomeTeamID
      );
      homeCurrentMoneyline.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (awayCurrentMoneyline.value == undefined) {
      const receipt = await betContract.returnMoneyLineBetTotal(
        Number(router.params.id),
        gameArray.value.AwayTeamID
      );
      awayCurrentMoneyline.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }
    if (homeCurrentPointSpreadUser.value == undefined) {
      const receipt = await betContract.returnPointSpreadBetReceipt(
        Number(router.params.id)
      );
      homeCurrentPointSpreadUser.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (awayCurrentPointSpreadUser.value == undefined) {
      const receipt = await betContract.returnPointSpreadBetReceipt(
        Number(router.params.id)
      );
      awayCurrentPointSpreadUser.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (homeCurrentPointSpread.value == undefined) {
      const receipt = await betContract.returnPointSpreadBetTotal(
        Number(router.params.id),
        gameArray.value.HomeTeamID
      );
      homeCurrentPointSpread.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (awayCurrentPointSpread.value == undefined) {
      const receipt = await betContract.returnPointSpreadBetTotal(
        Number(router.params.id),
        gameArray.value.AwayTeamID
      );
      awayCurrentPointSpread.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }
    if (homeCurrentPointTotalUser.value == undefined) {
      const receipt = await betContract.returnPointTotalBetReceipt(
        Number(router.params.id)
      );
      homeCurrentPointTotalUser.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (awayCurrentPointTotalUser.value == undefined) {
      const receipt = await betContract.returnPointTotalBetReceipt(
        Number(router.params.id)
      );
      awayCurrentPointTotalUser.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (homeCurrentPointTotal.value == undefined) {
      const receipt = await betContract.returnPointTotalBetTotal(
        Number(router.params.id)
      );
      homeCurrentPointTotal.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }

    if (awayCurrentPointTotal.value == undefined) {
      const receipt = await betContract.returnPointTotalBetTotal(
        Number(router.params.id)
      );
      awayCurrentPointTotal.value = JSON.stringify(receipt, (_, v) =>
        typeof v === 'bigint' ? v.toString() : v
      );
    }
  }
});

const sendBetAway = async () => {
  const signer = await provider.getSigner();
  const betContract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    contract.abi,
    signer
  );
  if (awayBetType.value === 'moneyline') {
    const overrides = {
      value: awayMoneyline.value,
    };
    try {
      const tx = await betContract.moneyLineBet(
        Number(router.params.id),
        gameArray.value.AwayTeamID,
        gameArray.value.HomeTeamID,
        gameArray.value.AwayTeamID,
        Date.parse(gameArray.value.DateTimeUTC) / 1000,
        paramData,
        overrides
      );

      await tx.wait();
      window.location.reload();
      console.log(tx);
    } catch (err) {
      console.log(err);
    }
  } else if (awayBetType.value === 'spread') {
    const overrides = {
      value: awaySpread.value,
    };
    try {
      const tx = await betContract.pointSpreadBet(
        Number(router.params.id),
        gameArray.value.AwayTeamID,
        gameArray.value.HomeTeamID,
        gameArray.value.AwayTeamID,
        gameArray.value.PointSpread * -10,
        Date.parse(gameArray.value.DateTimeUTC) / 1000,
        paramData,
        overrides
      );
      await tx.wait();
      window.location.reload();
      console.log(tx);
    } catch (err) {
      console.log(err);
    }
  } else if (awayBetType.value === 'total') {
    const overrides = {
      value: awayTotal.value,
    };
    try {
      const tx = await betContract.pointTotalBet(
        Number(router.params.id),
        Number(overUnderAway.value),
        gameArray.value.HomeTeamID,
        gameArray.value.AwayTeamID,
        gameArray.value.OverUnder * 10,
        Date.parse(gameArray.value.DateTimeUTC) / 1000,
        paramData,
        overrides
      );
      await tx.wait();
      window.location.reload();
      console.log(tx);
    } catch (err) {
      console.log(err);
    }
  }
};

const sendBetHome = async () => {
  const signer = await provider.getSigner();
  const betContract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    contract.abi,
    signer
  );
  if (homeBetType.value === 'moneyline') {
    const overrides = {
      value: homeMoneyline.value,
    };
    try {
      const tx = await betContract.moneyLineBet(
        Number(router.params.id),
        gameArray.value.HomeTeamID,
        gameArray.value.HomeTeamID,
        gameArray.value.AwayTeamID,
        Date.parse(gameArray.value.DateTimeUTC) / 1000,
        paramData,
        overrides
      );
      await tx.wait();
      window.location.reload();
      console.log(tx);
    } catch (err) {
      console.log(err);
    }
  } else if (homeBetType.value === 'spread') {
    const overrides = {
      value: homeSpread.value,
    };
    try {
      const tx = await betContract.pointSpreadBet(
        Number(router.params.id),
        gameArray.value.HomeTeamID,
        gameArray.value.HomeTeamID,
        gameArray.value.AwayTeamID,
        gameArray.value.PointSpread * 10,
        Date.parse(gameArray.value.DateTimeUTC) / 1000,
        paramData,
        overrides
      );
      await tx.wait();
      window.location.reload();
      console.log(tx);
    } catch (err) {
      console.log(err);
    }
  } else if (homeBetType.value === 'total') {
    const overrides = {
      value: homeTotal.value,
    };
    try {
      const tx = await betContract.pointTotalBet(
        Number(router.params.id),
        Number(overUnderHome.value),
        gameArray.value.HomeTeamID,
        gameArray.value.AwayTeamID,
        gameArray.value.OverUnder * 10,
        Date.parse(gameArray.value.DateTimeUTC) / 1000,
        paramData,
        overrides
      );
      await tx.wait();
      window.location.reload();
      console.log(tx);
    } catch (err) {
      console.log(err);
    }
  }
};
</script>
<template>
  <q-page>
    <div>
      <q-card v-if="gameArray.DateTimeUTC" class="mainCard">
        <div class="text-center">
          <span class="dateSign">
            {{ new Date(gameArray.DateTimeUTC).toLocaleDateString() }}
          </span>
        </div>
        <q-card-section>
          <div class="row items-center justify-evenly text-h3 text-center">
            <div style="width: 40%">
              <div class="hover">
                <q-img
                  fit="contain"
                  style="max-height: 2.5em; max-width: 2.5em"
                  :src="
                    TEAMS.find((row) => row.TeamID === gameArray.AwayTeamID)
                      .WikipediaLogoUrl
                  "
                  @click="
                    $router.push({ path: `/teams/${gameArray.AwayTeamID}` })
                  "
                  :key="gameArray.AwayTeamID"
                />
                {{ `${returnAwayOdds}%` }}
              </div>
            </div>
            <div style="width: 10%">@</div>
            <div style="width: 40%">
              <div class="hover">
                {{ `${returnHomeOdds}%` }}
                <q-img
                  fit="contain"
                  style="max-height: 2.5em; max-width: 2.5em"
                  :src="
                    TEAMS.find((row) => row.TeamID === gameArray.HomeTeamID)
                      .WikipediaLogoUrl
                  "
                  @click="
                    $router.push({ path: `/teams/${gameArray.HomeTeamID}` })
                  "
                  :key="gameArray.HomeTeamID"
                />
              </div>
            </div>
          </div>
        </q-card-section>

        <q-card-section>
          <div
            style="width: 80%"
            class="flex full-width row items-center justify-evenly text-center q-mx-auto"
          >
            <div>
              <q-card class="betCard">
                <q-card-section>
                  Total Bet:
                  <span class="text-red">{{ returnAwayTotal + ' ETH' }}</span>
                </q-card-section>
                <q-card-section>
                  Money Line:
                  <span class="text-red">{{ returnAwayMoneyline }}</span>
                </q-card-section>
                <q-card-section>
                  [
                  {{
                    (gameArray.PointSpread < 0 ? '+' : null) +
                    gameArray.PointSpread * -1
                  }}
                  ] Point Spread:
                  <span class="text-red">{{ returnAwayPointSpread }}</span>
                </q-card-section>
                <q-card-section>
                  [ {{ gameArray.OverUnder }} ] Point Total:
                  <span class="text-red">{{ returnAwayPointTotal }}</span>
                </q-card-section>
                <q-btn
                  @click="awayDialog = true"
                  :disabled="gameArray.Status !== 'Scheduled'"
                  >Place Bet</q-btn
                >
              </q-card>
              <q-dialog
                v-model="awayDialog"
                persistent
                maximized
                transition-show="slide-up"
                transition-hide="slide-down"
              >
                <q-card class="bg-grey-1 text-blue-grey-10">
                  <q-toolbar>
                    <q-avatar>
                      <img
                        fit="contain"
                        src="https://cdn.discordapp.com/attachments/946638392958009384/1142081959917539348/01.png"
                      />
                    </q-avatar>
                    <q-toolbar-title>
                      <span class="text-weight-bold">EBSL</span>
                    </q-toolbar-title>
                    <q-btn flat round dense icon="close" v-close-popup />
                  </q-toolbar>
                  <q-card-section>
                    <h3 class="text-center q-mb-xs">
                      <q-img
                        fit="contain"
                        style="max-height: 2em; max-width: 2em"
                        :src="
                          TEAMS.find(
                            (row) => row.TeamID === gameArray.AwayTeamID
                          ).WikipediaLogoUrl
                        "
                        :key="gameArray.AwayTeamID"
                      />
                    </h3>
                    <div class="text-h2 text-center q-mt-xs">
                      {{
                        TEAMS.find((row) => row.Key === gameArray.AwayTeam).City
                      }}
                      {{
                        TEAMS.find((row) => row.Key === gameArray.AwayTeam).Name
                      }}
                    </div>
                  </q-card-section>
                  <div class="betTypes" @click="awayBetType = 'moneyline'">
                    <q-card-section>
                      <div>
                        <span class="text-h6"
                          >Money Line{{ returnAwayMoneylineUser }}</span
                        >
                        <div
                          v-if="awayCurrentMoneyline !== undefined"
                          class="betValue"
                        >
                          {{ returnAwayMoneyline }}
                        </div>
                      </div>
                    </q-card-section>

                    <q-card-section class="q-pt-none">
                      Place your wager on
                      {{ gameArray.AwayTeam }} winning the game.
                    </q-card-section>
                    <div v-if="awayBetType === 'moneyline'">
                      <q-input
                        style="max-width: 300px; margin: 0 auto 1em auto"
                        square
                        outlined
                        label="ETH"
                        type="number"
                        v-model="awayMoneyline"
                      ></q-input>
                    </div>
                  </div>

                  <div class="betTypes" @click="awayBetType = 'spread'">
                    <q-card-section>
                      <div>
                        <span class="text-h6">
                          [{{
                            (gameArray.PointSpread < 0 ? '+' : null) +
                            gameArray.PointSpread * -1
                          }}] Point Spread {{ returnAwayPointSpreadUser }}
                        </span>
                        <div
                          v-if="awayCurrentPointSpread !== undefined"
                          class="betValue"
                        >
                          {{ returnAwayPointSpread }}
                        </div>
                      </div>
                    </q-card-section>

                    <q-card-section class="q-pt-none">
                      The point spread is a calculated points difference
                      determined by oddsmakers between two teams lining up.
                    </q-card-section>
                    <div v-if="awayBetType === 'spread'">
                      <q-input
                        style="max-width: 300px; margin: 0 auto 1em auto"
                        square
                        outlined
                        label="ETH"
                        type="number"
                        v-model="awaySpread"
                      ></q-input>
                    </div>
                  </div>
                  <q-card class="betTypes" @click="awayBetType = 'total'">
                    <q-card-section>
                      <div>
                        <span class="text-h6">
                          [{{ gameArray.OverUnder }}] Point Total
                          {{ returnAwayPointTotalUser }}
                        </span>
                        <div
                          v-if="awayCurrentPointTotal !== undefined"
                          class="betValue"
                        >
                          {{ returnAwayPointTotal }}
                        </div>
                      </div>
                    </q-card-section>

                    <q-card-section class="q-pt-none">
                      You are placing a wager based on whether or not the two
                      teams on the court exceed or fail to meet a certain
                      combined score.
                    </q-card-section>
                    <div v-if="awayBetType === 'total'">
                      <q-radio
                        v-model="overUnderAway"
                        :val="99"
                        label="Under"
                      />
                      <q-radio
                        v-model="overUnderAway"
                        :val="100"
                        label="Over"
                      />
                      <q-input
                        style="max-width: 300px; margin: 0 auto 1em auto"
                        square
                        outlined
                        label="ETH"
                        type="number"
                        v-model="awayTotal"
                      ></q-input>
                    </div>
                  </q-card>
                  <div class="text-center">
                    <q-btn
                      @click="async () => await sendBetAway()"
                      label="Confirm"
                    ></q-btn>
                  </div>
                </q-card>
              </q-dialog>
            </div>
            <div class="row items-center justify-evenly text-center betCard">
              <div v-if="gameArray.Status !== 'Scheduled'">
                <span>Away</span>
                <div
                  style="font-weight: 800; margin: 0.25em 0.3em"
                  class="text-h3"
                >
                  {{ gameArray.AwayTeamScore }}
                </div>
              </div>
              <div class="text-md align-center">
                <div v-if="gameArray.Status === 'Scheduled'">
                  {{ new Date(gameArray.DateTime).toLocaleTimeString() }}
                </div>
                <div v-if="gameArray.SeriesInfo === true">Playoffs</div>
                <div class="text-red">{{ gameArray.Status }}</div>
                <div
                  v-if="
                    gameArray.Status.charAt(0) !== 'F' &&
                    gameArray.Status !== 'Scheduled'
                  "
                >
                  {{ gameArray.TimeRemainingMinutes }}:{{
                    gameArray.TimeRemainingSeconds
                  }}
                </div>

                <div>{{ `${returnGameTotal} ETH` }}</div>
              </div>
              <div v-if="gameArray.Status !== 'Scheduled'">
                <span>Home</span>
                <div
                  style="font-weight: 800; margin: 0.25em 0.3em"
                  class="text-h3"
                >
                  {{ gameArray.HomeTeamScore }}
                </div>
              </div>
            </div>
            <div>
              <q-card class="betCard">
                <q-card-section>
                  Total Bet:
                  <span class="text-red">{{ returnHomeTotal + ' ETH' }}</span>
                </q-card-section>
                <q-card-section>
                  Money Line:
                  <span class="text-red">{{ returnHomeMoneyline }}</span>
                </q-card-section>
                <q-card-section>
                  [
                  {{
                    (gameArray.PointSpread > 0 ? '+' : null) +
                    gameArray.PointSpread
                  }}
                  ] Point Spread:
                  <span class="text-red">{{ returnHomePointSpread }}</span>
                </q-card-section>
                <q-card-section>
                  [
                  {{ gameArray.OverUnder }}
                  ] Point Total:
                  <span class="text-red">{{ returnHomePointTotal }}</span>
                </q-card-section>
                <q-btn @click="homeDialog = true">Place Bet</q-btn>
              </q-card>
              <q-dialog
                v-model="homeDialog"
                persistent
                maximized
                transition-show="slide-up"
                transition-hide="slide-down"
              >
                <q-card class="bg-grey-1 text-blue-grey-10">
                  <q-toolbar>
                    <q-avatar>
                      <img
                        src="https://cdn.discordapp.com/attachments/946638392958009384/1142081959917539348/01.png"
                      />
                    </q-avatar>

                    <q-toolbar-title>
                      <span class="text-weight-bold">EBSL</span>
                    </q-toolbar-title>

                    <q-btn flat round dense icon="close" v-close-popup />
                  </q-toolbar>
                  <q-card-section>
                    <h3 class="text-center q-mb-xs">
                      <q-img
                        fit="contain"
                        style="max-height: 2em; max-width: 2em"
                        :src="
                          TEAMS.find(
                            (row) => row.TeamID === gameArray.HomeTeamID
                          ).WikipediaLogoUrl
                        "
                        :key="gameArray.HomeTeamID"
                      />
                    </h3>
                    <div class="text-h2 text-center q-mt-xs">
                      {{
                        TEAMS.find((row) => row.Key === gameArray.HomeTeam).City
                      }}
                      {{
                        TEAMS.find((row) => row.Key === gameArray.HomeTeam).Name
                      }}
                    </div>
                  </q-card-section>
                  <div class="betTypes" @click="homeBetType = 'moneyline'">
                    <q-card-section>
                      <div>
                        <span class="text-h6">
                          Money Line {{ returnHomeMoneylineUser }}</span
                        >
                        <div
                          v-if="homeCurrentMoneyline !== undefined"
                          class="betValue"
                        >
                          {{ returnHomeMoneyline }}
                        </div>
                      </div>
                    </q-card-section>
                    <q-card-section class="q-pt-none">
                      Place your wager on
                      {{ gameArray.HomeTeam }} winning the game
                    </q-card-section>
                    <div v-if="homeBetType === 'moneyline'">
                      <q-input
                        style="max-width: 300px; margin: 0 auto 1em auto"
                        square
                        outlined
                        label="ETH"
                        type="number"
                        v-model="homeMoneyline"
                      ></q-input>
                    </div>
                  </div>

                  <div class="betTypes" @click="homeBetType = 'spread'">
                    <q-card-section>
                      <div>
                        <span class="text-h6">
                          [{{
                            (gameArray.PointSpread > 0 ? '+' : null) +
                            gameArray.PointSpread
                          }}] Point Spread {{ returnHomePointSpreadUser }}
                        </span>
                        <div
                          v-if="homeCurrentPointSpread !== undefined"
                          class="betValue"
                        >
                          {{ returnHomePointSpread }}
                        </div>
                      </div>
                    </q-card-section>

                    <q-card-section class="q-pt-none">
                      The point spread is a calculated points difference
                      determined by oddsmakers between two teams lining up.
                    </q-card-section>

                    <div v-if="homeBetType === 'spread'">
                      <q-input
                        style="max-width: 300px; margin: 0 auto 1em auto"
                        square
                        outlined
                        label="ETH"
                        type="number"
                        v-model="homeSpread"
                      ></q-input>
                    </div>
                  </div>
                  <div class="betTypes" @click="homeBetType = 'total'">
                    <q-card-section>
                      <div>
                        <span class="text-h6">
                          [{{ gameArray.OverUnder }}] Point Total
                          {{ returnHomePointTotalUser }}
                        </span>
                        <div
                          v-if="homeCurrentPointTotal !== undefined"
                          class="betValue"
                        >
                          {{ returnHomePointTotal }}
                        </div>
                      </div>
                    </q-card-section>

                    <q-card-section class="q-pt-none">
                      You are placing a wager based on whether or not the two
                      teams on the court exceed or fail to meet a certain
                      combined score.
                    </q-card-section>
                    <div v-if="homeBetType === 'total'">
                      <q-radio
                        v-model="overUnderHome"
                        :val="99"
                        label="Under"
                      />
                      <q-radio
                        v-model="overUnderHome"
                        :val="100"
                        label="Over"
                      />
                      <q-input
                        style="max-width: 300px; margin: 0 auto 1em auto"
                        square
                        outlined
                        label="ETH"
                        type="number"
                        v-model="homeTotal"
                      ></q-input>
                    </div>
                  </div>
                  <div class="text-center">
                    <q-btn
                      @click="async () => await sendBetHome()"
                      label="Confirm"
                    ></q-btn>
                  </div>
                </q-card>
              </q-dialog>
            </div>
          </div>
        </q-card-section>
        <q-card-section v-if="gameArray.Status !== 'Scheduled'">
          <q-table
            :title="gameArray.AwayTeam"
            :rows="statsArrayAway"
            :columns="statColumns"
            :row-key="(row) => row.StatID"
            :rows-per-page-options="[0]"
            :auto-width="true"
            virtual-scroll
            style="max-height: 30em"
            @row-click="
              (evt, row, index) =>
                $router.push({ path: `/players/${row.PlayerID}` })
            "
          />

          <q-table
            :title="gameArray.HomeTeam"
            :rows="statsArrayHome"
            :columns="statColumns"
            :row-key="(row) => row.StatID"
            :rows-per-page-options="[0]"
            :auto-width="true"
            virtual-scroll
            style="max-height: 30em"
            @row-click="
              (evt, row, index) =>
                $router.push({ path: `/players/${row.PlayerID}` })
            "
          />
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>
<style lang="scss" scoped>
.hover:hover {
  cursor: pointer;
}
.betCard {
  border: 5px $grey-4 solid;
  border-radius: 10px;
  color: $blue-grey-10;
  background: $grey-1;
  margin: auto;
  padding: 0.5em;
  font-weight: 650;
}
.mainCard {
  margin: 2em;
  color: $blue-grey-10;
  background-color: $grey-1;
  border: 4px $grey-4 solid;
  border-radius: 5px;
  padding: 1em;
}
.score {
  color: $lime-12;
  background-color: black;
  border: 3px $lime-12 solid;
  border-radius: 10px;
  padding: 2em;
  margin: auto;
  min-width: 10vw;
}
.betTypes {
  border: 5px $grey-4 solid;
  border-radius: 12px !important;
  text-align: center;
  margin: 1em auto;
  width: 80%;
  background: $grey-1;
}
.betTypes:hover {
  cursor: pointer;
}
.betValue {
  border: 3px $blue-grey-10 solid;
  width: 7.5em;
  margin: 0 auto;
}
.dateSign {
  color: $blue-grey-10;
  border: 3px red solid;
  border-radius: 5px;
  font-weight: 1000;
  background-color: $grey-1;
  margin: 0 auto;
  padding: 0.25em 0.5em;
}
</style>
