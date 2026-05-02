import { encodeAbiParameters, encodePacked, fromHex, parseGwei, toHex } from "viem";
import { ACCOUNT, ACCOUNT_FACTORY, ENTRY_POINT, PAYMASTER, SEPOLIA } from "./config.js";

(async () => {
  const create2Account = `0x${ACCOUNT_FACTORY.methodIdentifiers["create2Account(address)"]}${encodeAbiParameters(
    [{ name: "owner", type: "address" }],
    [SEPOLIA.account.address],
  ).slice(2)}`;
  const { data } = await SEPOLIA.call({
    to: ACCOUNT_FACTORY.sepolia.address,
    data: create2Account,
  });
  const userAccountAddress = `0x${data.slice(-40)}`;

  const deployedAddress = await SEPOLIA.readContract({
    address: ACCOUNT_FACTORY.sepolia.address,
    abi: ACCOUNT_FACTORY.abi,
    functionName: "getAccountAddress",
    args: [SEPOLIA.account.address],
  });
  const isDeployed = fromHex(deployedAddress, "bigint") > 0n;

  // https://www.alchemy.com/docs/wallets/api-reference/gas-manager-admin-api/gas-abstraction-api-endpoints/alchemy-request-gas-and-paymaster-and-data
  const policyId = process.env.PM_POLICY_ID; // The Gas Manager Policy ID
  const entryPoint = ENTRY_POINT.sepolia.address; // The EntryPoint address the request should be sent through
  const dummySignature = "0xfffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c"; // Dummy signature for the userOperation

  const nonce = await SEPOLIA.readContract({
    address: ENTRY_POINT.sepolia.address,
    abi: ENTRY_POINT.abi,
    functionName: "getNonce",
    args: [userAccountAddress, 0],
  });
  const userOperation = {
    sender: userAccountAddress,
    nonce: toHex(nonce),
    initCode: isDeployed ? "0x" : `${ACCOUNT_FACTORY.sepolia.address}${create2Account.slice(2)}`,
    callData: `0x${ACCOUNT.methodIdentifiers["increment()"]}`,
    signature: dummySignature,
  };

  // TODO: Everything onward hasn't been tested successfully. Waiting for Alchemy EntryPoint v0.9.0 support
  const {
    paymaster,
    paymasterData,
    callGasLimit,
    verificationGasLimit,
    preVerificationGas,
    maxFeePerGas,
    maxPriorityFeePerGas,
    paymasterVerificationGasLimit,
    paymasterPostOpGasLimit,
  } = await SEPOLIA.request({
    method: "alchemy_requestGasAndPaymasterAndData",
    params: [{ policyId, entryPoint, dummySignature, userOperation }],
  });
  userOperation.paymasterAndData = `${paymaster}${encodePacked(
    ["uint128", "uint128"],
    [fromHex(paymasterVerificationGasLimit, "bigint"), fromHex(paymasterPostOpGasLimit, "bigint")],
  ).slice(2)}${paymasterData.slice(2)}`;
  userOperation.accountGasLimits = encodePacked(
    ["uint128", "uint128"],
    [fromHex(verificationGasLimit, "bigint"), fromHex(callGasLimit, "bigint")],
  );
  userOperation.gasFees = encodePacked(
    ["uint128", "uint128"],
    [fromHex(maxPriorityFeePerGas, "bigint"), fromHex(maxFeePerGas, "bigint")],
  );
  userOperation.preVerificationGas = preVerificationGas;

  const userOpHash = await FOUNDRY.readContract({
    address: ENTRY_POINT.foundry.address,
    abi: ENTRY_POINT.abi,
    functionName: "getUserOpHash",
    args: [userOp],
  });
  userOperation.signature = await SEPOLIA.signMessage({ message: { raw: userOpHash } });

  const operationHash = await SEPOLIA.request({
    method: "eth_sendUserOperation",
    params: [userOperation, ENTRY_POINT.sepolia.address],
  });
  setTimeout(async () => {
    const { transactionHash } = await SEPOLIA.request({
      method: "eth_getUserOperationByHash",
      params: [operationHash],
    });
    const { status } = await SEPOLIA.waitForTransactionReceipt({ hash: transactionHash });
    console.log({ status });
    console.log({
      number: await SEPOLIA.readContract({
        address: userAccountAddress,
        abi: ACCOUNT.abi,
        functionName: "number",
      })
    });
  }, 12_000);
})();
