import { defineStore } from 'pinia';

export const useWalletStore = defineStore('wallet', {
  state: () => ({
    user:
      window.ethereum?._state?.accounts?.length > 0
        ? window.ethereum._state.accounts[0]
        : undefined,
    chainID: window.ethereum?.chainId ? window.ethereum.chainId : undefined,
  }),
});
