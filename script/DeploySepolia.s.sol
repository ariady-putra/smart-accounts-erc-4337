// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {console} from "forge-std/console.sol";
import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "@account-abstraction/contracts/core/EntryPoint.sol";
import {PaymasterScript} from "./Paymaster.s.sol";
import {AccountFactoryScript} from "./AccountFactory.s.sol";

contract DeploySepoliaScript is Script {
    PaymasterScript public pms;
    AccountFactoryScript public afs;

    EntryPoint ep;
    address payable epV09 = payable(0x433709009B8330FDa32311DF1C2AFA402eD8D009); // https://github.com/eth-infinitism/account-abstraction/releases
    address sponsor;

    function setUp() public {
        sponsor = vm.envAddress("ADDRESS");

        ep = EntryPoint(epV09);
        pms = new PaymasterScript();
        afs = new AccountFactoryScript();
    }

    function run() public {
        pms.run();
        afs.run();

        address pmAddress = address(pms.pm());

        vm.startBroadcast(sponsor);

        if (ep.balanceOf(pmAddress) == 0) {
            ep.depositTo{value: 0.2 ether}(pmAddress);
            console.log("Deposit ETH 0.2 to EP for PM account");
        }

        vm.stopBroadcast();
    }
}
