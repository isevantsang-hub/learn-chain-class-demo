// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/IERC721.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {NFTCommerceBase} from "./NFTCommerceBase.sol";

/// @title NFTTimeLock — NFT 时间锁模块
/// @notice 将 NFT 锁定至指定时间后，释放给 beneficiary；可与托管、Hub pipeline 串联。
contract NFTTimeLock is NFTCommerceBase {
  /// @dev 时间锁日程
  struct TimelockSchedule {
    address beneficiary; // 到期接收人
    uint256 releaseAt; // 释放时间戳
    bool released; // 是否已释放
  }

  mapping(uint256 => TimelockSchedule) public schedules;

  event Scheduled(uint256 indexed tokenId, address indexed beneficiary, uint256 releaseAt);
  event Released(uint256 indexed tokenId, address indexed to);

  /// @inheritdoc INFTCommerceModule
  function lockType() external pure override returns (ICommercialNFT.LockType) {
    return ICommercialNFT.LockType.TimeLock;
  }

  /// @notice Hub 接力：NFT 已在合约内时登记释放计划
  /// @param tokenId NFT 编号
  /// @param beneficiary 到期接收地址
  /// @param releaseAt 释放时间戳（须 > block.timestamp）
  function scheduleReleaseHeld(uint256 tokenId, address beneficiary, uint256 releaseAt)
    external
    onlyHub
    nonReentrant
  {
    require(commercialNFT.ownerOfToken(tokenId) == address(this), "timelock: not held");
    require(releaseAt > block.timestamp, "timelock: past");
    _lock(tokenId, beneficiary, releaseAt, keccak256("TIMELOCK"));
    schedules[tokenId] = TimelockSchedule({beneficiary: beneficiary, releaseAt: releaseAt, released: false});
    emit Scheduled(tokenId, beneficiary, releaseAt);
  }

  /// @notice 持有人将 NFT 转入并设定未来释放给 beneficiary
  /// @param tokenId NFT 编号
  /// @param beneficiary 到期接收人
  /// @param releaseAt 释放时间戳
  function scheduleRelease(uint256 tokenId, address beneficiary, uint256 releaseAt) external nonReentrant {
    require(releaseAt > block.timestamp, "timelock: past");
    address owner = commercialNFT.ownerOfToken(tokenId);
    require(owner == msg.sender, "timelock: not owner");

    IERC721(address(commercialNFT)).safeTransferFrom(msg.sender, address(this), tokenId);
    _lock(tokenId, beneficiary, releaseAt, keccak256("TIMELOCK"));

    schedules[tokenId] = TimelockSchedule({beneficiary: beneficiary, releaseAt: releaseAt, released: false});
    emit Scheduled(tokenId, beneficiary, releaseAt);
  }

  /// @notice 到达 releaseAt 后释放 NFT 给 beneficiary（任何人可调用以推动执行）
  /// @param tokenId NFT 编号
  function release(uint256 tokenId) external nonReentrant {
    TimelockSchedule storage s = schedules[tokenId];
    require(!s.released, "timelock: done");
    require(block.timestamp >= s.releaseAt, "timelock: early");

    s.released = true;
    _unlock(tokenId);
    delete schedules[tokenId];
    IERC721(address(commercialNFT)).safeTransferFrom(address(this), s.beneficiary, tokenId);
    emit Released(tokenId, s.beneficiary);
  }

  /// @notice Hub 延长释放时间（仅改本模块 mapping；链上 LockInfo.releaseAt 以首次 lock 为准）
  /// @param tokenId NFT 编号
  /// @param newReleaseAt 新的释放时间戳
  function extendReleaseAt(uint256 tokenId, uint256 newReleaseAt) external onlyHub {
    TimelockSchedule storage s = schedules[tokenId];
    require(!s.released, "timelock: done");
    require(newReleaseAt > block.timestamp, "timelock: past");
    s.releaseAt = newReleaseAt;
  }
}
