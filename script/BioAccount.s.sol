// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/entrypoint/EntryPoint.sol";
import "../src/BioAccount.sol";
import "../src/OraclePaymaster.sol";
import "../src/mocks/MockOracle.sol";
import "../src/mocks/MockERC20.sol";

contract BioAccountScript is Script {
    EntryPoint entryPoint = EntryPoint(payable(0x7C2641de9b8ECED9C3796B0bf99Ead1BeD5407A5));
    BioAccount account = BioAccount(payable(0x5154de6CC9bb544a1A12079018F628eF63456574));
    OraclePaymaster paymaster = OraclePaymaster(payable(0x0bb7B5e7E3B7Da3D45fEa583E467D1c4944D7A1f));
    MockOracle oracle = MockOracle(payable(0x9a85Ea933df5962F0FcbB94b863ACf5960592AAf));
    MockERC20 optimismToken = MockERC20(payable(0xBB3E66eE258ef9Cc7b4e5d84F765071658A5215D));

    address precompile = address(0x1773);
    address hamza = 0x9Ce372F4781BEC015A740044a790a296aF1573fC;
    bytes publicKey = hex"03acdd696a4c5b603f7115db9baa5fc58b14fb2fa133b9c1f472465e4718bfb98d";
    bytes initCode = "0x0000000000FFe8B47B3e2130213B802212439497";

    UserOperation userOpApprovePaymaster = UserOperation({
        sender: 0x5154de6CC9bb544a1A12079018F628eF63456574,
        nonce: 4,
        initCode: "",
        callData: hex"b61d27f6000000000000000000000000bb3e66ee258ef9cc7b4e5d84f765071658a5215d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044095ea7b30000000000000000000000000bb7b5e7e3b7da3d45fea583e467d1c4944d7a1f00000000000000000000000000000000000004ee2d6d415b85acef810000000000000000000000000000000000000000000000000000000000000000",
        callGasLimit: 100000,
        verificationGasLimit: 100000,
        preVerificationGas: 100000,
        maxFeePerGas: 4,
        maxPriorityFeePerGas: 2,
        paymasterAndData: "",
        signature: hex"00304502200f62a197ceb328bfcacc42d4118e19823a1f281e3ff2eda1c87f2464437cc3b3022100bbcda922818ba7ee43369a71db1b9c53a5981bff39300aded68ba51b99ced6dc"
    });

    UserOperation userOpSendTokens = UserOperation({
        sender: 0x5154de6CC9bb544a1A12079018F628eF63456574,
        nonce: 4,
        initCode: "",
        callData: hex"b61d27f6000000000000000000000000bb3e66ee258ef9cc7b4e5d84f765071658a5215d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000044a9059cbb0000000000000000000000009ce372f4781bec015a740044a790a296af1573fc0000000000000000000000000000000000000000000000008ac7230489e8000000000000000000000000000000000000000000000000000000000000",
        callGasLimit: 50000,
        verificationGasLimit: 50000,
        preVerificationGas: 50000,
        maxFeePerGas: 5,
        maxPriorityFeePerGas: 5,
        paymasterAndData: hex"0bb7B5e7E3B7Da3D45fEa583E467D1c4944D7A1f",
        signature: hex"00304502200f62a197ceb328bfcacc42d4118e19823a1f281e3ff2eda1c87f2464437cc3b3022100bbcda922818ba7ee43369a71db1b9c53a5981bff39300aded68ba51b99ced6dc"
    });

    function deploy() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        entryPoint = new EntryPoint();
        account = new BioAccount(address(entryPoint), publicKey);
        optimismToken = new MockERC20("Optimism Token", "OP");
        oracle = new MockOracle();
        paymaster = new OraclePaymaster(address(entryPoint), address(oracle), address(optimismToken));

        vm.stopBroadcast();
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        //optimismToken.mint(address(account), 1000 ether);
        //paymaster.deposit{value: 1 ether}();
        UserOperation[] memory userOps0 = new UserOperation[](1);
        UserOperation[] memory userOps1 = new UserOperation[](1);
        userOps0[0] = userOpApprovePaymaster;
        userOps1[0] = userOpSendTokens;
        //entryPoint.handleOps(userOps0, payable(address(1)));
        entryPoint.handleOps(userOps1, payable(address(1)));

        vm.stopBroadcast();
    }
}
