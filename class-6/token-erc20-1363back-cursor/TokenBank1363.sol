// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC1363Receiver.sol";

/// @title ERC1363 回调存款银行
/// @dev 用户通过 transferAndCall 把代币转入本合约后记账，可按余额提取。
contract TokenBank1363 is IERC1363Receiver {
    // 仅接受这一种指定代币。
    IERC20 public immutable token;
    // 用户地址 => 存款余额。
    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "TokenBank: zero token");
        token = IERC20(tokenAddress);
    }

    function onTransferReceived(address , address from, uint256 value, bytes calldata)
        external
        override
        returns (bytes4)
    {
        // 只接受指定 token 合约触发的回调。
        require(msg.sender == address(token), "TokenBank: unsupported token");
        require(from != address(0), "TokenBank: zero from");
        require(value > 0, "TokenBank: zero value");

        // 记账并发出存款事件。
        deposits[from] += value;
        emit Deposited(from, value);

        // 按 ERC1363 规范返回固定 selector。
        return IERC1363Receiver.onTransferReceived.selector;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "TokenBank: zero amount");
        require(deposits[msg.sender] >= amount, "TokenBank: insufficient");

        // 先更新内部余额再转账，降低重入风险。
        deposits[msg.sender] -= amount;
        bool ok = token.transfer(msg.sender, amount);
        require(ok, "TokenBank: transfer failed");

        emit Withdrawn(msg.sender, amount);
    }
}
