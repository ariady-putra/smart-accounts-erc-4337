import { createWalletClient, defineChain, http, publicActions } from "viem";
import { generatePrivateKey, privateKeyToAccount } from "viem/accounts";
import { sepolia } from "viem/chains";

import EntryPoint from "./out/EntryPoint.sol/EntryPoint.json" with { type: "json" };
import Paymaster from "./out/Paymaster.sol/Paymaster.json" with { type: "json" };
import AccountFactory from "./out/AccountFactory.sol/AccountFactory.json" with { type: "json" };
import Account from "./out/Account.sol/Account.json" with { type: "json" };

import { config } from "dotenv";
config({ quiet: true });

const ADDRESS = {
  FOUNDRY: {
    ENTRY_POINT: "0x4130B7F329d09b4DEaF7f73181931EFCf99fcc0f",
    PAYMASTER: "0xcD4D8F590EBa734201E435840C684d5f52B8590E",
    ACCOUNT_FACTORY: "0xe9e1BB973EFA9ca167a95B463281DB0C66401480",
  },
  SEPOLIA: {
    ENTRY_POINT: "0x433709009B8330FDa32311DF1C2AFA402eD8D009",
    PAYMASTER: "0xc8953C236d7a173DdeDD0889fFac499dB545d6C4",
    ACCOUNT_FACTORY: "0xe816559A19AFE2aBbe0fC0e81843fF9f101C7a64",
  },
};

export const ENTRY_POINT = {
  ...EntryPoint,
  foundry: { address: ADDRESS.FOUNDRY.ENTRY_POINT },
  sepolia: { address: ADDRESS.SEPOLIA.ENTRY_POINT },
};
export const PAYMASTER = {
  ...Paymaster,
  foundry: { address: ADDRESS.FOUNDRY.PAYMASTER },
  sepolia: { address: ADDRESS.SEPOLIA.PAYMASTER },
};
export const ACCOUNT_FACTORY = {
  ...AccountFactory,
  foundry: { address: ADDRESS.FOUNDRY.ACCOUNT_FACTORY },
  sepolia: { address: ADDRESS.SEPOLIA.ACCOUNT_FACTORY },
};
export const ACCOUNT =
  Account;

export const FOUNDRY = createWalletClient({
  account: privateKeyToAccount(process.env.PRIVATE_KEY),
  chain: defineChain({
    id: 1337,
    name: "Foundry",
    nativeCurrency: {
      decimals: 18,
      name: "Ether",
      symbol: "ETH",
    },
    rpcUrls: {
      default: {
        http: ["http://127.0.0.1:8545"],
        webSocket: ["ws://127.0.0.1:8545"],
      },
    },
  }),
  mode: "anvil",
  transport: http(),
}).extend(publicActions);

export const SEPOLIA = createWalletClient({
  account: privateKeyToAccount(process.env.PRIVATE_KEY ?? generatePrivateKey()),
  chain: sepolia,
  transport: http(process.env.RPC_URL),
}).extend(publicActions);
