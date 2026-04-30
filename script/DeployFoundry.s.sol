// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EntryPointScript} from "./EntryPoint.s.sol";
import {PaymasterScript} from "./Paymaster.s.sol";
import {AccountFactoryScript} from "./AccountFactory.s.sol";

contract DeployFoundryScript is Script {
    EntryPointScript public eps;
    PaymasterScript public pms;
    AccountFactoryScript public afs;

    address sponsor;

    function setUp() public {
        sponsor = vm.envAddress("ADDRESS");

        eps = new EntryPointScript();
        pms = new PaymasterScript();
        afs = new AccountFactoryScript();
    }

    function run() public {
        eps.run();
        pms.run();
        afs.run();

        address pmAddress = address(pms.pm());

        vm.startBroadcast(sponsor);

        if (eps.ep().balanceOf(pmAddress) == 0) {
            eps.ep().depositTo{value: 2000 ether}(pmAddress);
            console.log("Deposit ETH 2000 to EP for PM account");
        }

        vm.stopBroadcast();
    }
}
