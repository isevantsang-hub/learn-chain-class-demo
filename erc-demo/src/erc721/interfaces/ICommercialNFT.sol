// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ICommercialNFT — 商业 NFT 主体对外接口
/// @notice 所有业务模块只依赖本接口，即可查询锁定状态、申请锁定/解锁，而不必依赖具体实现合约。
interface ICommercialNFT {
  /// @dev 锁定类型枚举：与八大业务模块一一对应，用于链上索引与风控展示
  enum LockType {
    None, // 0 — 无业务锁定，持有人可按标准 ERC-721 自由转移
    Custody, // 1 — 托管中
    Staking, // 2 — 质押中
    ProxyAuction, // 3 — 代拍挂牌/竞拍中
    Fractional, // 4 — 碎片化锁定（底层 NFT 由份额代表）
    Rental, // 5 — 租赁中
    Collateral, // 6 — 抵押借贷中
    Airdrop, // 7 — 空投池锁定，待领取
    TimeLock // 8 — 时间锁，到期前不可转给第三方
  }

  /// @dev 单枚 token 的业务锁定快照
  struct LockInfo {
    LockType lockType; // 当前业务类型（见 enum）
    address module; // 负责该 token 逻辑的业务合约地址（如 NFTCustody、NFTStaking）
    address beneficiary; // 商业接受方：承租人、借款人、中标人、托管商等
    uint256 releaseAt; // 计划解锁时间戳；0 表示仅由 module 主动 unlock
    bytes32 refId; // 业务单号/引用 id，便于链下订单系统对齐
  }

  /// @dev 平台授权/取消授权某业务模块
  event ModuleAuthorized(address indexed module, bool authorized);

  /// @dev 某 token 进入业务锁定
  event TokenLocked(
    uint256 indexed tokenId,
    LockType lockType,
    address indexed module,
    address beneficiary,
    uint256 releaseAt
  );

  /// @dev 某 token 解除业务锁定
  event TokenUnlocked(uint256 indexed tokenId, LockType lockType, address indexed module);

  /// @notice 授权或撤销业务模块资格
  /// @param module 业务合约地址（如 address(custody)）
  /// @param authorized true=允许该模块调用 lockToken；false=撤销
  function authorizeModule(address module, bool authorized) external;

  /// @notice 查询某地址是否为已授权模块
  /// @param module 待查询的合约地址
  /// @return 是否已授权
  function isModuleAuthorized(address module) external view returns (bool);

  /// @notice 为指定 token 登记业务锁定（锁定后持有人不能私自转出）
  /// @param tokenId 商业 NFT 的编号
  /// @param lockType 业务类型（Custody/Staking/...）
  /// @param module 承担该业务的合约地址（锁定记录中的「责任模块」）
  /// @param beneficiary 商业接受方地址（可为 0，表示尚未确定对手方）
  /// @param releaseAt 到期时间戳；0=仅模块可 unlock
  /// @param refId 业务引用 id（链下订单号哈希等）
  function lockToken(
    uint256 tokenId,
    LockType lockType,
    address module,
    address beneficiary,
    uint256 releaseAt,
    bytes32 refId
  ) external;

  /// @notice 解除 token 的业务锁定（仅 lockInfo.module 可调用）
  /// @param tokenId 要解锁的 NFT 编号
  function unlockToken(uint256 tokenId) external;

  /// @notice 查询 token 当前锁定信息
  /// @param tokenId NFT 编号
  /// @return 当前 LockInfo 结构体
  function getLockInfo(uint256 tokenId) external view returns (LockInfo memory);

  /// @notice 查询 token 当前持有人（等同 ERC-721 ownerOf）
  /// @param tokenId NFT 编号
  /// @return 持有人地址
  function ownerOfToken(uint256 tokenId) external view returns (address);
}
