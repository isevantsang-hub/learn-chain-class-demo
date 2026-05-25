// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin-contracts-5.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin-contracts-5.6.0/access/AccessControl.sol";
import {ICommercialNFT} from "./interfaces/ICommercialNFT.sol";

/// @title CommercialNFT — 商业 NFT 主体合约
/// @notice
/// - 全平台统一的 ERC-721 资产；
/// - 每枚 token 可有业务锁定（托管/质押/代拍等），锁定期间仅授权 module 可驱动转移；
/// - beneficiary 字段记录商业接受方（承租人、出借人、中标人等）。
contract CommercialNFT is ERC721, ERC721URIStorage, AccessControl, ICommercialNFT {
  /// @dev 拥有 mintCommercial 权限的角色（通常授予 Hub）
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  /// @dev 下一枚待铸造的 tokenId（自增）
  uint256 private _nextTokenId;

  /// @dev tokenId => 当前业务锁定信息
  mapping(uint256 => LockInfo) private _locks;

  /// @dev 业务模块地址 => 是否被平台授权可调用 lockToken
  mapping(address => bool) private _authorizedModules;

  /// @notice 部署商业 NFT 集合
  /// @param admin 获得 DEFAULT_ADMIN_ROLE 与 MINTER_ROLE 的地址（一般为部署者或多签）
  constructor(address admin) ERC721("Commercial NFT", "CNFT") {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(MINTER_ROLE, admin);
  }

  /// @notice 铸造一枚商业 NFT 并设置链上 metadata URI
  /// @param to 接收者地址（持有人）
  /// @param uri 元数据链接，如 ipfs://.../1.json
  /// @return tokenId 新铸造的编号
  function mintCommercial(address to, string calldata uri) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
    tokenId = _nextTokenId++;
    _safeMint(to, tokenId);
    _setTokenURI(tokenId, uri);
  }

  /// @inheritdoc ICommercialNFT
  /// @notice 平台管理员授权某业务合约可操作锁定逻辑
  function authorizeModule(address module, bool authorized) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _authorizedModules[module] = authorized;
    emit ModuleAuthorized(module, authorized);
  }

  /// @inheritdoc ICommercialNFT
  /// @notice 查询模块是否已授权
  function isModuleAuthorized(address module) external view returns (bool) {
    return _authorizedModules[module];
  }

  /// @inheritdoc ICommercialNFT
  /// @notice 登记业务锁定；调用者必须是已授权模块之一
  function lockToken(
    uint256 tokenId,
    LockType lockType,
    address module,
    address beneficiary,
    uint256 releaseAt,
    bytes32 refId
  ) external {
    require(_authorizedModules[msg.sender], "CommercialNFT: caller not module");
    require(_authorizedModules[module], "CommercialNFT: module not authorized");
    require(lockType != LockType.None, "CommercialNFT: invalid lock");
    require(_ownerOf(tokenId) != address(0), "CommercialNFT: nonexistent");
    require(_locks[tokenId].lockType == LockType.None, "CommercialNFT: already locked");

    _locks[tokenId] = LockInfo({
      lockType: lockType,
      module: module,
      beneficiary: beneficiary,
      releaseAt: releaseAt,
      refId: refId
    });
    emit TokenLocked(tokenId, lockType, module, beneficiary, releaseAt);
  }

  /// @inheritdoc ICommercialNFT
  /// @notice 解除锁定；仅 lockInfo.module 可调用
  function unlockToken(uint256 tokenId) external {
    LockInfo memory info = _locks[tokenId];
    require(info.lockType != LockType.None, "CommercialNFT: not locked");
    require(msg.sender == info.module, "CommercialNFT: not lock owner module");
    _locks[tokenId] = LockInfo({
      lockType: LockType.None,
      module: address(0),
      beneficiary: address(0),
      releaseAt: 0,
      refId: bytes32(0)
    });
    emit TokenUnlocked(tokenId, info.lockType, msg.sender);
  }

  /// @inheritdoc ICommercialNFT
  /// @notice 只读：返回锁定详情
  function getLockInfo(uint256 tokenId) external view returns (LockInfo memory) {
    return _locks[tokenId];
  }

  /// @inheritdoc ICommercialNFT
  /// @notice 只读：当前持有人
  function ownerOfToken(uint256 tokenId) external view returns (address) {
    return _ownerOf(tokenId);
  }

  /// @dev OpenZeppelin v5 转移钩子：若 token 处于业务锁定，禁止持有人私自转出
  /// @param to 接收地址
  /// @param tokenId NFT 编号
  /// @param auth 授权方（transferFrom 时的 spender）
  /// @return 实际 from 地址
  function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
    LockInfo memory info = _locks[tokenId];
    if (info.lockType != LockType.None) {
      require(
        msg.sender == info.module || to == info.module || auth == info.module,
        "CommercialNFT: token locked"
      );
    }
    return super._update(to, tokenId, auth);
  }

  /// @notice 返回 token 的 metadata URI（ERC-721 标准扩展）
  /// @param tokenId NFT 编号
  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  /// @notice ERC-165 接口探测（钱包/市场用）
  /// @param interfaceId 接口 id 四字节
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721URIStorage, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
