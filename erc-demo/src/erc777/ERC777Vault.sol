// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC777Recipient} from "./IERC777.sol";
import {IERC1820RegistryMinimal} from "./IERC1820RegistryMinimal.sol";

/// @title ERC777Vault — 实现 tokensReceived，演示 777 转入回调
contract ERC777Vault is IERC777Recipient {
  IERC1820RegistryMinimal private immutable ERC1820;

  bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
    keccak256("ERC777TokensRecipient");

  uint256 public totalReceived;
  address public lastSender;

  constructor(address erc1820Registry) {
    ERC1820 = IERC1820RegistryMinimal(erc1820Registry);
    ERC1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
  }

  function tokensReceived(
    address,
    address from,
    address,
    uint256 amount,
    bytes calldata,
    bytes calldata
  ) external override {
    totalReceived += amount;
    lastSender = from;
  }
}
