// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./BaseAccount.sol";
import {Exec} from "./utils/Exec.sol";

contract BioAccount is BaseAccount {
    IEntryPoint internal immutable _entryPoint;
    bytes internal constant publicKey = "0x038eb6366f309b6bc7c76255196395e8617c72632d3690c55f";
    address internal constant secp256r1 = address(0x1773);
    uint256 private _nonce;

    constructor(address _entryPointAddress) {
        _entryPoint = IEntryPoint(_entryPointAddress);
    }

    receive() external payable {}

    /// @inheritdoc BaseAccount
    function nonce() public view virtual override returns (uint256) {
        return _nonce;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    /// @inheritdoc BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        override
        returns (uint256 validationData)
    {
        bool valid = Exec.staticcall(secp256r1, abi.encode(publicKey, userOpHash, userOp.signature), gasleft());
        validationData = _packValidationData(valid, 0, 0);
    }

    /// @inheritdoc BaseAccount
    function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {}
}
