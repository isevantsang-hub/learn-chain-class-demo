// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {CrossAssetHub} from "../../integration/CrossAssetHub.sol";
import {DemoERC20Permit} from "../../erc2612/DemoERC20Permit.sol";
import {DemoERC1155} from "../../erc1155/DemoERC1155.sol";
import {DemoERC721} from "../../erc721/DemoERC721.sol";

contract CrossAssetHubTest is Test {
  uint256 internal userPk = 0xBEEF;
  address internal user;
  DemoERC20Permit internal payment;
  DemoERC1155 internal badges;
  DemoERC721 internal membership;
  CrossAssetHub internal hub;

  bytes32 internal constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  function setUp() public {
    user = vm.addr(userPk);
    payment = new DemoERC20Permit(address(this));
    badges = new DemoERC1155(address(this));
    membership = new DemoERC721(address(this));
    hub = new CrossAssetHub(payment, badges, membership);
    badges.transferOwnership(address(hub));
    membership.transferOwnership(address(hub));

    payment.transfer(user, 10_000 ether);
  }

  function test_DepositMintsGoldBadge() public {
    vm.startPrank(user);
    payment.approve(address(hub), 500 ether);
    hub.deposit(500 ether);
    vm.stopPrank();

    assertEq(badges.balanceOf(user, badges.ID_GOLD()), 50);
    assertEq(membership.balanceOf(user), 0);
  }

  function test_LargeDepositMintsMembershipAndGold() public {
    vm.startPrank(user);
    payment.approve(address(hub), 2_000 ether);
    hub.deposit(2_000 ether);
    vm.stopPrank();

    assertEq(membership.balanceOf(user), 1);
    assertEq(badges.balanceOf(user, badges.ID_GOLD()), 200);
  }

  function test_DepositWithPermit() public {
    uint256 amount = 300 ether;
    uint256 deadline = block.timestamp + 1 hours;

    bytes32 structHash =
      keccak256(abi.encode(PERMIT_TYPEHASH, user, address(hub), amount, payment.nonces(user), deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", payment.DOMAIN_SEPARATOR(), structHash));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

    vm.prank(user);
    hub.depositWithPermit(amount, deadline, v, r, s);

    assertEq(badges.balanceOf(user, badges.ID_GOLD()), 30);
  }
}
