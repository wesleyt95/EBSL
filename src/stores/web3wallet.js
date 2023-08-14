import { defineStore } from 'pinia';

export const useWalletStore = defineStore('wallet', {
  state: () => ({
    user: window.ethereum._state?.accounts[0],
    chainID: window.ethereum?.chainId,
  })
});
