// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev ERC1363 接口：在 ERC20 转账后触发目标合约回调。
interface IERC1363 is IERC20 {
    /// @notice 转账后调用接收方合约回调（无附加数据）。
    function transferAndCall(address to, uint256 value) external returns (bool);

    /// @notice 转账后调用接收方合约回调（携带附加数据）。
    function transferAndCall(address to, uint256 value, bytes memory data) external returns (bool);

    /// @notice 代扣转账后调用接收方合约回调（携带附加数据）。
    function transferFromAndCall(address from, address to, uint256 value, bytes memory data) external returns (bool);
}
