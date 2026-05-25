// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/utils/SafeERC20.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {NFTCommerceBase} from "./NFTCommerceBase.sol";

/// @title NFTCollateralLending — NFT 抵押借贷模块
/// @notice 借款人抵押 NFT 借出代币；到期还款取回；逾期出借人可清算取得 NFT。
contract NFTCollateralLending is NFTCommerceBase {
  using SafeERC20 for IERC20;

  /// @dev 借贷本金与利息结算代币
  IERC20 public paymentToken;

  /// @dev 单笔借据
  struct Loan {
    address borrower; // 借款人（ROLE_BORROWER）
    address lender; // 出借人（ROLE_LENDER）
    uint256 principal; // 本金
    uint256 interestBps; // 利率，基点
    uint256 dueAt; // 到期时间戳
    bool repaid; // 是否已还款
    bool active; // 借据是否有效
  }

  mapping(uint256 => Loan) public loans;

  event Collateralized(uint256 indexed tokenId, address indexed borrower, uint256 principal);
  event Repaid(uint256 indexed tokenId);
  event Liquidated(uint256 indexed tokenId, address indexed lender);

  /// @notice 部署借贷模块
  /// @param paymentToken_ ERC-20 借贷代币
  constructor(IERC20 paymentToken_) {
    paymentToken = paymentToken_;
  }

  /// @inheritdoc INFTCommerceModule
  function lockType() external pure override returns (ICommercialNFT.LockType) {
    return ICommercialNFT.LockType.Collateral;
  }

  /// @notice 借款人抵押 NFT 并从出借人处获得本金
  /// @param tokenId 抵押的 NFT 编号
  /// @param lender 出借人地址（须 ROLE_LENDER）
  /// @param principal 借款本金
  /// @param interestBps 利率基点（如 500 = 5%）
  /// @param durationDays 借款天数
  function borrow(
    uint256 tokenId,
    address lender,
    uint256 principal,
    uint256 interestBps,
    uint256 durationDays
  ) external nonReentrant {
    _requireActiveRecipient(lender, recipientRegistry.ROLE_LENDER());
    _requireActiveRecipient(msg.sender, recipientRegistry.ROLE_BORROWER());

    address owner = commercialNFT.ownerOfToken(tokenId);
    require(owner == msg.sender, "lend: not owner");

    IERC721(address(commercialNFT)).safeTransferFrom(msg.sender, address(this), tokenId);
    uint256 dueAt = block.timestamp + durationDays * 1 days;
    _lock(tokenId, lender, dueAt, keccak256("LOAN"));

    loans[tokenId] = Loan({
      borrower: msg.sender,
      lender: lender,
      principal: principal,
      interestBps: interestBps,
      dueAt: dueAt,
      repaid: false,
      active: true
    });

    paymentToken.safeTransferFrom(lender, msg.sender, principal);
    emit Collateralized(tokenId, msg.sender, principal);
  }

  /// @notice 借款人还款本息后取回 NFT
  /// @param tokenId NFT 编号
  function repay(uint256 tokenId) external nonReentrant {
    Loan storage ln = loans[tokenId];
    require(ln.active && !ln.repaid, "lend: closed");
    require(msg.sender == ln.borrower, "lend: not borrower");

    uint256 interest = (ln.principal * ln.interestBps) / 10_000;
    uint256 total = ln.principal + interest;
    paymentToken.safeTransferFrom(msg.sender, ln.lender, total);

    ln.repaid = true;
    ln.active = false;
    _unlock(tokenId);
    delete loans[tokenId];
    IERC721(address(commercialNFT)).safeTransferFrom(address(this), ln.borrower, tokenId);
    emit Repaid(tokenId);
  }

  /// @notice 逾期清算：NFT 转移给出借人
  /// @param tokenId NFT 编号
  function liquidate(uint256 tokenId) external nonReentrant {
    Loan storage ln = loans[tokenId];
    require(ln.active && !ln.repaid, "lend: closed");
    require(block.timestamp > ln.dueAt, "lend: not overdue");
    require(msg.sender == ln.lender || msg.sender == commerceHub, "lend: forbidden");

    ln.active = false;
    _unlock(tokenId);
    delete loans[tokenId];
    IERC721(address(commercialNFT)).safeTransferFrom(address(this), ln.lender, tokenId);
    emit Liquidated(tokenId, ln.lender);
  }
}
