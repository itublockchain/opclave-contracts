// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./base-contracts/BaseAccount.sol";

contract BioAccount is BaseAccount {
    IEntryPoint internal immutable _entryPoint;
    address internal constant secp256r1 = address(0x1773);
    uint256 private _nonce;
    bytes public publicKey;
    uint256 public InactiveTimeLimit;
    uint256 public lastActiveTime;
    address public inheritor;

    modifier updateLastActive() {
        _;
        lastActiveTime = block.timestamp;
    }

    constructor(address _entryPointAddress, bytes memory _publicKey) {
        _entryPoint = IEntryPoint(_entryPointAddress);
        publicKey = _publicKey;
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
     * execute a transaction (called directly by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external updateLastActive {
        _requireFromEntryPoint();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external updateLastActive {
        _requireFromEntryPoint();
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    function setPublicKey(bytes calldata _publicKey) external updateLastActive {
        _requireFromEntryPoint();
        publicKey = _publicKey;
    }

    function setInactiveTimeLimit(uint256 _InactiveTimeLimit) external updateLastActive {
        _requireFromEntryPoint();
        InactiveTimeLimit = _InactiveTimeLimit;
    }

    function setInheritor(address _inheritor) external updateLastActive {
        _requireFromEntryPoint();
        inheritor = _inheritor;
    }

    function inherit() external {
        require(inheritor == msg.sender, "not inheritor");
        require(block.timestamp - lastActiveTime > InactiveTimeLimit, "not inactive");
        payable(inheritor).transfer(address(this).balance);
    }

    /// @inheritdoc BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        override
        returns (uint256 validationData)
    {
        address _secp256r1 = secp256r1;
        bytes memory _publicKey = publicKey;
        bytes memory _signature = userOp.signature;

        bool valid;
        assembly {
            let ptr := mload(0x40)

            mstore(ptr, add(_publicKey, 0x20))
            mstore(add(ptr, 0x21), userOpHash)
            mstore(add(ptr, 0x41), _signature)

            if iszero(staticcall(gas(), _secp256r1, ptr, 0x61, ptr, 0x20)) { revert(0, 0) }

            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            valid := byte(size, mload(ptr))
        }
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
