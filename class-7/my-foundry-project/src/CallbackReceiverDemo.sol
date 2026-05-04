// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC1363Receiver} from "./IERC1363Receiver.sol";
import {IERC1363Spender} from "./IERC1363Spender.sol";
import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";

/// @dev 示例：可接收原生币；实现「转入代币回调」与「授权回调」，便于联调 Token10000WithCallbacks。
contract CallbackReceiverDemo is IERC1363Receiver, IERC1363Spender {
    event NativeReceived(address indexed from, uint256 amount);
    event TransferCallback(address indexed operator, address indexed from, uint256 value, bytes data);
    event ApprovalCallback(address indexed owner, uint256 value, bytes data);

    receive() external payable {
        emit NativeReceived(msg.sender, msg.value);
    }

    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        emit TransferCallback(operator, from, value, data);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    function onApprovalReceived(address owner, uint256 value, bytes calldata data) external override returns (bytes4) {
        emit ApprovalCallback(owner, value, data);
        return IERC1363Spender.onApprovalReceived.selector;
    }

    /// @dev 授权回调里常用：在已知代币地址时从 owner 代扣（需事先 approveAndCall 已设好 allowance）。
    function pullFrom(address token, address owner, uint256 amount) external {
        require(IERC20(token).transferFrom(owner, address(this), amount), "pullFrom failed");
    }
}
