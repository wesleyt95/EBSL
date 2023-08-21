<script setup>
import { useWalletStore } from 'stores/web3wallet';
const store = useWalletStore();
</script>
<template>
  <div>
    <div v-if="store.user === '0xAb97Bf09F0F404f9dc271314bb09Dd0f097C990A'">
      Authenticated
    </div>
    <div v-else>Imposter</div>
  </div>
</template>
<style scoped></style>
