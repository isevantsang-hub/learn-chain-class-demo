// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/utils/SafeERC20.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {NFTCommerceBase} from "./NFTCommerceBase.sol";

/// @title NFTStaking — NFT 质押模块
/// @notice 持有人将 NFT 质押在本合约，按时间获得 ERC-20 奖励；质押期间 NFT 锁定。
contract NFTStaking is NFTCommerceBase {
  using SafeERC20 for IERC20;

  /// @dev 奖励代币（通常为平台 PayToken）
  IERC20 public rewardToken;

  /// @dev 每枚质押 NFT 每秒奖励数量（wei）
  uint256 public rewardRatePerSecond;

  /// @dev 单笔质押信息
  struct StakeInfo {
    address staker; // 质押人
    uint256 startTime; // 质押开始时间
    uint256 accruedClaimed; // 预留：已计提领取（当前实现未使用）
    bool active; // 是否质押中
  }

  mapping(uint256 => StakeInfo) public stakes;

  event Staked(uint256 indexed tokenId, address indexed staker);
  event Unstaked(uint256 indexed tokenId, address indexed staker, uint256 rewardPaid);

  /// @notice 部署质押模块
  /// @param rewardToken_ 奖励 ERC-20 地址
  /// @param rewardRatePerSecond_ 每秒每 NFT 奖励（wei）
  constructor(IERC20 rewardToken_, uint256 rewardRatePerSecond_) {
    rewardToken = rewardToken_;
    rewardRatePerSecond = rewardRatePerSecond_;
  }

  /// @inheritdoc INFTCommerceModule
  function lockType() external pure override returns (ICommercialNFT.LockType) {
    return ICommercialNFT.LockType.Staking;
  }

  /// @notice Hub 调整奖励速率
  /// @param newRate 新的每秒奖励（wei）
  function setRewardRate(uint256 newRate) external onlyHub {
    rewardRatePerSecond = newRate;
  }

  /// @notice 质押 NFT
  /// @param tokenId 要质押的 NFT 编号（调用者须为 owner）
  function stake(uint256 tokenId) external nonReentrant {
    address owner = commercialNFT.ownerOfToken(tokenId);
    require(owner == msg.sender, "staking: not owner");

    IERC721(address(commercialNFT)).safeTransferFrom(msg.sender, address(this), tokenId);
    _lock(tokenId, msg.sender, 0, keccak256("STAKE"));

    stakes[tokenId] = StakeInfo({staker: msg.sender, startTime: block.timestamp, accruedClaimed: 0, active: true});
    emit Staked(tokenId, msg.sender);
  }

  /// @notice 计算当前可领取奖励（只读）
  /// @param tokenId NFT 编号
  /// @return 奖励代币数量（wei）
  function pendingReward(uint256 tokenId) public view returns (uint256) {
    StakeInfo memory s = stakes[tokenId];
    if (!s.active) return 0;
    return (block.timestamp - s.startTime) * rewardRatePerSecond;
  }

  /// @notice 解除质押：取回 NFT 并发放奖励
  /// @param tokenId NFT 编号
  function unstake(uint256 tokenId) external nonReentrant {
    StakeInfo memory s = stakes[tokenId];
    require(s.active && s.staker == msg.sender, "staking: invalid");

    uint256 reward = pendingReward(tokenId);
    _unlock(tokenId);
    delete stakes[tokenId];

    IERC721(address(commercialNFT)).safeTransferFrom(address(this), msg.sender, tokenId);
    if (reward > 0) {
      rewardToken.safeTransfer(msg.sender, reward);
    }
    emit Unstaked(tokenId, msg.sender, reward);
  }
}
