// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/utils/SafeERC20.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {NFTCommerceBase} from "./NFTCommerceBase.sol";

/// @title NFTProxyAuction — 代拍模块
/// @notice 委托人上架、竞拍人 ERC-20 出价、到期结标交割 NFT 与款项。
contract NFTProxyAuction is NFTCommerceBase {
  using SafeERC20 for IERC20;

  /// @dev 竞价结算用 ERC-20
  IERC20 public paymentToken;

  /// @dev 平台手续费，基点（10000 = 100%）
  uint256 public platformFeeBps;

  /// @dev 单场代拍状态
  struct Auction {
    address consignor; // 委托人（接受方 ROLE_CONSIGNOR）
    address highestBidder; // 当前最高出价人
    uint256 highestBid; // 当前最高出价金额
    uint256 endTime; // 拍卖结束时间戳
    bool settled; // 是否已结标
    bool active; // 是否进行中
  }

  mapping(uint256 => Auction) public auctions;

  event Listed(uint256 indexed tokenId, address indexed consignor, uint256 endTime);
  event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
  event Settled(uint256 indexed tokenId, address indexed winner, uint256 price);

  /// @notice 部署代拍模块
  /// @param paymentToken_ 出价/结算代币
  /// @param platformFeeBps_ 平台费基点
  constructor(IERC20 paymentToken_, uint256 platformFeeBps_) {
    paymentToken = paymentToken_;
    platformFeeBps = platformFeeBps_;
  }

  /// @inheritdoc INFTCommerceModule
  function lockType() external pure override returns (ICommercialNFT.LockType) {
    return ICommercialNFT.LockType.ProxyAuction;
  }

  /// @notice Hub 在 custody handover 后调用：创建拍卖场次（NFT 须已在本合约且已锁定为 ProxyAuction）
  /// @param tokenId NFT 编号
  /// @param consignor 委托人地址
  /// @param duration 拍卖持续秒数
  function listFromCustody(uint256 tokenId, address consignor, uint256 duration) external onlyHub nonReentrant {
    _requireActiveRecipient(consignor, recipientRegistry.ROLE_CONSIGNOR());
    require(commercialNFT.ownerOfToken(tokenId) == address(this), "auction: nft not here");

    auctions[tokenId] = Auction({
      consignor: consignor,
      highestBidder: address(0),
      highestBid: 0,
      endTime: block.timestamp + duration,
      settled: false,
      active: true
    });
    emit Listed(tokenId, consignor, block.timestamp + duration);
  }

  /// @notice 竞拍人出价（须 ROLE_BIDDER；出价须高于当前最高价）
  /// @param tokenId NFT 编号
  /// @param amount 出价金额（须先 approve 本合约）
  function bid(uint256 tokenId, uint256 amount) external nonReentrant {
    Auction storage a = auctions[tokenId];
    require(a.active && !a.settled, "auction: closed");
    require(block.timestamp < a.endTime, "auction: ended");
    _requireActiveRecipient(msg.sender, recipientRegistry.ROLE_BIDDER());
    require(amount > a.highestBid, "auction: low bid");

    if (a.highestBidder != address(0)) {
      paymentToken.safeTransfer(a.highestBidder, a.highestBid);
    }
    paymentToken.safeTransferFrom(msg.sender, address(this), amount);
    a.highestBidder = msg.sender;
    a.highestBid = amount;
    emit BidPlaced(tokenId, msg.sender, amount);
  }

  /// @notice 拍卖结束后结标：NFT 给中标人，扣除平台费后款项给委托人
  /// @param tokenId NFT 编号
  function settle(uint256 tokenId) external nonReentrant {
    Auction storage a = auctions[tokenId];
    require(a.active && !a.settled, "auction: done");
    require(block.timestamp >= a.endTime, "auction: not ended");
    require(a.highestBidder != address(0), "auction: no bid");

    a.settled = true;
    a.active = false;
    uint256 fee = (a.highestBid * platformFeeBps) / 10_000;
    uint256 payout = a.highestBid - fee;

    _unlock(tokenId);
    IERC721(address(commercialNFT)).safeTransferFrom(address(this), a.highestBidder, tokenId);
    paymentToken.safeTransfer(a.consignor, payout);
    emit Settled(tokenId, a.highestBidder, a.highestBid);
  }
}
