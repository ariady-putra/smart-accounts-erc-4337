// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {Paymaster} from "../src/Paymaster.sol";

contract PaymasterScript is Script {
    Paymaster public pm;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        pm = new Paymaster();

        vm.stopBroadcast();

        address pmAddress = address(pm);
        console.log("PM deployed to", pmAddress);
        // console.logBytes(pmAddress.code);
        console.log("Code size:", pmAddress.code.length);
    }
}
