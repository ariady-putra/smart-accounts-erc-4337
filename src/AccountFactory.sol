// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Account as Acc} from "./Account.sol";

contract AccountFactory is Nonces {
    address immutable self = address(this);

    constructor() {
        _useNonce(self); // start nonce at 1
    }

    function createAccount(address owner) external returns (address accountAddress) {
        _useNonce(self);

        Acc account = new Acc(owner);
        accountAddress = address(account);
    }
}
