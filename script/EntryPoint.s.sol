// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";

contract EntryPointScript is Script {
    EntryPoint public ep;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        ep = new EntryPoint();

        vm.stopBroadcast();

        address epAddress = address(ep);
        console.log("EP deployed to", epAddress);
        // console.logBytes(epAddress.code);
        console.log("Code size:", epAddress.code.length);
    }
}
