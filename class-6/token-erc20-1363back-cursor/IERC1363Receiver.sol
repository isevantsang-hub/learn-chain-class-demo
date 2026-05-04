// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @dev ERC1363 接收方接口：用于接收代币后执行回调逻辑。
interface IERC1363Receiver {
    /// @notice 代币合约在转账完成后调用该函数，接收方需返回固定 selector 表示接受。
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
}
