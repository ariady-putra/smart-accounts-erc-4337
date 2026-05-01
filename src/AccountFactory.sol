// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
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
        bytes32 accountContractHash = keccak256(accountContract);

        // Guaranteed to deploy an address even when the improbable collision happens
        for (uint256 ownerSalt = uint160(owner); accountAddress == address(0); ownerSalt += type(uint160).max) {
            bytes32 salt = bytes32(ownerSalt);

            // Skip the current salt when the computed address has some code
            if (Create2.computeAddress(salt, accountContractHash).code.length > 0) continue;

            // Create2.deploy but without address(this).balance call
            assembly ("memory-safe") {
                accountAddress := create2(0, add(accountContract, 0x20), mload(accountContract), salt)
                // if no address was created, and returndata is not empty, bubble any revert thrown by the Account.constructor
                if and(iszero(accountAddress), not(iszero(returndatasize()))) {
                    let p := mload(0x40)
                    returndatacopy(p, 0, returndatasize())
                    revert(p, returndatasize())
                }
            }
        }

        // Cache the owner account address
        ownerAccounts[owner] = accountAddress;
    }
}
