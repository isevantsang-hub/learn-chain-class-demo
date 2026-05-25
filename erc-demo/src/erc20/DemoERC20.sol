// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin-contracts-5.6.0/access/Ownable.sol";

/// @title DemoERC20 — EIP-20 教学代币（固定精度 18，owner 可增发）
/// @notice 生产环境应限制 mint、考虑暂停与升级策略；本合约仅用于理解 transfer / approve / allowance。
contract DemoERC20 is ERC20, Ownable {
  uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;

  constructor(address initialOwner) ERC20("Demo ERC20", "D20") Ownable(initialOwner) {
    _mint(initialOwner, INITIAL_SUPPLY);
  }

  function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
  }
}
