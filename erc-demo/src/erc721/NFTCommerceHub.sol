// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin-contracts-5.6.0/access/AccessControl.sol";
import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";
import {CommercialNFT} from "./CommercialNFT.sol";
import {RecipientRegistry} from "./RecipientRegistry.sol";
import {NFTCustody} from "./modules/NFTCustody.sol";
import {NFTStaking} from "./modules/NFTStaking.sol";
import {NFTProxyAuction} from "./modules/NFTProxyAuction.sol";
import {NFTFractional} from "./modules/NFTFractional.sol";
import {NFTRental} from "./modules/NFTRental.sol";
import {NFTCollateralLending} from "./modules/NFTCollateralLending.sol";
import {NFTAirdrop} from "./modules/NFTAirdrop.sol";
import {NFTTimeLock} from "./modules/NFTTimeLock.sol";
import {ICommercialNFT} from "./interfaces/ICommercialNFT.sol";
import {INFTCommerceModule} from "./interfaces/INFTCommerceModule.sol";

/// @title NFTCommerceHub — 商业 NFT 中枢合约
/// @notice 部署八大模块、接线、铸造 NFT、登记接受方、跨模块 pipeline 编排。
contract NFTCommerceHub is AccessControl {
  /// @dev 运营角色：可 mint、registerRecipient、触发 pipeline、充值质押池
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  /// @dev 商业 NFT 主体合约引用
  CommercialNFT public commercialNFT;

  /// @dev 接受方登记簿引用
  RecipientRegistry public recipientRegistry;

  /// @dev 托管模块实例
  NFTCustody public custody;

  /// @dev 质押模块实例
  NFTStaking public staking;

  /// @dev 代拍模块实例
  NFTProxyAuction public proxyAuction;

  /// @dev 碎片化模块实例
  NFTFractional public fractional;

  /// @dev 租赁模块实例
  NFTRental public rental;

  /// @dev 抵押借贷模块实例
  NFTCollateralLending public collateralLending;

  /// @dev 空投模块实例
  NFTAirdrop public airdrop;

  /// @dev 时间锁模块实例
  NFTTimeLock public timeLock;

  /// @dev 接线完成事件
  event CommerceWired(address indexed nft, address indexed registry);

  /// @notice 部署 Hub 并创建全部子模块
  /// @param nft_ 已部署的 CommercialNFT 地址
  /// @param registry_ 已部署的 RecipientRegistry 地址
  /// @param paymentToken_ 平台结算用 ERC-20（质押奖励、拍卖、租赁、借贷等）
  /// @param stakingRewardPerSecond_ 质押每秒每枚 NFT 奖励（wei）
  /// @param auctionFeeBps_ 代拍平台费，基点（250 = 2.5%）
  constructor(
    CommercialNFT nft_,
    RecipientRegistry registry_,
    IERC20 paymentToken_,
    uint256 stakingRewardPerSecond_,
    uint256 auctionFeeBps_
  ) {
    commercialNFT = nft_;
    recipientRegistry = registry_;

    custody = new NFTCustody();
    staking = new NFTStaking(paymentToken_, stakingRewardPerSecond_);
    proxyAuction = new NFTProxyAuction(paymentToken_, auctionFeeBps_);
    fractional = new NFTFractional(paymentToken_);
    rental = new NFTRental(paymentToken_);
    collateralLending = new NFTCollateralLending(paymentToken_);
    airdrop = new NFTAirdrop();
    timeLock = new NFTTimeLock();

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(OPERATOR_ROLE, msg.sender);
  }

  /// @notice 一次性接线：授权各模块、注入 Hub/NFT/Registry、授予 Hub 铸造权
  /// @dev 部署后必须由 admin 调用一次，否则模块无法 lockToken
  function wireCommerce() external onlyRole(DEFAULT_ADMIN_ROLE) {
    address nft = address(commercialNFT);
    address reg = address(recipientRegistry);
    address hub = address(this);

    INFTCommerceModule[] memory mods = new INFTCommerceModule[](8);
    mods[0] = INFTCommerceModule(address(custody));
    mods[1] = INFTCommerceModule(address(staking));
    mods[2] = INFTCommerceModule(address(proxyAuction));
    mods[3] = INFTCommerceModule(address(fractional));
    mods[4] = INFTCommerceModule(address(rental));
    mods[5] = INFTCommerceModule(address(collateralLending));
    mods[6] = INFTCommerceModule(address(airdrop));
    mods[7] = INFTCommerceModule(address(timeLock));

    for (uint256 i = 0; i < mods.length; i++) {
      commercialNFT.authorizeModule(address(mods[i]), true);
      mods[i].wireCommerce(hub, nft, reg);
    }

    commercialNFT.grantRole(commercialNFT.MINTER_ROLE(), hub);
    emit CommerceWired(nft, reg);
  }

  /// @notice 运营代用户铸造商业 NFT
  /// @param to 接收地址
  /// @param uri metadata URI
  /// @return tokenId 新 token 编号
  function mintCommercialNFT(address to, string calldata uri) external onlyRole(OPERATOR_ROLE) returns (uint256) {
    return commercialNFT.mintCommercial(to, uri);
  }

  /// @notice 登记商业接受方（写入 Registry 并设为 active）
  /// @param account 接受方地址
  /// @param role 角色常量（如 ROLE_BIDDER）
  /// @param label 备注
  function registerRecipient(address account, bytes32 role, string calldata label) external onlyRole(OPERATOR_ROLE) {
    recipientRegistry.setRecipient(account, role, true, label);
  }

  /// @notice 编排：托管库中的 NFT → 代拍上架
  /// @param tokenId NFT 编号（须已在 custody 合约中）
  /// @param consignor 委托人，须已登记 ROLE_CONSIGNOR
  /// @param custodian 托管商（记录用，须已 deposit 时指定）
  /// @param auctionSeconds 拍卖持续秒数
  function pipelineCustodyToAuction(uint256 tokenId, address consignor, address custodian, uint256 auctionSeconds)
    external
    onlyRole(OPERATOR_ROLE)
  {
    require(commercialNFT.ownerOfToken(tokenId) == address(custody), "hub: not in custody");
    custody.handoverToModule(
      tokenId, address(proxyAuction), ICommercialNFT.LockType.ProxyAuction, consignor
    );
    proxyAuction.listFromCustody(tokenId, consignor, auctionSeconds);
  }

  /// @notice 编排：托管 → 时间锁，到期释放给 beneficiary
  /// @param tokenId NFT 编号
  /// @param custodian 托管商（流程记录）
  /// @param beneficiary 到期接收人
  /// @param releaseAt 释放时间戳（须大于 block.timestamp）
  function pipelineCustodyToTimelock(uint256 tokenId, address custodian, address beneficiary, uint256 releaseAt)
    external
    onlyRole(OPERATOR_ROLE)
  {
    require(commercialNFT.ownerOfToken(tokenId) == address(custody), "hub: not in custody");
    custody.handoverToModule(tokenId, address(timeLock), ICommercialNFT.LockType.TimeLock, beneficiary);
    timeLock.scheduleReleaseHeld(tokenId, beneficiary, releaseAt);
  }

  /// @notice 编排：托管 → 碎片化
  /// @param tokenId NFT 编号
  /// @param owner 碎片化后份额归属人 / 原持有人
  /// @param totalShares 铸造份额总数
  /// @param buyoutPrice 全额回购 NFT 所需支付代币数量
  function pipelineCustodyToFractional(
    uint256 tokenId,
    address owner,
    uint256 totalShares,
    uint256 buyoutPrice
  ) external onlyRole(OPERATOR_ROLE) {
    require(commercialNFT.ownerOfToken(tokenId) == address(custody), "hub: not in custody");
    custody.handoverToModule(tokenId, address(fractional), ICommercialNFT.LockType.Fractional, owner);
    fractional.fractionalizeHeld(tokenId, owner, totalShares, buyoutPrice);
  }

  /// @notice 向质押合约充值奖励代币（需先 approve Hub）
  /// @param amount 转入 staking 合约的代币数量
  function fundStakingRewards(uint256 amount) external onlyRole(OPERATOR_ROLE) {
    IERC20(paymentToken()).transferFrom(msg.sender, address(staking), amount);
  }

  /// @notice 只读：返回平台支付代币地址（与 staking 使用同一 ERC-20）
  /// @return IERC20 支付代币接口
  function paymentToken() public view returns (IERC20) {
    return IERC20(address(staking.rewardToken()));
  }
}
