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
    ENTRY_POINT: "0xEc463742DA80C4552E133d91cEC82cDE3E68219d",
    PAYMASTER: "0xCf912FeF40B49c52ac28B6DF547c246984D00d8D",
    ACCOUNT_FACTORY: "0x50E43561fCc60d6B7C0198a5078F27e17588d7ba",
  },
  SEPOLIA: {
    ENTRY_POINT: "0x433709009B8330FDa32311DF1C2AFA402eD8D009",
    PAYMASTER: "0xc8953C236d7a173DdeDD0889fFac499dB545d6C4",
    ACCOUNT_FACTORY: "0x946f350D26505C268D5A50F1547D744D59074DB3",
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
