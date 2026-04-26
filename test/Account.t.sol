// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {Account as Acc} from "../src/Account.sol";

contract AccountTest is Test {
    Acc public account;
    address owner = address(this);

    function setUp() public {
        account = new Acc(owner);
        account.setNumber(0);
    }

    function test_Increment() public {
        account.increment();
        assertEq(account.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        account.setNumber(x);
        assertEq(account.number(), x);
    }
}
