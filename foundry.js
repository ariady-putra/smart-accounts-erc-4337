import { encodeAbiParameters, encodePacked, fromHex, parseGwei, toHex } from "viem";
import { ACCOUNT, ACCOUNT_FACTORY, ENTRY_POINT, FOUNDRY, PAYMASTER } from "./config.js";

(async () => {
  const create2Account = `0x${ACCOUNT_FACTORY.methodIdentifiers["create2Account(address)"]}${encodeAbiParameters(
    [{ name: "owner", type: "address" }],
    [FOUNDRY.account.address],
  ).slice(2)}`;
  const { data } = await FOUNDRY.call({
    to: ACCOUNT_FACTORY.foundry.address,
    data: create2Account,
  });
  const userAccountAddress = `0x${data.slice(-40)}`;

  const deployedAddress = await FOUNDRY.readContract({
    address: ACCOUNT_FACTORY.foundry.address,
    abi: ACCOUNT_FACTORY.abi,
    functionName: "getAccountAddress",
    args: [FOUNDRY.account.address],
  });
  const isDeployed = fromHex(deployedAddress, "bigint") > 0n;

  const nonce = await FOUNDRY.readContract({
    address: ENTRY_POINT.foundry.address,
    abi: ENTRY_POINT.abi,
    functionName: "getNonce",
    args: [userAccountAddress, 0],
  });

  const callGasLimit = 800_000n;
  const verificationGasLimit = 800_000n;
  const postOpGasLimit = 800_000n; // for Paymaster's postOp gas limit
  const maxFeePerGas = parseGwei("40");
  const maxPriorityFeePerGas = parseGwei("20");

  const userOp = {
    sender: userAccountAddress,
    nonce: toHex(nonce),
    initCode: isDeployed ? "0x" : `${ACCOUNT_FACTORY.foundry.address}${create2Account.slice(2)}`,
    callData: `0x${ACCOUNT.methodIdentifiers["increment()"]}`,
    accountGasLimits: encodePacked(["uint128", "uint128"], [verificationGasLimit, callGasLimit]),
    preVerificationGas: toHex(200_000n),
    gasFees: encodePacked(["uint128", "uint128"], [maxPriorityFeePerGas, maxFeePerGas]),
    paymasterAndData: encodePacked(["address", "uint128", "uint128"], [PAYMASTER.foundry.address, verificationGasLimit, postOpGasLimit]),
    signature: "0x",
  };
  const userOpHash = await FOUNDRY.readContract({
    address: ENTRY_POINT.foundry.address,
    abi: ENTRY_POINT.abi,
    functionName: "getUserOpHash",
    args: [userOp],
  });

  userOp.signature = await FOUNDRY.signMessage({ message: { raw: userOpHash } });

  const { request } = await FOUNDRY.simulateContract({
    address: ENTRY_POINT.foundry.address,
    abi: ENTRY_POINT.abi,
    functionName: "handleOps",
    args: [[userOp], FOUNDRY.account.address],
  });
  const hash = await FOUNDRY.writeContract(request);
  const { status } = await FOUNDRY.waitForTransactionReceipt({ hash });
  console.log({ status });
  console.log({
    number: await FOUNDRY.readContract({
      address: userAccountAddress,
      abi: ACCOUNT.abi,
      functionName: "number",
    })
  });
})();
