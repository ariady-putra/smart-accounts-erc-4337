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

  const nonce = await SEPOLIA.readContract({
    address: ENTRY_POINT.sepolia.address,
    abi: ENTRY_POINT.abi,
    functionName: "getNonce",
    args: [userAccountAddress, 0],
  });

  const userOp = {
    sender: userAccountAddress,
    nonce: toHex(nonce),
    initCode: isDeployed ? "0x" : `${ACCOUNT_FACTORY.sepolia.address}${create2Account.slice(2)}`,
    callData: `0x${ACCOUNT.methodIdentifiers["increment()"]}`,
    paymasterAndData: PAYMASTER.sepolia.address,
    signature: "0xfffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c",
  };

  // TODO: Everything onward hasn't been tested successfully. Waiting for Alchemy EntryPoint v0.9.0 support

  const { preVerificationGas, verificationGasLimit, callGasLimit } = await SEPOLIA.request({
    method: "eth_estimateUserOperationGas",
    params: [userOp, ENTRY_POINT.sepolia.address],
  });
  userOp.paymasterAndData = encodePacked(["address", "uint128", "uint128"], [PAYMASTER.foundry.address, verificationGasLimit, 800_000n]);
  userOp.accountGasLimits = encodePacked(["uint128", "uint128"], [verificationGasLimit, callGasLimit]);
  userOp.preVerificationGas = toHex(preVerificationGas);

  const { maxFeePerGas } = await SEPOLIA.estimateFeesPerGas();
  const maxPriorityFeePerGas = await SEPOLIA.request({ method: "rundler_maxPriorityFeePerGas" });
  userOp.gasFees = encodePacked(["uint128", "uint128"], [maxPriorityFeePerGas, maxFeePerGas]);

  const userOpHash = await FOUNDRY.readContract({
    address: ENTRY_POINT.foundry.address,
    abi: ENTRY_POINT.abi,
    functionName: "getUserOpHash",
    args: [userOp],
  });

  userOp.signature = await SEPOLIA.signMessage({ message: { raw: userOpHash } });

  const operationHash = await SEPOLIA.request({
    method: "eth_sendUserOperation",
    params: [userOp, ENTRY_POINT.sepolia.address],
  });

  const test = setTimeout(async () => {
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

    clearTimeout(test);
  }, 12_000);
})();
