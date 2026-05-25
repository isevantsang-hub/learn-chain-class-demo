// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DemoERC1155} from "../../erc1155/DemoERC1155.sol";

contract DemoERC1155Test is Test {
  DemoERC1155 internal token;
  address internal owner = address(0xA11CE);
  address internal alice = address(0xA1);

  function setUp() public {
    vm.prank(owner);
    token = new DemoERC1155(owner);
  }

  function test_BalanceOfBatch() public {
    vm.startPrank(owner);
    token.mintGold(alice, 1000);
    token.mintCard(alice, 1);
    vm.stopPrank();

    assertEq(token.balanceOf(alice, token.ID_GOLD()), 1000);
    assertEq(token.balanceOf(alice, token.ID_CARD()), 1);

    uint256[] memory ids = new uint256[](2);
    ids[0] = token.ID_GOLD();
    ids[1] = token.ID_CARD();
    address[] memory accounts = new address[](2);
    accounts[0] = alice;
    accounts[1] = alice;

    uint256[] memory balances = token.balanceOfBatch(accounts, ids);
    assertEq(balances[0], 1000);
    assertEq(balances[1], 1);
  }

  function test_SafeBatchTransfer() public {
    vm.startPrank(owner);
    token.mintGold(alice, 500);
    vm.stopPrank();

    address bob = address(0xB0B);
    uint256[] memory ids = new uint256[](1);
    ids[0] = token.ID_GOLD();
    uint256[] memory amounts = new uint256[](1);
    amounts[0] = 200;

    vm.prank(alice);
    token.safeBatchTransferFrom(alice, bob, ids, amounts, "");

    assertEq(token.balanceOf(bob, token.ID_GOLD()), 200);
  }
}
