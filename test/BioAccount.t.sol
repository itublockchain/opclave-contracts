// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/entrypoint/EntryPoint.sol";
import "../src/BioAccount.sol";

contract BioAccountTest is Test {
    EntryPoint entryPoint;
    BioAccount account;
    address precompile = address(0x1773);
    bytes publicKey = hex"03acdd696a4c5b603f7115db9baa5fc58b14fb2fa133b9c1f472465e4718bfb98d";

    UserOperation userOpNoCdNoPm = UserOperation({
        sender: 0x2e234DAe75C793f67A35089C9d99245E1C58470b,
        nonce: 0,
        initCode: "0x",
        callData: "0x",
        callGasLimit: 1000000,
        verificationGasLimit: 1000000,
        preVerificationGas: 1000000,
        maxFeePerGas: 0,
        maxPriorityFeePerGas: 0,
        paymasterAndData: "0x",
        signature: hex"00304502200f62a197ceb328bfcacc42d4118e19823a1f281e3ff2eda1c87f2464437cc3b3022100bbcda922818ba7ee43369a71db1b9c53a5981bff39300aded68ba51b99ced6dc"
    });
    bytes32 noCdNoPmHash = hex"62fe8625fd33bd7f48ca4561fed3c80d5d82e6c41ef0f0122d594b35924bf04e";

    function setUp() public {
        entryPoint = new EntryPoint();
        account = new BioAccount(address(entryPoint), publicKey);
    }

    function testPrecompile() public {
        bytes memory _publicKey = publicKey;
        bytes memory _signature = userOpNoCdNoPm.signature;
        bytes32 _userOpHash = noCdNoPmHash;
        address _secp256r1 = precompile;

        bool valid;
        assembly {
            let ptr := add(mload(0x40), 0x80)
            mstore(ptr, mload(add(_publicKey, 0x20)))
            mstore8(add(ptr, 0x20), mload(add(_publicKey, 0x21)))
            mstore(add(ptr, 0x21), _userOpHash)
            mstore(add(ptr, 0x41), mload(add(_signature, 0x20)))
            mstore(add(ptr, 0x59), mload(add(_signature, 0x38)))
            mstore(add(ptr, 0x71), mload(add(_signature, 0x50)))

            if iszero(staticcall(gas(), _secp256r1, ptr, 0x89, 0x00, 0x20)) { revert(0, 0) }

            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            valid := mload(ptr)
        }

        assertTrue(valid);
    }
}
