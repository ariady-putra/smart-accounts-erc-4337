// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {Account as Acc} from "./Account.sol";

contract AccountFactory is Nonces {
    address immutable self = address(this);

    //      Owner      Account
    mapping(address => address) ownerAccounts;

    constructor() {
        _useNonce(self); // start nonce at 1
    }

    function getAccountAddress(address owner) external view returns (address) {
        return ownerAccounts[owner];
    }

    function createAccount(address owner) external returns (address accountAddress) {
        _useNonce(self);

        Acc account = new Acc(owner);
        accountAddress = address(account);
    }

    function create2Account(address owner) external returns (address accountAddress) {
        // Check if the owner's accountAddress has already been deployed
        accountAddress = ownerAccounts[owner];
        if (address(0) != accountAddress) return accountAddress;

        bytes memory accountContract = abi.encodePacked(type(Acc).creationCode, abi.encode(owner)); // Account.constructor

        // Prevent an astronomically improbable scenario where a legitimate user generates the computed CREATE2 address of address(0)
        // Max 2 iterations (if the first iteration generates address(0), then the next one should not - collision resistance)
        for (uint256 ownerSalt = uint160(owner); accountAddress == address(0); ownerSalt += type(uint160).max) {
            bytes32 salt = bytes32(ownerSalt);

            // @openzeppelin/contracts/utils/Create2.deploy but without address(this).balance call
            assembly ("memory-safe") {
                accountAddress := create2(0, add(accountContract, 0x20), mload(accountContract), salt)
                // if no address was created, and returndata is not empty, bubble any revert thrown by the Account.constructor
                if and(iszero(accountAddress), not(iszero(returndatasize()))) {
                    let p := mload(0x40)
                    returndatacopy(p, 0, returndatasize())
                    revert(p, returndatasize())
                }
            }

            // Cache owner account
            if (address(0) != accountAddress) ownerAccounts[owner] = accountAddress;
        }
    }
}
