// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/IERC721.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {NFTCommerceBase} from "./NFTCommerceBase.sol";

/// @title NFTCustody — NFT 托管模块
/// @notice 用户将 NFT 存入托管库并指定托管商；Hub 可将托管中 NFT 接力给其他模块。
contract NFTCustody is NFTCommerceBase {
  /// @dev 单枚 token 的托管记录
  struct CustodyRecord {
    address depositor; // 存入人（原持有人）
    address custodian; // 托管接受方（须在 Registry 登记 ROLE_CUSTODIAN）
    uint256 depositedAt; // 存入时间戳
    bool active; // 是否在托管中
  }

  /// @dev tokenId => 托管记录
  mapping(uint256 => CustodyRecord) public records;

  event Deposited(uint256 indexed tokenId, address indexed depositor, address indexed custodian);
  event Released(uint256 indexed tokenId, address indexed to);

  /// @inheritdoc INFTCommerceModule
  /// @notice 返回本模块锁定类型 Custody
  function lockType() external pure override returns (ICommercialNFT.LockType) {
    return ICommercialNFT.LockType.Custody;
  }

  /// @notice 用户将 NFT 转入托管合约并锁定
  /// @param tokenId 要托管的 NFT 编号
  /// @param custodian 托管商地址（须 isActiveRecipient(custodian, ROLE_CUSTODIAN)）
  function deposit(uint256 tokenId, address custodian) external nonReentrant {
    _requireActiveRecipient(custodian, recipientRegistry.ROLE_CUSTODIAN());
    address owner = commercialNFT.ownerOfToken(tokenId);
    require(owner == msg.sender, "custody: not owner");

    IERC721(address(commercialNFT)).safeTransferFrom(msg.sender, address(this), tokenId);
    bytes32 refId = keccak256(abi.encodePacked("CUSTODY", tokenId, block.timestamp));
    _lock(tokenId, custodian, 0, refId);

    records[tokenId] = CustodyRecord({
      depositor: msg.sender,
      custodian: custodian,
      depositedAt: block.timestamp,
      active: true
    });
    emit Deposited(tokenId, msg.sender, custodian);
  }

  /// @notice 从托管库取出 NFT 并转给指定地址
  /// @param tokenId NFT 编号
  /// @param to 接收地址（通常为 depositor 本人）
  function release(uint256 tokenId, address to) external nonReentrant {
    CustodyRecord memory rec = records[tokenId];
    require(rec.active, "custody: inactive");
    require(msg.sender == rec.depositor || msg.sender == commerceHub, "custody: forbidden");

    _unlock(tokenId);
    delete records[tokenId];
    IERC721(address(commercialNFT)).safeTransferFrom(address(this), to, tokenId);
    emit Released(tokenId, to);
  }

  /// @notice Hub 专用：将托管中 NFT 转交下一业务模块（代拍/时间锁/碎片化等）
  /// @param tokenId NFT 编号
  /// @param module 目标模块合约地址
  /// @param newLock 目标模块的 LockType
  /// @param beneficiary 新业务的商业接受方
  function handoverToModule(uint256 tokenId, address module, ICommercialNFT.LockType newLock, address beneficiary)
    external
    onlyHub
    nonReentrant
  {
    CustodyRecord memory rec = records[tokenId];
    require(rec.active, "custody: inactive");
    _unlock(tokenId);
    commercialNFT.lockToken(tokenId, newLock, module, beneficiary, 0, keccak256("HANDOVER"));
    IERC721(address(commercialNFT)).safeTransferFrom(address(this), module, tokenId);
    delete records[tokenId];
  }
}
