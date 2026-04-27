// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script, VmSafe} from "forge-std/Script.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {EntryPointScript} from "./EntryPoint.s.sol";
import {PaymasterScript} from "./Paymaster.s.sol";
import {AccountFactoryScript} from "./AccountFactory.s.sol";
import {Account as Acc} from "../src/Account.sol";

contract DeployWithPaymasterScript is Script {
    using MessageHashUtils for bytes32;

    EntryPointScript public eps;
    PaymasterScript public pms;
    AccountFactoryScript public afs;

    address payable bundler; // test only
    VmSafe.Wallet user;

    function _sign(VmSafe.Wallet memory wallet, bytes32 digest) private pure returns (bytes memory signature) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet, digest);
        signature = abi.encodePacked(r, s, v); // NOTE: The order here is different
    }

    function setUp() public {
        // user = payable(vm.promptAddress("User address"));
        // user = payable(makeAddr("User")); // test only
        user = vm.createWallet("User");
        bundler = payable(makeAddr("Bundler")); // test only

        eps = new EntryPointScript();
        pms = new PaymasterScript();
        afs = new AccountFactoryScript();
    }

    function run() public {
        eps.run();
        pms.run();
        afs.run();

        // Below code is to test EntryPoint and AccountFactory:

        address epAddress = address(eps.ep());
        address pmAddress = address(pms.pm());
        address afAddress = address(afs.af());

        address userAccountAddress = vm.computeCreateAddress(afAddress, afs.af().nonces(afAddress)); // address(userAccount)
        bytes memory createUserAccount = abi.encodeWithSelector(afs.af().createAccount.selector, user.addr); // AccountFactory.createAccount(user)
        bytes memory incrementUserAccount = abi.encodeWithSelector(Acc.increment.selector); // Account(userAccountAddress).increment()

        uint128 callGasLimit = 400_000;
        uint128 verificationGasLimit = 400_000;
        uint128 postOpGasLimit = 400_000; // for Paymaster's postOp gas limit
        uint128 maxFeePerGas = 20 gwei;
        uint128 maxPriorityFeePerGas = 10 gwei;

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = PackedUserOperation({
            sender: userAccountAddress,
            nonce: eps.ep().getNonce(userAccountAddress, 0),
            initCode: abi.encodePacked(afAddress, createUserAccount),
            callData: incrementUserAccount,
            accountGasLimits: bytes32(abi.encodePacked(verificationGasLimit, callGasLimit)),
            preVerificationGas: 100_000,
            gasFees: bytes32(abi.encodePacked(maxPriorityFeePerGas, maxFeePerGas)),
            paymasterAndData: abi.encodePacked(pmAddress, verificationGasLimit, postOpGasLimit),
            signature: ""
        });
        ops[0].signature = _sign(user, eps.ep().getUserOpHash(ops[0]).toEthSignedMessageHash());

        uint256 initialDeposit = 3 ether;
        vm.deal(bundler, initialDeposit); // test only
        vm.startBroadcast(bundler);
        if (eps.ep().balanceOf(pmAddress) == 0) {
            eps.ep().depositTo{value: bundler.balance}(pmAddress);
        }
        eps.ep().handleOps(ops, bundler);
        vm.stopBroadcast();

        require(Acc(userAccountAddress).number() == 1, "1 - Must have increased number once");
        require(bundler.balance == initialDeposit - eps.ep().balanceOf(pmAddress), "2 - Must compensate bundler");

        // Test call user account again (increment), now we do not set the initCode:

        ops[0] = PackedUserOperation({
            sender: userAccountAddress,
            nonce: eps.ep().getNonce(userAccountAddress, 0),
            initCode: "", // abi.encodePacked(afAddress, createUserAccount), // user account has been created
            callData: incrementUserAccount,
            accountGasLimits: bytes32(abi.encodePacked(verificationGasLimit, callGasLimit)),
            preVerificationGas: 100_000,
            gasFees: bytes32(abi.encodePacked(maxPriorityFeePerGas, maxFeePerGas)),
            paymasterAndData: abi.encodePacked(pmAddress, verificationGasLimit, postOpGasLimit),
            signature: ""
        });
        ops[0].signature = _sign(user, eps.ep().getUserOpHash(ops[0]).toEthSignedMessageHash());

        vm.startBroadcast(bundler);
        eps.ep().handleOps(ops, bundler);
        vm.stopBroadcast();

        require(Acc(userAccountAddress).number() == 2, "3 - Must have increased number twice");
        require(bundler.balance == initialDeposit - eps.ep().balanceOf(pmAddress), "4 - Must compensate bundler");
    }
}
