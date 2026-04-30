// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Test} from "forge-std/Test.sol";
import {AccountFactory} from "../src/AccountFactory.sol";

contract AccountFactoryTest is Test {
    AccountFactory public af;

    function setUp() public {
        af = new AccountFactory();
    }

    function testFuzz_Create2Account(address user) public {
        vm.assume(address(0) != user);

        assertEq(af.getAccountAddress(user), address(0));
        address userAccount = af.create2Account(user);
        assertEq(af.getAccountAddress(user), userAccount);

        assertGt(userAccount.code.length, 0);
    }
}
