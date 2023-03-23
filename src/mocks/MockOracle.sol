// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract MockOracle {
    function getTokenValueOfEth(uint256 ethOutput) external pure returns (uint256 tokenInput) {
        // 1 eth = 712 OP
        return ethOutput * 712;
    }
}
