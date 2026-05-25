// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ICommercialNFT} from "./ICommercialNFT.sol";

/// @title INFTCommerceModule — 业务模块统一挂载接口
/// @notice Hub 部署子模块后，对每个模块调用一次 wireCommerce 注入依赖。
interface INFTCommerceModule {
  /// @notice 返回已接线的 Hub 地址
  /// @return commerceHub 中枢合约地址
  function commerceHub() external view returns (address);

  /// @notice 返回已绑定的商业 NFT 主体接口
  /// @return commercialNFT ICommercialNFT 实例
  function commercialNFT() external view returns (ICommercialNFT);

  /// @notice 返回本模块对应的锁定类型（与 CommercialNFT.LockType 一致）
  /// @return 本模块的 LockType 枚举值
  function lockType() external view returns (ICommercialNFT.LockType);

  /// @notice 由 Hub 在 wireCommerce 时调用，完成依赖注入（仅可调用一次）
  /// @param hub_ NFTCommerceHub 合约地址
  /// @param nft_ CommercialNFT 合约地址
  /// @param recipientRegistry_ RecipientRegistry 合约地址
  function wireCommerce(address hub_, address nft_, address recipientRegistry_) external;
}
