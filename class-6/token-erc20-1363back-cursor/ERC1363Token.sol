// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC1363.sol";
import "./IERC1363Receiver.sol";

/// @title ERC1363 示例代币
/// @dev 在标准 ERC20 基础上支持 transferAndCall 回调。
contract ERC1363Token is ERC20, IERC1363 {
    // 初始化铸造总量：2,100 万枚（18 位精度）。
    uint256 public constant INITIAL_SUPPLY = 21_000_000 * 10 ** 18;

    constructor() ERC20("CallbackToken", "CBT") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transferAndCall(address to, uint256 value) external override returns (bool) {
        // 复用带 data 的版本，默认传空字节。
        transferAndCall(to, value , "");
        return true;
    }

    function transferAndCall(address to, uint256 value, bytes memory data) public override returns (bool) {
        // 先完成 ERC20 转账，再通知接收方合约。
        _transfer(_msgSender(), to, value);
        _checkOnTransferReceived(_msgSender(), _msgSender(), to, value, data);
        return true;
    }

    function transferFromAndCall(address from, address to, uint256 value, bytes memory data)
        external
        override
        returns (bool)
    {
        // 先消耗授权，再执行转账并触发回调。
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value);
        _checkOnTransferReceived(_msgSender(), from, to, value, data);
        return true;
    }

    function _checkOnTransferReceived(address operator, address from, address to, uint256 value, bytes memory data)
        internal
    {
        // ERC1363 要求接收方必须是合约地址。
        require(to.code.length > 0, "ERC1363: receiver is not a contract");
        bytes4 retval = IERC1363Receiver(to).onTransferReceived(operator, from, value, data);
        // 只有返回预期 selector 才视为接收成功。
        require(retval == IERC1363Receiver.onTransferReceived.selector, "ERC1363: invalid receiver return");
    }
}