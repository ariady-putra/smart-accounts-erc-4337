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

  const callGasLimit = 800_000n;
  const verificationGasLimit = 800_000n;
  const postOpGasLimit = 800_000n; // for Paymaster's postOp gas limit
  const maxFeePerGas = parseGwei("40");
  const maxPriorityFeePerGas = parseGwei("20");

  const userOp = {
    sender: userAccountAddress,
    nonce: toHex(nonce),
    initCode: isDeployed ? "0x" : `${ACCOUNT_FACTORY.sepolia.address}${create2Account.slice(2)}`,
    callData: `0x${ACCOUNT.methodIdentifiers["increment()"]}`,
    paymasterAndData: PAYMASTER.sepolia.address,
    signature: "0xfffffffffffffffffffffffffffffff0000000000000000000000000000000007aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa1c",
  };
  const gasEstimation = await SEPOLIA.request({
    method: "eth_estimateUserOperationGas",
    params: [userOp, ENTRY_POINT.sepolia.address],
  });
  console.log({ gasEstimation });

  // userOp.signature = await SEPOLIA.signMessage({ message: { raw: userOpHash } });

  // const { request } = await SEPOLIA.simulateContract({
  //   address: ENTRY_POINT.sepolia.address,
  //   abi: ENTRY_POINT.abi,
  //   functionName: "handleOps",
  //   args: [[userOp], SEPOLIA.account.address],
  // });
  // const hash = await SEPOLIA.writeContract(request);
  // const { status } = await SEPOLIA.waitForTransactionReceipt({ hash });
  // console.log({ status });
  // console.log({
  //   number: await SEPOLIA.readContract({
  //     address: userAccountAddress,
  //     abi: ACCOUNT.abi,
  //     functionName: "number",
  //   })
  // });
})();
