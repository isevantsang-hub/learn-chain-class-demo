// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/IERC721.sol";
import {ERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/utils/SafeERC20.sol";
import {ICommercialNFT} from "../interfaces/ICommercialNFT.sol";
import {NFTCommerceBase} from "./NFTCommerceBase.sol";

/// @dev 某一枚 NFT 对应的碎片化份额代币（ERC-20），由 NFTFractional 部署
contract FractionShareToken is ERC20 {
  /// @dev 关联的商业 NFT tokenId
  uint256 public immutable linkedTokenId;

  /// @notice 部署份额币并一次性 mint 全部份额给部署者（NFTFractional 合约）
  /// @param tokenId_ 底层 NFT 编号
  /// @param totalShares 份额总供应量
  constructor(uint256 tokenId_, uint256 totalShares) ERC20(string.concat("CNFT-Frac-", _toStr(tokenId_)), "FRAC") {
    linkedTokenId = tokenId_;
    _mint(msg.sender, totalShares);
  }

  /// @dev 将 uint256 转为十进制字符串（用于 name）
  function _toStr(uint256 v) private pure returns (string memory) {
    if (v == 0) return "0";
    uint256 t = v;
    uint256 d;
    while (t != 0) {
      d++;
      t /= 10;
    }
    bytes memory b = new bytes(d);
    while (v != 0) {
      d--;
      b[d] = bytes1(uint8(48 + (v % 10)));
      v /= 10;
    }
    return string(b);
  }
}

/// @title NFTFractional — NFT 碎片化模块
/// @notice 锁定底层 NFT，铸造可转让份额 ERC-20；支付 buyoutPrice 可回购完整 NFT。
contract NFTFractional is NFTCommerceBase {
  using SafeERC20 for IERC20;

  /// @dev 单个 NFT 的碎片化金库信息
  struct Vault {
    address shareToken; // 份额 ERC-20 合约地址
    address originalOwner; // 原持有人 / 碎片受益人
    uint256 totalShares; // 份额总量
    uint256 buyoutPrice; // 回购 NFT 所需支付代币数
    bool active; // 是否碎片化中
  }

  mapping(uint256 => Vault) public vaults;

  /// @dev 回购时使用的支付代币
  IERC20 public paymentToken;

  event Fractionalized(uint256 indexed tokenId, address shareToken, uint256 shares);
  event Buyout(uint256 indexed tokenId, address indexed buyer);

  /// @notice 部署碎片化模块
  /// @param paymentToken_ 回购支付用 ERC-20
  constructor(IERC20 paymentToken_) {
    paymentToken = paymentToken_;
  }

  /// @inheritdoc INFTCommerceModule
  function lockType() external pure override returns (ICommercialNFT.LockType) {
    return ICommercialNFT.LockType.Fractional;
  }

  /// @notice Hub 接力：NFT 已在合约内时执行碎片化
  /// @param tokenId NFT 编号
  /// @param owner 份额接收人 / 原 owner
  /// @param totalShares 铸造份额数量
  /// @param buyoutPrice 全额回购价
  function fractionalizeHeld(uint256 tokenId, address owner, uint256 totalShares, uint256 buyoutPrice)
    external
    onlyHub
    nonReentrant
  {
    require(commercialNFT.ownerOfToken(tokenId) == address(this), "fraction: not held");
    _fractionalize(tokenId, owner, totalShares, buyoutPrice);
  }

  /// @notice 持有人主动碎片化：先转入 NFT 再 mint 份额
  /// @param tokenId NFT 编号
  /// @param totalShares 份额总量
  /// @param buyoutPrice 回购价
  function fractionalize(uint256 tokenId, uint256 totalShares, uint256 buyoutPrice) external nonReentrant {
    address owner = commercialNFT.ownerOfToken(tokenId);
    require(owner == msg.sender, "fraction: not owner");
    IERC721(address(commercialNFT)).safeTransferFrom(msg.sender, address(this), tokenId);
    _fractionalize(tokenId, msg.sender, totalShares, buyoutPrice);
  }

  /// @dev 内部：锁定 NFT、部署份额币并转给 owner
  function _fractionalize(uint256 tokenId, address owner, uint256 totalShares, uint256 buyoutPrice) private {
    require(totalShares > 0, "fraction: zero shares");
    _lock(tokenId, owner, 0, keccak256("FRAC"));

    FractionShareToken share = new FractionShareToken(tokenId, totalShares);
    share.transfer(owner, totalShares);

    vaults[tokenId] = Vault({
      shareToken: address(share),
      originalOwner: owner,
      totalShares: totalShares,
      buyoutPrice: buyoutPrice,
      active: true
    });
    emit Fractionalized(tokenId, address(share), totalShares);
  }

  /// @notice 支付 buyoutPrice 并交还全部份额，取回底层 NFT
  /// @param tokenId NFT 编号
  function buyout(uint256 tokenId) external nonReentrant {
    Vault storage v = vaults[tokenId];
    require(v.active, "fraction: inactive");
    paymentToken.safeTransferFrom(msg.sender, address(this), v.buyoutPrice);
    paymentToken.safeTransfer(v.originalOwner, v.buyoutPrice);

    FractionShareToken(v.shareToken).transferFrom(msg.sender, address(this), v.totalShares);
    _unlock(tokenId);
    delete vaults[tokenId];
    IERC721(address(commercialNFT)).safeTransferFrom(address(this), msg.sender, tokenId);
    emit Buyout(tokenId, msg.sender);
  }
}
