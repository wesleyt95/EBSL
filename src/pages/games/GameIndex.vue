<script setup>
import { ref, watchEffect, computed } from 'vue';
import { useRoute } from 'vue-router';
import { ethers } from 'ethers';

const router = useRoute();
const user = ref();
const provider = new ethers.BrowserProvider(window.ethereum);
const contract = require('/artifacts/contracts/Bet.sol/Bet.json');
const betContract = new ethers.Contract(
  process.env.CONTRACT_ADDRESS,
  contract.abi,
  provider
);

const gameArray = ref([]);
const gameTotal = ref();
const homeTotalBet = ref();
const awayTotalBet = ref();
const homeOdds = ref();
const awayOdds = ref();
const statsArrayAway = ref([]);
const statsArrayHome = ref([]);

const homeDialog = ref(false);
const awayDialog = ref(false);

const homeBetType = ref();
const homeMoneyline = ref();
const homeSpread = ref();
const homeTotal = ref();
const awayBetType = ref();
const awayMoneyline = ref();
const awaySpread = ref();
const awayTotal = ref();

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
    name: 'player',
    label: 'Name',
    field: 'player',
    format: (val) => `${val.first_name} ${val.last_name}`,
    align: 'left',
  },
  {
    name: 'min',
    label: 'Minutes',
    field: 'min',
  },
  {
    name: 'pts',
    label: 'Points',
    field: 'pts',
  },
  { name: 'reb', label: 'Rebounds', field: 'reb' },
  { name: 'ast', label: 'Assists', field: 'ast' },
  { name: 'stl', label: 'Steals', field: 'stl' },
  { name: 'blk', label: 'Blocks', field: 'blk' },
];

watchEffect(async () => {
  if (
    window.ethereum._state.accounts &&
    window.ethereum._state.accounts.length > 0
  ) {
    user.value = window.ethereum._state.accounts[0];
  }
  await fetch(
    `https://www.balldontlie.io/api/v1/games/${Number(router.params.id)}`
  ).then((responseData) =>
    responseData.json().then((data) => (gameArray.value = data))
  );

  await fetch(
    `https://www.balldontlie.io/api/v1/stats?game_ids[]=${Number(
      router.params.id
    )}`
  ).then((responseData) =>
    responseData.json().then(async (data) => {
      statsArrayAway.value = await data.data.filter(
        (row) => row.team.id === gameArray.value.visitor_team.id
      );
      statsArrayHome.value = await data.data.filter(
        (row) => row.team.id === gameArray.value.home_team.id
      );
    })
  );

  if (gameTotal.value == undefined) {
    gameTotal.value = await betContract.totalBetOnGame(
      Number(router.params.id)
    );
  }
  if (homeTotalBet.value == undefined) {
    homeTotalBet.value = await betContract.totalBetOnTeam(
      Number(router.params.id),
      gameArray.value.home_team.id
    );
  }
  if (awayTotalBet.value == undefined) {
    awayTotalBet.value = await betContract.totalBetOnTeam(
      Number(router.params.id),
      gameArray.value.visitor_team.id
    );
  }
  if (homeOdds.value == undefined) {
    homeOdds.value = await betContract.returnOdds(
      Number(router.params.id),
      gameArray.value.home_team.id
    );
  }
  if (awayOdds.value == undefined) {
    awayOdds.value = await betContract.returnOdds(
      Number(router.params.id),
      gameArray.value.visitor_team.id
    );
  }

  if (homeCurrentMoneylineUser.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnMoneyLineBetReceipt(
      Number(router.params.id),
      gameArray.value.home_team.id
    );
    homeCurrentMoneylineUser.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (awayCurrentMoneylineUser.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnMoneyLineBetReceipt(
      Number(router.params.id),
      gameArray.value.visitor_team.id
    );
    awayCurrentMoneylineUser.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (homeCurrentMoneyline.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnMoneyLineBetTotal(
      Number(router.params.id),
      gameArray.value.home_team.id
    );
    homeCurrentMoneyline.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (awayCurrentMoneyline.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnMoneyLineBetTotal(
      Number(router.params.id),
      gameArray.value.visitor_team.id
    );
    awayCurrentMoneyline.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }
  if (homeCurrentPointSpreadUser.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnPointSpreadBetReceipt(
      Number(router.params.id),
      gameArray.value.home_team.id
    );
    homeCurrentPointSpreadUser.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (awayCurrentPointSpreadUser.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnPointSpreadBetReceipt(
      Number(router.params.id),
      gameArray.value.visitor_team.id
    );
    awayCurrentPointSpreadUser.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (homeCurrentPointSpread.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnPointSpreadBetTotal(
      Number(router.params.id),
      gameArray.value.home_team.id
    );
    homeCurrentPointSpread.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (awayCurrentPointSpread.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnPointSpreadBetTotal(
      Number(router.params.id),
      gameArray.value.visitor_team.id
    );
    awayCurrentPointSpread.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }
  if (homeCurrentPointTotalUser.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnPointTotalBetReceipt(
      Number(router.params.id)
    );
    homeCurrentPointTotalUser.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (awayCurrentPointTotalUser.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnPointTotalBetReceipt(
      Number(router.params.id)
    );
    awayCurrentPointTotalUser.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (homeCurrentPointTotal.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnPointTotalBetTotal(
      Number(router.params.id)
    );
    homeCurrentPointTotal.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
  }

  if (awayCurrentPointTotal.value == undefined) {
    const betContract = new ethers.Contract(
      process.env.CONTRACT_ADDRESS,
      contract.abi,
      await provider.getSigner()
    );
    const receipt = await betContract.returnPointTotalBetTotal(
      Number(router.params.id)
    );
    awayCurrentPointTotal.value = JSON.stringify(receipt, (_, v) =>
      typeof v === 'bigint' ? v.toString() : v
    );
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
        user.value,
        Number(router.params.id),
        gameArray.value.visitor_team.id,
        gameArray.value.home_team.id,
        gameArray.value.visitor_team.id,
        Date.parse(gameArray.value.date) / 1000,
        process.env.MONEYLINE_ADDRESS,
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
        user.value,
        Number(router.params.id),
        gameArray.value.visitor_team.id,
        gameArray.value.home_team.id,
        gameArray.value.visitor_team.id,
        Date.parse(gameArray.value.date) / 1000,
        14,
        process.env.POINTSPREAD_ADDRESS,
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
        user.value,
        Number(router.params.id),
        200,
        gameArray.value.home_team.id,
        gameArray.value.visitor_team.id,
        Date.parse(gameArray.value.date) / 1000,
        -1,
        process.env.POINTTOTAL_ADDRESS,
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
        user.value,
        Number(router.params.id),
        gameArray.value.home_team.id,
        gameArray.value.home_team.id,
        gameArray.value.visitor_team.id,
        Date.parse(gameArray.value.date) / 1000,
        process.env.MONEYLINE_ADDRESS,
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
        user.value,
        Number(router.params.id),
        gameArray.value.home_team.id,
        gameArray.value.home_team.id,
        gameArray.value.visitor_team.id,
        Date.parse(gameArray.value.date) / 1000,
        14,
        process.env.POINTSPREAD_ADDRESS,
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
        user.value,
        Number(router.params.id),
        200,
        gameArray.value.home_team.id,
        gameArray.value.visitor_team.id,
        Date.parse(gameArray.value.date) / 1000,
        -1,
        process.env.POINTTOTAL_ADDRESS,
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
const logResult = async () => {
  const betContract = new ethers.Contract(
    process.env.CONTRACT_ADDRESS,
    contract.abi,
    await provider.getSigner()
  );
  try {
    const tx = await betContract._depositFunds1Balance(
      9000000000000000,
      '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
      user.value
    );
    await tx.wait();
    window.location.reload();
    console.log(tx);
  } catch (err) {
    console.log(err);
  }
};
</script>
<template>
  <q-page>
    <div>
      <q-card v-if="gameArray.date" class="mainCard">
        <div class="text-center">
          {{ new Date(gameArray.date).toLocaleDateString() }}
        </div>
        <q-card-section>
          <div class="row items-center justify-evenly text-h3 text-center">
            <div style="width: 40%">
              {{ gameArray.visitor_team?.full_name + ` (${returnAwayOdds}%)` }}
            </div>
            <div style="width: 10%">@</div>
            <div style="width: 40%">
              {{ gameArray.home_team?.full_name + ` (${returnHomeOdds}%)` }}
            </div>
          </div>
        </q-card-section>
        <q-card-section v-if="gameArray.period === 0">
          <div class="row items-center justify-evenly text-center">
            <div>
              {{ gameArray.visitor_team?.division }} Division|{{
                gameArray.visitor_team?.conference
              }}ern Conference
            </div>
            <div class="text-md align-center">
              <div v-if="gameArray.postseason === true">Playoffs</div>
              <div>{{ new Date(gameArray.date).toLocaleTimeString() }}</div>
              <div>{{ new Date(gameArray.date).toLocaleDateString() }}</div>
            </div>
            <div>
              {{ gameArray.home_team?.division }} Division|{{
                gameArray.home_team?.conference
              }}ern Conference
            </div>
          </div>
        </q-card-section>
        <q-card-section v-else>
          <div
            style="width: 80%"
            class="row items-center justify-evenly text-center q-mx-auto"
          >
            <div>
              <q-card @click="awayDialog = true"
                ><q-card-section>{{
                  returnAwayTotal + ' ETH'
                }}</q-card-section></q-card
              >
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
                        src="https://content.sportslogos.net/logos/6/982/full/8147__national_basketball_association-primary-2018.png"
                      />
                    </q-avatar>

                    <q-toolbar-title
                      ><span class="text-weight-bold">EBSL</span>
                    </q-toolbar-title>

                    <q-btn flat round dense icon="close" v-close-popup />
                  </q-toolbar>
                  <q-card-section>
                    <div class="text-h3 text-center">
                      {{ gameArray.visitor_team?.full_name }}
                    </div>
                  </q-card-section>
                  <div class="betTypes">
                    <q-radio
                      v-model="awayBetType"
                      val="moneyline"
                      checked-icon="null"
                      unchecked-icon="null"
                    >
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
                        {{ gameArray.visitor_team?.full_name }} winning the
                        game.
                      </q-card-section>
                    </q-radio>
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

                  <div class="betTypes">
                    <q-radio
                      v-model="awayBetType"
                      val="spread"
                      checked-icon="null"
                      unchecked-icon="null"
                    >
                      <q-card-section>
                        <div>
                          <span class="text-h6">
                            Point Spread {{ returnAwayPointSpreadUser }}
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
                    </q-radio>
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
                  <q-card class="betTypes">
                    <q-radio
                      v-model="awayBetType"
                      val="total"
                      checked-icon="null"
                      unchecked-icon="null"
                    >
                      <q-card-section>
                        <div>
                          <span class="text-h6">
                            Point Total {{ returnAwayPointTotalUser }}
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
                        <q-input
                          style="max-width: 300px; margin: 0 auto 1em auto"
                          square
                          outlined
                          label="ETH"
                          type="number"
                          v-model="awayTotal"
                        ></q-input>
                      </div>
                    </q-radio>
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
            <div class="row items-center justify-evenly text-center score">
              <div>
                <span>Away</span>
                <div style="font-weight: 800" class="text-h3">
                  {{ gameArray.visitor_team_score }}
                </div>
              </div>
              <div class="text-md align-center">
                <div v-if="gameArray.postseason === true">Playoffs</div>
                <div v-if="gameArray.status !== 'Final'">
                  {{ gameArray.time }}
                </div>
                <div>{{ gameArray.status }}</div>
                <div>{{ `${returnGameTotal} ETH` }}</div>
              </div>
              <div>
                <span>Home</span>
                <div style="font-weight: 800" class="text-h3">
                  {{ gameArray.home_team_score }}
                </div>
              </div>
            </div>
            <div>
              <q-card @click="homeDialog = true"
                ><q-card-section>{{
                  returnHomeTotal + ' ETH'
                }}</q-card-section></q-card
              >
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
                        src="https://content.sportslogos.net/logos/6/982/full/8147__national_basketball_association-primary-2018.png"
                      />
                    </q-avatar>

                    <q-toolbar-title
                      ><span class="text-weight-bold">EBSL</span>
                    </q-toolbar-title>

                    <q-btn flat round dense icon="close" v-close-popup />
                  </q-toolbar>
                  <q-card-section>
                    <div class="text-h3 text-center">
                      {{ gameArray.home_team?.full_name }}
                    </div>
                  </q-card-section>
                  <div class="betTypes">
                    <q-radio
                      v-model="homeBetType"
                      val="moneyline"
                      checked-icon="null"
                      unchecked-icon="null"
                    >
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
                        {{ gameArray.home_team?.full_name }} winning the game
                      </q-card-section>
                    </q-radio>
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

                  <div class="betTypes">
                    <q-radio
                      v-model="homeBetType"
                      val="spread"
                      checked-icon="null"
                      unchecked-icon="null"
                    >
                      <q-card-section>
                        <div>
                          <span class="text-h6">
                            Point Spread {{ returnHomePointSpreadUser }}
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
                    </q-radio>
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
                  <div class="betTypes">
                    <q-radio
                      v-model="homeBetType"
                      val="total"
                      checked-icon="null"
                      unchecked-icon="null"
                    >
                      <q-card-section>
                        <div>
                          <span class="text-h6">
                            Point Total {{ returnHomePointTotalUser }}
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
                        <q-input
                          style="max-width: 300px; margin: 0 auto 1em auto"
                          square
                          outlined
                          label="ETH"
                          type="number"
                          v-model="homeTotal"
                        ></q-input>
                      </div>
                    </q-radio>
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
        <q-card-section v-if="gameArray.period > 0">
          <div class="row items-center justify-evenly">
            <div>
              <q-table
                :title="gameArray.visitor_team.full_name"
                :rows="statsArrayAway"
                :columns="statColumns"
                :row-key="(row) => row.id"
                :rows-per-page-options="[0]"
                :auto-width="true"
                virtual-scroll
                style="height: 30em"
                @row-click="
                  (evt, row, index) =>
                    this.$router.replace({ path: `/players/${row.player.id}` })
                "
              />
            </div>
            <div @click="logResult">
              <q-table
                :title="gameArray.home_team.full_name"
                :rows="statsArrayHome"
                :columns="statColumns"
                :row-key="(row) => row.id"
                :rows-per-page-options="[0]"
                :auto-width="true"
                virtual-scroll
                style="height: 30em"
                @row-click="
                  (evt, row, index) =>
                    this.$router.replace({ path: `/players/${row.player.id}` })
                "
              />
            </div>
          </div>
        </q-card-section>
      </q-card>
    </div>
  </q-page>
</template>
<style lang="scss" scoped>
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
  width: 50%;
}
.betTypes {
  border: 3px $blue-grey-10 solid;
  text-align: center;
  margin: 1em auto;
  width: 80%;
  background: #fff;
}

.betValue {
  border: 3px $blue-grey-10 solid;
  width: 7.5em;
  margin: 0 auto;
}
</style>
