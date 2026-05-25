// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@openzeppelin-contracts-5.6.0/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/utils/SafeERC20.sol";
import {DemoERC1155} from "../erc1155/DemoERC1155.sol";
import {DemoERC721} from "../erc721/DemoERC721.sol";

/// @title CrossAssetHub — 串联 ERC-20 / 2612 / 1155 / 721 的演示金库
/// @notice 用户存入 ERC-20 → 按额度发放 1155 金币徽章或铸造 721 会员 NFT；可用 permit 免 approve 交易。
contract CrossAssetHub {
  using SafeERC20 for IERC20;

  IERC20 public immutable paymentToken;
  IERC20Permit public immutable paymentTokenPermit;
  DemoERC1155 public immutable badges;
  DemoERC721 public immutable membership;

  uint256 public constant MIN_BADGE_DEPOSIT = 100 ether;
  uint256 public constant MIN_MEMBERSHIP_DEPOSIT = 1_000 ether;
  uint256 public constant GOLD_PER_100_ETHER = 10;

  event Deposited(address indexed user, uint256 amount, bool membershipMinted, uint256 goldMinted);

  constructor(IERC20 paymentToken_, DemoERC1155 badges_, DemoERC721 membership_) {
    paymentToken = paymentToken_;
    paymentTokenPermit = IERC20Permit(address(paymentToken_));
    badges = badges_;
    membership = membership_;
  }

  function deposit(uint256 amount) external {
    paymentToken.safeTransferFrom(msg.sender, address(this), amount);
    _settleRewards(msg.sender, amount);
  }

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    paymentTokenPermit.permit(msg.sender, address(this), amount, deadline, v, r, s);
    paymentToken.safeTransferFrom(msg.sender, address(this), amount);
    _settleRewards(msg.sender, amount);
  }

  function _settleRewards(address user, uint256 amount) internal {
    bool mintedMembership;
    uint256 gold;

    if (amount >= MIN_MEMBERSHIP_DEPOSIT) {
      membership.mint(user, string.concat("ipfs://demo/member/", _toString(amount)));
      mintedMembership = true;
    }

    if (amount >= MIN_BADGE_DEPOSIT) {
      gold = (amount / 100 ether) * GOLD_PER_100_ETHER;
      if (gold > 0) {
        badges.mintGold(user, gold);
      }
    }

    emit Deposited(user, amount, mintedMembership, gold);
  }

  function _toString(uint256 value) internal pure returns (string memory) {
    if (value == 0) return "0";
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }
}
