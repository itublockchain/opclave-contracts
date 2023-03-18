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

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external {
        _requireFromEntryPoint();
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /// @inheritdoc BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        override
        returns (uint256 validationData)
    {
        bool valid = Exec.staticcall(secp256r1, abi.encode(publicKey, userOpHash, userOp.signature), gasleft());
        validationData = _packValidationData(!valid, 0, 0);
    }

    /// @inheritdoc BaseAccount
    function _validateAndUpdateNonce(UserOperation calldata userOp) internal override {
        require(_nonce++ == userOp.nonce, "account: invalid nonce");
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }
}
