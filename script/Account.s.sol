// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Script} from "forge-std/Script.sol";
import {Account as Acc} from "../src/Account.sol";

contract AccountScript is Script {
    Acc public account;
    address owner;

    function setUp() public {
        owner = vm.envAddress("ADDRESS");
    }

    function run() public {
        vm.startBroadcast(owner);

        account = new Acc(owner);

        vm.stopBroadcast();
    }
}
