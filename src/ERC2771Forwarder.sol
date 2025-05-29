// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.3.0) (metatx/ERC2771Forwarder.sol)

pragma solidity ^0.8.20;

import { ERC2771Forwarder as ERC2771ForwarderBase } from "@openzeppelin/metatx/ERC2771Forwarder.sol";

error FailedCallWithMessage(bytes message);

contract ERC2771Forwarder is ERC2771ForwarderBase {

    /**
     * @dev See {EIP712-constructor}.
     */
    constructor(string memory name) ERC2771ForwarderBase(name) {}

    function validate(ForwardRequestData calldata request) public view returns (bool isTrustedForwarder, bool active, bool signerMatch) {
        (isTrustedForwarder, active, signerMatch, ) = _validate(request);
    }

    /**
     * @dev Executes a `request` on behalf of `signature`'s signer using the ERC-2771 protocol. The gas
     * provided to the requested call may not be exactly the amount requested, but the call will not run
     * out of gas. Will revert if the request is invalid or the call reverts, in this case the nonce is not consumed.
     *
     * Requirements:
     *
     * - The request value should be equal to the provided `msg.value`.
     * - The request should be valid according to {verify}.
     */
    function execute(ForwardRequestData calldata request) public payable virtual override {
        // We make sure that msg.value and request.value match exactly.
        // If the request is invalid or the call reverts, this whole function
        // will revert, ensuring value isn't stuck.
        if (msg.value != request.value) {
            revert ERC2771ForwarderMismatchedValue(request.value, msg.value);
        }

        (bool success, bytes memory revertMessage) = _executeWithMessage(request, true);
        if (!success) {
            revert FailedCallWithMessage(revertMessage);
        }
    }

    /**
     * @dev Validates and executes a signed request returning the request call `success` value.
     *
     * Internal function without msg.value validation.
     *
     * Requirements:
     *
     * - The caller must have provided enough gas to forward with the call.
     * - The request must be valid (see {verify}) if the `requireValidRequest` is true.
     *
     * Emits an {ExecutedForwardRequest} event.
     *
     * IMPORTANT: Using this function doesn't check that all the `msg.value` was sent, potentially
     * leaving value stuck in the contract.
     */
    function _executeWithMessage(
        ForwardRequestData calldata request,
        bool requireValidRequest
    ) internal virtual returns (bool success, bytes memory returnData) {
        (bool isTrustedForwarder, bool active, bool signerMatch, address signer) = _validate(request);

        // Need to explicitly specify if a revert is required since non-reverting is default for
        // batches and reversion is opt-in since it could be useful in some scenarios
        if (requireValidRequest) {
            if (!isTrustedForwarder) {
                revert ERC2771UntrustfulTarget(request.to, address(this));
            }

            if (!active) {
                revert ERC2771ForwarderExpiredRequest(request.deadline);
            }

            if (!signerMatch) {
                revert ERC2771ForwarderInvalidSigner(signer, request.from);
            }
        }

        // Ignore an invalid request because requireValidRequest = false
        if (isTrustedForwarder && signerMatch && active) {
            // Nonce should be used before the call to prevent reusing by reentrancy
            uint256 currentNonce = _useNonce(signer);

            uint256 reqGas = request.gas;
            address to = request.to;
            uint256 value = request.value;
            bytes memory data = abi.encodePacked(request.data, request.from);

            uint256 gasLeft;


            assembly ("memory-safe") {
                success := call(reqGas, to, value, add(data, 0x20), mload(data), 0, 0)
                if iszero(success) {
                    let size := returndatasize()
                    if gt(size, 0) {
                        // Allocate memory for returnData
                        mstore(returnData, size)
                        // Copy the revert message directly to returnData
                        returndatacopy(add(returnData, 0x20), 0, size)
                    }
                }
                gasLeft := gas()
            }

            _checkForwardedGasOverride(gasLeft, request);

            emit ExecutedForwardRequest(signer, currentNonce, success);
        }
    }

    function _checkForwardedGasOverride(uint256 gasLeft, ForwardRequestData calldata request) private pure {
        // To avoid insufficient gas griefing attacks, as referenced in https://ronan.eth.limo/blog/ethereum-gas-dangers/
        //
        // A malicious relayer can attempt to shrink the gas forwarded so that the underlying call reverts out-of-gas
        // but the forwarding itself still succeeds. In order to make sure that the subcall received sufficient gas,
        // we will inspect gasleft() after the forwarding.
        //
        // Let X be the gas available before the subcall, such that the subcall gets at most X * 63 / 64.
        // We can't know X after CALL dynamic costs, but we want it to be such that X * 63 / 64 >= req.gas.
        // Let Y be the gas used in the subcall. gasleft() measured immediately after the subcall will be gasleft() = X - Y.
        // If the subcall ran out of gas, then Y = X * 63 / 64 and gasleft() = X - Y = X / 64.
        // Under this assumption req.gas / 63 > gasleft() is true if and only if
        // req.gas / 63 > X / 64, or equivalently req.gas > X * 63 / 64.
        // This means that if the subcall runs out of gas we are able to detect that insufficient gas was passed.
        //
        // We will now also see that req.gas / 63 > gasleft() implies that req.gas >= X * 63 / 64.
        // The contract guarantees Y <= req.gas, thus gasleft() = X - Y >= X - req.gas.
        // -    req.gas / 63 > gasleft()
        // -    req.gas / 63 >= X - req.gas
        // -    req.gas >= X * 63 / 64
        // In other words if req.gas < X * 63 / 64 then req.gas / 63 <= gasleft(), thus if the relayer behaves honestly
        // the forwarding does not revert.
        if (gasLeft < request.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.20
            // https://docs.soliditylang.org/en/v0.8.20/control-structures.html#panic-via-assert-and-error-via-require
            assembly ("memory-safe") {
                invalid()
            }
        }
    }
}
