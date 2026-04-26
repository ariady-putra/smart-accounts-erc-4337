// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {EntryPointScript} from "./EntryPoint.s.sol";
import {AccountFactoryScript} from "./AccountFactory.s.sol";
import {Account as Acc} from "../src/Account.sol";

contract DeployScript is Script {
    EntryPointScript public eps;
    AccountFactoryScript public afs;

    address payable user;

    function setUp() public {
        user = payable(vm.promptAddress("User address"));

        eps = new EntryPointScript();
        afs = new AccountFactoryScript();
    }

    function run() public {
        eps.run();
        afs.run();

        // Below code is to test EntryPoint and AccountFactory:

        address epAddress = address(eps.ep());
        address afAddress = address(afs.af());

        address userAccountAddress = vm.computeCreateAddress(afAddress, afs.af().nonces(afAddress)); // address(userAccount)
        bytes memory createUserAccount = abi.encodeWithSelector(afs.af().createAccount.selector, user); // AccountFactory.createAccount(user)
        bytes memory incrementUserAccount = abi.encodeWithSelector(Acc.increment.selector); // Account(userAccountAddress).increment()

        uint128 callGasLimit = 2_000_000;
        uint128 verificationGasLimit = 2_000_000;
        uint128 maxFeePerGas = 10 gwei;
        uint128 maxPriorityFeePerGas = 5 gwei;

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = PackedUserOperation({
            sender: userAccountAddress,
            nonce: eps.ep().getNonce(userAccountAddress, 0),
            initCode: abi.encodePacked(afAddress, createUserAccount),
            callData: incrementUserAccount,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: 50_000,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: "",
            signature: ""
        });

        vm.deal(user, 2 ether); // test only
        vm.startBroadcast(user);
        if (eps.ep().balanceOf(userAccountAddress) == 0) {
            eps.ep().depositTo{value: user.balance}(userAccountAddress);
        }
        eps.ep().handleOps(ops, user);
        vm.stopBroadcast();

        assert(Acc(userAccountAddress).number() == 1); // increased number once

        // Test call user account again (increment), now we do not set the initCode:

        ops[0] = PackedUserOperation({
            sender: userAccountAddress,
            nonce: eps.ep().getNonce(userAccountAddress, 0),
            initCode: "", // abi.encodePacked(afAddress, createUserAccount), // user account has been created
            callData: incrementUserAccount,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: 50_000,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: "",
            signature: ""
        });

        vm.startBroadcast(user);
        eps.ep().handleOps(ops, user);
        vm.stopBroadcast();

        assert(Acc(userAccountAddress).number() == 2); // increased number twice
    }
}
