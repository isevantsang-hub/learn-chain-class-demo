// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev 代币转入后由代币合约调用的接收方回调（ERC1363 风格）。
interface IERC1363Receiver {
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}
