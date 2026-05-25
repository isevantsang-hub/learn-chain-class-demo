// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MerkleProof} from "@openzeppelin-contracts-5.6.0/utils/cryptography/MerkleProof.sol";
import {IERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/IERC721.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {NFTCommerceBase} from "./NFTCommerceBase.sol";

/// @title NFTAirdrop — NFT 空投分发模块
/// @notice 运营将 NFT 放入空投池；领取人凭 Merkle 证明领取（须 ROLE_AIRDROP_CLAIMER）。
contract NFTAirdrop is NFTCommerceBase {
  /// @dev Merkle 树根（运营通过 Hub setMerkleRoot 设置）
  bytes32 public merkleRoot;

  /// @dev tokenId 是否在空投池中
  mapping(uint256 => bool) public tokenInPool;

  /// @dev 某地址是否已领取过（本实现：每地址仅可 claim 一次）
  mapping(address => bool) public claimed;

  event PoolAdded(uint256 indexed tokenId);
  event RootUpdated(bytes32 root);
  event Claimed(uint256 indexed tokenId, address indexed claimer);

  /// @inheritdoc INFTCommerceModule
  function lockType() external pure override returns (ICommercialNFT.LockType) {
    return ICommercialNFT.LockType.Airdrop;
  }

  /// @notice Hub 将已在合约内的 NFT 标记为可领取（须 owner 为本合约）
  /// @param tokenId NFT 编号
  function addToPool(uint256 tokenId) external onlyHub nonReentrant {
    require(commercialNFT.ownerOfToken(tokenId) == address(this), "airdrop: not held");
    require(!tokenInPool[tokenId], "airdrop: in pool");
    _lock(tokenId, address(0), 0, keccak256("AIRDROP_POOL"));
    tokenInPool[tokenId] = true;
    emit PoolAdded(tokenId);
  }

  /// @notice 运营将 NFT 转入合约并加入空投池
  /// @param tokenId NFT 编号（须先 approve 本合约）
  function depositToPool(uint256 tokenId) external nonReentrant {
    IERC721(address(commercialNFT)).safeTransferFrom(msg.sender, address(this), tokenId);
    require(!tokenInPool[tokenId], "airdrop: in pool");
    _lock(tokenId, address(0), 0, keccak256("AIRDROP_POOL"));
    tokenInPool[tokenId] = true;
    emit PoolAdded(tokenId);
  }

  /// @notice Hub 更新 Merkle 根
  /// @param root_ 新 Merkle root
  function setMerkleRoot(bytes32 root_) external onlyHub {
    merkleRoot = root_;
    emit RootUpdated(root_);
  }

  /// @notice 领取空投 NFT
  /// @param tokenId 要领取的 NFT 编号
  /// @param proof Merkle 证明路径（叶子为 double-hash(account, tokenId)）
  function claim(uint256 tokenId, bytes32[] calldata proof) external nonReentrant {
    _requireActiveRecipient(msg.sender, recipientRegistry.ROLE_AIRDROP_CLAIMER());
    require(tokenInPool[tokenId], "airdrop: not in pool");
    require(!claimed[msg.sender], "airdrop: claimed");

    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender, tokenId))));
    require(MerkleProof.verify(proof, merkleRoot, leaf), "airdrop: bad proof");

    claimed[msg.sender] = true;
    tokenInPool[tokenId] = false;
    _unlock(tokenId);
    IERC721(address(commercialNFT)).safeTransferFrom(address(this), msg.sender, tokenId);
    emit Claimed(tokenId, msg.sender);
  }
}
