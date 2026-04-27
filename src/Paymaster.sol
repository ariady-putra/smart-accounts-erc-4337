// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import {IPaymaster} from "@account-abstraction/contracts/interfaces/IPaymaster.sol";
import {PackedUserOperation} from "@account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract Paymaster is IPaymaster {
    function validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        external
        returns (bytes memory context, uint256 validationData)
    {
        context = ""; // Value to send to a `postOp`. Zero length to signify `postOp` is not required
        validationData = 0; // Signature and time-range of this operation, encoded the same as the return
        //                     value of `validateUserOperation`
        //                     <20-byte> aggregatorOrSigFail - 0 for valid signature, 1 to mark signature failure,
        //                               other values are invalid for paymaster.
        //                     <6-byte> validUntil - Last timestamp this operation is valid at, or 0 for "indefinitely"
        //                     <6-byte> validAfter - first timestamp this operation is valid
        //
        //                     NOTE: The validation code cannot use `block.timestamp` (or `block.number`) directly
    }

    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost, uint256 actualUserOpFeePerGas)
        external {}
}
