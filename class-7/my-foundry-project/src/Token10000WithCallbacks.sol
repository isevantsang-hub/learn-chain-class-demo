// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/ERC20.sol";
import {IERC1363} from "./IERC1363.sol";
import {IERC1363Receiver} from "./IERC1363Receiver.sol";
import {IERC1363Spender} from "./IERC1363Spender.sol";

/// @title 固定总量 10000 枚（18 小数）的 ERC20，带转账回调与授权回调（ERC1363 风格）。
contract Token10000WithCallbacks is ERC20, IERC1363 {
    uint256 public constant INITIAL_SUPPLY = 10_000 * 10 ** 18;

    constructor() ERC20("ClassTestToken", "CTT") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function transferAndCall(address to, uint256 value) external override returns (bool) {
        transferAndCall(to, value, "");
        return true;
    }

    function transferAndCall(address to, uint256 value, bytes memory data) public override returns (bool) {
        _transfer(_msgSender(), to, value);
        _checkOnTransferReceived(_msgSender(), _msgSender(), to, value, data);
        return true;
    }

    function transferFromAndCall(address from, address to, uint256 value, bytes memory data)
        external
        override
        returns (bool)
    {
        _spendAllowance(from, _msgSender(), value);
        _transfer(from, to, value);
        _checkOnTransferReceived(_msgSender(), from, to, value, data);
        return true;
    }

    function approveAndCall(address spender, uint256 value, bytes memory data) external override returns (bool) {
        _approve(_msgSender(), spender, value);
        _checkOnApprovalReceived(_msgSender(), spender, value, data);
        return true;
    }

    function _checkOnTransferReceived(address operator, address from, address to, uint256 value, bytes memory data)
        internal
    {
        require(to.code.length > 0, "ERC1363: transfer to non-contract");
        bytes4 retval = IERC1363Receiver(to).onTransferReceived(operator, from, value, data);
        require(retval == IERC1363Receiver.onTransferReceived.selector, "ERC1363: bad onTransferReceived");
    }

    function _checkOnApprovalReceived(address owner, address spender, uint256 value, bytes memory data) internal {
        require(spender.code.length > 0, "ERC1363: approve to non-contract");
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(owner, value, data);
        require(retval == IERC1363Spender.onApprovalReceived.selector, "ERC1363: bad onApprovalReceived");
    }
}
