// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {AccountFactory} from "../src/AccountFactory.sol";

contract AccountFactoryScript is Script {
    AccountFactory public af;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        af = new AccountFactory();

        vm.stopBroadcast();

        address afAddress = address(af);
        console.log("AF deployed to", afAddress);
        // console.logBytes(afAddress.code);
        console.log("Code size:", afAddress.code.length);
    }
}
