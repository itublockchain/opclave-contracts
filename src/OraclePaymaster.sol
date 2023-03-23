// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

import "./base-contracts/BasePaymaster.sol";

interface IOracle {
    function getTokenValueOfEth(uint256 ethOutput) external view returns (uint256 tokenInput);
}

contract OraclePaymaster is BasePaymaster {
    using UserOperationLib for UserOperation;
    using SafeERC20 for IERC20;

    //calculated cost of the postOp
    uint256 public constant COST_OF_POST = 35000;

    IOracle public oracle;
    IERC20 public optimismToken;

    constructor(address _entryPointAddress, address oracleAddress, address opTokenAddress)
        BasePaymaster(IEntryPoint(_entryPointAddress))
    {
        oracle = IOracle(oracleAddress);
        optimismToken = IERC20(opTokenAddress);
    }

    function _validatePaymasterUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        internal
        view
        override
        returns (bytes memory context, uint256 validationData)
    {
        (userOpHash); // unused param
        address account = userOp.getSender();
        uint256 gasPriceUserOp = userOp.gasPrice();
        uint256 maxTokenCost = getTokenValueOfEth(maxCost);
        uint256 approvedAmount = optimismToken.allowance(address(this), account);
        require(approvedAmount >= maxTokenCost, "Not enough approved tokens");
        return (abi.encode(account, gasPriceUserOp, maxTokenCost, maxCost), 0);
    }

    function _postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost) internal override {
        (mode); // unused param
        (address account, uint256 gasPricePostOp, uint256 maxTokenCost, uint256 maxCost) =
            abi.decode(context, (address, uint256, uint256, uint256));

        uint256 actualTokenCost = (actualGasCost + COST_OF_POST * gasPricePostOp) * maxTokenCost / maxCost;
        optimismToken.safeTransferFrom(account, address(this), actualTokenCost);
    }

    function getTokenValueOfEth(uint256 ethBought) internal view returns (uint256 tokenInput) {
        return oracle.getTokenValueOfEth(ethBought);
    }
}
