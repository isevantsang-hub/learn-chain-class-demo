// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/utils/SafeERC20.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {NFTCommerceBase} from "./NFTCommerceBase.sol";

/// @title NFTRental — NFT 租赁模块
/// @notice 出租人挂牌；承租人（ROLE_TENANT）付租金+押金；到期 complete 退押金、NFT 回出租人。
contract NFTRental is NFTCommerceBase {
  using SafeERC20 for IERC20;

  /// @dev 租金与押金结算代币
  IERC20 public paymentToken;

  /// @dev 租约信息
  struct Lease {
    address landlord; // 出租人
    address tenant; // 承租人（接受方）；0 表示尚未出租
    uint256 rentPerDay; // 每日租金（wei）
    uint256 deposit; // 押金（wei）
    uint256 startAt; // 租约开始时间
    uint256 endAt; // 租约结束时间
    bool active; // 租约是否有效
  }

  mapping(uint256 => Lease) public leases;

  event Listed(uint256 indexed tokenId, address indexed landlord, uint256 rentPerDay, uint256 endAt);
  event Leased(uint256 indexed tokenId, address indexed tenant, uint256 paid);
  event Completed(uint256 indexed tokenId);

  /// @notice 部署租赁模块
  /// @param paymentToken_ ERC-20 支付代币
  constructor(IERC20 paymentToken_) {
    paymentToken = paymentToken_;
  }

  /// @inheritdoc INFTCommerceModule
  function lockType() external pure override returns (ICommercialNFT.LockType) {
    return ICommercialNFT.LockType.Rental;
  }

  /// @notice 出租人挂牌：NFT 转入合约并设置租金参数
  /// @param tokenId NFT 编号
  /// @param rentPerDay 每日租金
  /// @param deposit 押金数额
  /// @param durationDays 最长挂牌天数（用于计算 endAt 上限）
  function listForRent(uint256 tokenId, uint256 rentPerDay, uint256 deposit, uint256 durationDays)
    external
    nonReentrant
  {
    address owner = commercialNFT.ownerOfToken(tokenId);
    require(owner == msg.sender, "rental: not owner");

    IERC721(address(commercialNFT)).safeTransferFrom(msg.sender, address(this), tokenId);
    uint256 endAt = block.timestamp + durationDays * 1 days;
    _lock(tokenId, address(0), endAt, keccak256("RENT_LIST"));

    leases[tokenId] = Lease({
      landlord: msg.sender,
      tenant: address(0),
      rentPerDay: rentPerDay,
      deposit: deposit,
      startAt: 0,
      endAt: endAt,
      active: true
    });
    emit Listed(tokenId, msg.sender, rentPerDay, endAt);
  }

  /// @notice 承租人租下 NFT
  /// @param tokenId NFT 编号
  /// @param daysToRent 租赁天数
  function rent(uint256 tokenId, uint256 daysToRent) external nonReentrant {
    Lease storage l = leases[tokenId];
    require(l.active && l.tenant == address(0), "rental: taken");
    _requireActiveRecipient(msg.sender, recipientRegistry.ROLE_TENANT());

    uint256 rentCost = l.rentPerDay * daysToRent;
    uint256 total = rentCost + l.deposit;
    paymentToken.safeTransferFrom(msg.sender, address(this), total);

    l.tenant = msg.sender;
    l.startAt = block.timestamp;
    _lock(tokenId, msg.sender, l.endAt, keccak256("RENT_ACTIVE"));

    emit Leased(tokenId, msg.sender, total);
  }

  /// @notice 租期结束：NFT 归还出租人，押金退承租人
  /// @param tokenId NFT 编号
  function complete(uint256 tokenId) external nonReentrant {
    Lease storage l = leases[tokenId];
    require(l.active, "rental: inactive");
    require(block.timestamp >= l.endAt, "rental: not ended");
    require(msg.sender == l.landlord || msg.sender == l.tenant || msg.sender == commerceHub, "rental: forbidden");

    address tenant = l.tenant;
    uint256 dep = l.deposit;
    _unlock(tokenId);
    delete leases[tokenId];

    IERC721(address(commercialNFT)).safeTransferFrom(address(this), l.landlord, tokenId);
    if (tenant != address(0) && dep > 0) {
      paymentToken.safeTransfer(tenant, dep);
    }
    emit Completed(tokenId);
  }
}
