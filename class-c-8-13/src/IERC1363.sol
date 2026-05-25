// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";

interface IERC1363 is IERC20 {
    function transferAndCall(address to, uint256 value) external returns (bool);
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}
