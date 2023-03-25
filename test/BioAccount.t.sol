// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/entrypoint/EntryPoint.sol";
import "../src/BioAccount.sol";
import "../src/OraclePaymaster.sol";
import "../src/mocks/MockOracle.sol";
import "../src/mocks/MockERC20.sol";

contract BioAccountTest is Test {
    EntryPoint entryPoint;
    BioAccount account;
    MockERC20 optimismToken;
    MockOracle oracle;
    OraclePaymaster paymaster;

    address precompile = address(0x1773);
    bytes publicKey = hex"03acdd696a4c5b603f7115db9baa5fc58b14fb2fa133b9c1f472465e4718bfb98d";
    bytes32 userOpHash = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

    UserOperation userOpNoCdNoPm = UserOperation({
        sender: 0x2e234DAe75C793f67A35089C9d99245E1C58470b,
        nonce: 0,
        initCode: "",
        callData: "",
        callGasLimit: 1000000,
        verificationGasLimit: 1000000,
        preVerificationGas: 1000000,
        maxFeePerGas: 0,
        maxPriorityFeePerGas: 0,
        paymasterAndData: "",
        signature: hex"00304502200f62a197ceb328bfcacc42d4118e19823a1f281e3ff2eda1c87f2464437cc3b3022100bbcda922818ba7ee43369a71db1b9c53a5981bff39300aded68ba51b99ced6dc"
    });

    UserOperation userOpPm = UserOperation({
        sender: 0x2e234DAe75C793f67A35089C9d99245E1C58470b,
        nonce: 0,
        initCode: "",
        callData: "",
        callGasLimit: 1000000,
        verificationGasLimit: 1000000,
        preVerificationGas: 1000000,
        maxFeePerGas: 10,
        maxPriorityFeePerGas: 10,
        paymasterAndData: hex"c7183455a4C133Ae270771860664b6B7ec320bB1",
        signature: hex"00304502200f62a197ceb328bfcacc42d4118e19823a1f281e3ff2eda1c87f2464437cc3b3022100bbcda922818ba7ee43369a71db1b9c53a5981bff39300aded68ba51b99ced6dc"
    });

    UserOperation userOpApprovePaymaster = UserOperation({
        sender: 0x2e234DAe75C793f67A35089C9d99245E1C58470b,
        nonce: 0,
        initCode: "",
        callData: hex"b61d27f6000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044095ea7b3000000000000000000000000c7183455a4c133ae270771860664b6b7ec320bb1000000000000009f4f2726179a224501d762422c946590d9100000000000000000000000000000000000000000000000000000000000000000000000",
        callGasLimit: 1000000,
        verificationGasLimit: 1000000,
        preVerificationGas: 1000000,
        maxFeePerGas: 0,
        maxPriorityFeePerGas: 0,
        paymasterAndData: hex"",
        signature: hex"00304502200f62a197ceb328bfcacc42d4118e19823a1f281e3ff2eda1c87f2464437cc3b3022100bbcda922818ba7ee43369a71db1b9c53a5981bff39300aded68ba51b99ced6dc"
    });

    UserOperation userOpSendTokens = UserOperation({
        sender: 0x2e234DAe75C793f67A35089C9d99245E1C58470b,
        nonce: 1,
        initCode: "",
        callData: hex"b61d27f6000000000000000000000000f62849f9a0b5bf2913b396098f7c7019b51a820a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044a9059cbb0000000000000000000000005991a2df15a8f6a256d3ec51e99254cd3fb576a90000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000",
        callGasLimit: 1000000,
        verificationGasLimit: 1000000,
        preVerificationGas: 1000000,
        maxFeePerGas: 10,
        maxPriorityFeePerGas: 10,
        paymasterAndData: hex"c7183455a4C133Ae270771860664b6B7ec320bB1",
        signature: hex"00304502200f62a197ceb328bfcacc42d4118e19823a1f281e3ff2eda1c87f2464437cc3b3022100bbcda922818ba7ee43369a71db1b9c53a5981bff39300aded68ba51b99ced6dc"
    });

    function setUp() public {
        entryPoint = new EntryPoint();
        account = new BioAccount(address(entryPoint), publicKey);
        optimismToken = new MockERC20("Optimism Token", "OP");
        oracle = new MockOracle();
        paymaster = new OraclePaymaster(address(entryPoint), address(oracle), address(optimismToken));

        optimismToken.mint(address(account), 100 ether);
        vm.deal(address(paymaster), 100 ether);
        payable(precompile).transfer(0.1 ether);
    }

    // function testPrecompile() public {
    //     bytes memory _publicKey = publicKey;
    //     bytes memory _signature = userOpNoCdNoPm.signature;
    //     bytes32 _userOpHash = userOpHash;
    //     address _secp256r1 = precompile;

    //     bool valid;
    //     assembly {
    //         let ptr := add(mload(0x40), 0x80)
    //         mstore(ptr, mload(add(_publicKey, 0x20)))
    //         mstore8(add(ptr, 0x20), mload(add(_publicKey, 0x21)))
    //         mstore(add(ptr, 0x21), _userOpHash)
    //         mstore(add(ptr, 0x41), mload(add(_signature, 0x20)))
    //         mstore(add(ptr, 0x59), mload(add(_signature, 0x38)))
    //         mstore(add(ptr, 0x71), mload(add(_signature, 0x50)))

    //         if iszero(staticcall(gas(), _secp256r1, ptr, 0x89, 0x00, 0x20)) { revert(0, 0) }

    //         let size := returndatasize()
    //         returndatacopy(ptr, 0, size)
    //         valid := mload(ptr)
    //     }

    //     assertTrue(valid);
    // }

    // function testNoCdNoPm() public {
    //     UserOperation[] memory userOps = new UserOperation[](1);
    //     userOps[0] = userOpNoCdNoPm;
    //     entryPoint.handleOps(userOps, payable(address(this)));
    // }

    // function testPaymaster() public {
    //     vm.prank(address(account));
    //     optimismToken.approve(address(paymaster), 10 ether);
    //     vm.prank(address(paymaster));
    //     paymaster.deposit{value: 5 ether}();
    //     UserOperation[] memory userOps = new UserOperation[](1);
    //     userOps[0] = userOpPm;
    //     entryPoint.handleOps(userOps, payable(address(this)));
    // }

    function testSendTokens() public {
        vm.prank(address(paymaster));
        paymaster.deposit{value: 50 ether}();
        UserOperation[] memory userOps0 = new UserOperation[](1);
        UserOperation[] memory userOps1 = new UserOperation[](1);
        userOps0[0] = userOpApprovePaymaster;
        userOps1[0] = userOpSendTokens;
        entryPoint.handleOps(userOps0, payable(address(this)));
        entryPoint.handleOps(userOps1, payable(address(this)));
    }

    receive() external payable {
        console2.log("Received ETH: %s", msg.value);
    }
}
