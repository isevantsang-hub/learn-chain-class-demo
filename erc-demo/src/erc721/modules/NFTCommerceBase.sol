// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin-contracts-5.6.0/utils/ReentrancyGuard.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {INFTCommerceModule} from "../interfaces/INFTCommerceModule.sol";
import {RecipientRegistry} from "../RecipientRegistry.sol";

/// @title NFTCommerceBase — 业务模块抽象基类
/// @notice 子模块继承本合约，复用 Hub 校验、接受方校验、lock/unlock 封装。
abstract contract NFTCommerceBase is INFTCommerceModule, ReentrancyGuard {
  /// @dev 已注入的 Hub 地址；onlyHub 修饰符使用
  address public override commerceHub;

  /// @dev 商业 NFT 主体，用于 ownerOf、lockToken、unlockToken
  ICommercialNFT public override commercialNFT;

  /// @dev 接受方登记簿，用于校验对手方是否已平台备案
  RecipientRegistry public recipientRegistry;

  /// @dev 防止 wireCommerce 被重复调用
  bool private _wired;

  /// @dev 仅允许 Hub 调用（用于 pipeline、handover、Held 类函数）
  modifier onlyHub() {
    require(msg.sender == commerceHub, "module: not hub");
    _;
  }

  /// @inheritdoc INFTCommerceModule
  /// @param hub_ 中枢合约地址，须等于 msg.sender
  /// @param nft_ CommercialNFT 地址
  /// @param recipientRegistry_ RecipientRegistry 地址
  function wireCommerce(address hub_, address nft_, address recipientRegistry_) external {
    require(!_wired, "module: already wired");
    require(msg.sender == hub_, "module: hub only");
    commerceHub = hub_;
    commercialNFT = ICommercialNFT(nft_);
    recipientRegistry = RecipientRegistry(recipientRegistry_);
    _wired = true;
  }

  /// @dev 内部：要求 account 在注册表中具备 role 且 active=true
  /// @param account 待校验的接受方地址
  /// @param role RecipientRegistry 中的角色常量（如 ROLE_TENANT）
  function _requireActiveRecipient(address account, bytes32 role) internal view {
    require(recipientRegistry.isActiveRecipient(account, role), "module: recipient not active");
  }

  /// @dev 内部：对 tokenId 施加本模块类型的锁定
  /// @param tokenId NFT 编号
  /// @param beneficiary 商业接受方
  /// @param releaseAt 到期时间；0=手动解锁
  /// @param refId 业务单号
  function _lock(uint256 tokenId, address beneficiary, uint256 releaseAt, bytes32 refId) internal {
    commercialNFT.lockToken(tokenId, lockType(), address(this), beneficiary, releaseAt, refId);
  }

  /// @dev 内部：解除本模块对 tokenId 的锁定
  /// @param tokenId NFT 编号
  function _unlock(uint256 tokenId) internal {
    commercialNFT.unlockToken(tokenId);
  }
}
