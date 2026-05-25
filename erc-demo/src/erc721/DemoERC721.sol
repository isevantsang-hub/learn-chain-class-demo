// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin-contracts-5.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin-contracts-5.6.0/access/Ownable.sol";

/// @title DemoERC721 — 最小 ERC-721 教学合约（无商业锁定）
/// @notice 仅用于对比学习标准 721；全功能商业逻辑请使用 CommercialNFT + Hub。
contract DemoERC721 is ERC721, ERC721URIStorage, Ownable {
  /// @dev 下一枚 tokenId
  uint256 private _nextId;

  /// @notice 部署并指定 owner（仅 owner 可 mint）
  /// @param initialOwner 管理员地址
  constructor(address initialOwner) ERC721("Demo ERC721", "D721") Ownable(initialOwner) {}

  /// @notice 铸造一枚 NFT
  /// @param to 接收地址
  /// @param uri metadata URI
  /// @return tokenId 新编号
  function mint(address to, string calldata uri) external onlyOwner returns (uint256 tokenId) {
    tokenId = _nextId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  /// @notice 查询 metadata URI
  /// @param tokenId NFT 编号
  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  /// @notice ERC-165 接口支持查询
  /// @param interfaceId 接口 id
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}
