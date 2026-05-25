// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin-contracts-5.6.0/access/AccessControl.sol";

/// @title RecipientRegistry — 商业接受方登记簿
/// @notice 平台将托管商、承租人、借款人、竞拍人等地址登记在此；各业务模块成交前校验对手方已备案。
contract RecipientRegistry is AccessControl {
  /// @dev 可执行 setRecipient 的角色（Hub 运营可被授予）
  bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

  /// @dev 托管商角色：NFTCustody.deposit 的 custodian 参数须通过此角色校验
  bytes32 public constant ROLE_CUSTODIAN = keccak256("ROLE_CUSTODIAN");

  /// @dev 代拍委托人：上架代拍时的 consignor
  bytes32 public constant ROLE_CONSIGNOR = keccak256("ROLE_CONSIGNOR");

  /// @dev 竞拍人：NFTProxyAuction.bid 的调用者
  bytes32 public constant ROLE_BIDDER = keccak256("ROLE_BIDDER");

  /// @dev 承租人：NFTRental.rent 的调用者
  bytes32 public constant ROLE_TENANT = keccak256("ROLE_TENANT");

  /// @dev 借款人：NFTCollateralLending.borrow 的调用者
  bytes32 public constant ROLE_BORROWER = keccak256("ROLE_BORROWER");

  /// @dev 出借人：NFTCollateralLending.borrow 的 lender 参数
  bytes32 public constant ROLE_LENDER = keccak256("ROLE_LENDER");

  /// @dev 碎片化份额买方（扩展用）
  bytes32 public constant ROLE_FRACTION_BUYER = keccak256("ROLE_FRACTION_BUYER");

  /// @dev 空投领取人：NFTAirdrop.claim 的调用者
  bytes32 public constant ROLE_AIRDROP_CLAIMER = keccak256("ROLE_AIRDROP_CLAIMER");

  /// @dev 单条接受方档案
  struct RecipientProfile {
    bool active; // 是否启用；false 时 isActiveRecipient 返回 false
    string label; // 人类可读备注，如「华东托管中心」
  }

  /// @dev account => role => 档案
  mapping(address => mapping(bytes32 => RecipientProfile)) private _profiles;

  /// @dev 接受方登记变更事件
  event RecipientUpdated(address indexed account, bytes32 indexed role, bool active, string label);

  /// @notice 部署登记簿
  /// @param admin 管理员，拥有 DEFAULT_ADMIN_ROLE 与 REGISTRAR_ROLE
  constructor(address admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(REGISTRAR_ROLE, admin);
  }

  /// @notice 登记或更新某地址在某商业角色下的资格
  /// @param account 接受方链上地址
  /// @param role 角色常量（如 ROLE_TENANT）
  /// @param active 是否启用
  /// @param label 备注标签，便于运营识别
  function setRecipient(address account, bytes32 role, bool active, string calldata label)
    external
    onlyRole(REGISTRAR_ROLE)
  {
    _profiles[account][role] = RecipientProfile({active: active, label: label});
    emit RecipientUpdated(account, role, active, label);
  }

  /// @notice 模块调用：该地址在指定角色下是否已启用
  /// @param account 待查地址
  /// @param role 角色常量
  /// @return 是否 active
  function isActiveRecipient(address account, bytes32 role) external view returns (bool) {
    return _profiles[account][role].active;
  }

  /// @notice 查询完整档案（含 label）
  /// @param account 地址
  /// @param role 角色
  /// @return RecipientProfile 结构体
  function getProfile(address account, bytes32 role) external view returns (RecipientProfile memory) {
    return _profiles[account][role];
  }
}
