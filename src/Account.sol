// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IAccount} from "@account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Account is Ownable, IAccount {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    uint256 public number;

    constructor(address owner) Ownable(owner) {}

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        (address recovered, ECDSA.RecoverError err,) = userOpHash.toEthSignedMessageHash().tryRecover(userOp.signature);
        if (err != ECDSA.RecoverError.NoError) return 1;
        if (owner() != recovered) return 1;

        validationData = 0;
    }

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
