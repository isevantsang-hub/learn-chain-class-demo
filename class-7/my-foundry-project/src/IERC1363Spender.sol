// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev 授权后由代币合约调用的支出方回调（ERC1363 的 approveAndCall 路径）。
interface IERC1363Spender {
    function onApprovalReceived(address owner, uint256 value, bytes calldata data) external returns (bytes4);
}
