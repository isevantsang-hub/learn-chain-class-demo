// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DemoERC20} from "../../erc20/DemoERC20.sol";

contract DemoERC20Test is Test {
  DemoERC20 internal token;
  address internal owner = address(0xA11CE);
  address internal bob = address(0xB0B);

  function setUp() public {
    vm.prank(owner);
    token = new DemoERC20(owner);
  }

  function test_InitialSupplyToOwner() public view {
    assertEq(token.balanceOf(owner), token.INITIAL_SUPPLY());
    assertEq(token.decimals(), 18);
  }

  function test_TransferAndApprove() public {
    vm.prank(owner);
    token.transfer(bob, 100 ether);

    assertEq(token.balanceOf(bob), 100 ether);

    vm.prank(bob);
    token.approve(owner, 50 ether);
    assertEq(token.allowance(bob, owner), 50 ether);

    vm.prank(owner);
    token.transferFrom(bob, owner, 50 ether);
    assertEq(token.balanceOf(bob), 50 ether);
  }
}
