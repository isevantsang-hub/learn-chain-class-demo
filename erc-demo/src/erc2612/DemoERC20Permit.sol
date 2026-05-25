// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin-contracts-5.6.0/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin-contracts-5.6.0/access/Ownable.sol";

/// @title DemoERC20Permit — EIP-20 + EIP-2612（permit 链下签名换 allowance）
/// @dev 依赖 EIP-712 域分隔符；OpenZeppelin 在构造时传入 name 用于 DOMAIN_SEPARATOR。
contract DemoERC20Permit is ERC20, ERC20Permit, Ownable {
  constructor(address initialOwner)
    ERC20("Demo Permit Token", "DPERM")
    ERC20Permit("Demo Permit Token")
    Ownable(initialOwner)
  {
    _mint(initialOwner, 1_000_000 * 10 ** 18);
  }

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }
}
