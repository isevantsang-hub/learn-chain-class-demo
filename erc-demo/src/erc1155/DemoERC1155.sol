// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC1155} from "@openzeppelin-contracts-5.6.0/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin-contracts-5.6.0/access/Ownable.sol";

/// @title DemoERC1155 — EIP-1155 多 id 余额（游戏道具 / 半同质化场景）
/// @dev id=1 金币（可大量持有），id=2 稀有卡（通常少量）
contract DemoERC1155 is ERC1155, Ownable {
  uint256 public constant ID_GOLD = 1;
  uint256 public constant ID_CARD = 2;

  constructor(address initialOwner) ERC1155("https://demo.example/api/{id}.json") Ownable(initialOwner) {}

  function mintGold(address to, uint256 amount) external onlyOwner {
    _mint(to, ID_GOLD, amount, "");
  }

  function mintCard(address to, uint256 amount) external onlyOwner {
    _mint(to, ID_CARD, amount, "");
  }

  function mintBatch(address to, uint256[] calldata ids, uint256[] calldata amounts) external onlyOwner {
    _mintBatch(to, ids, amounts, "");
  }
}
