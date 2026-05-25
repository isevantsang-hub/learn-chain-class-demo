// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DemoERC20Permit} from "../../erc2612/DemoERC20Permit.sol";

contract DemoERC20PermitTest is Test {
  DemoERC20Permit internal token;
  address internal owner;
  uint256 internal ownerPk;
  address internal spender = address(0xDEAD);

  bytes32 internal constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  function setUp() public {
    ownerPk = 0xA11CE;
    owner = vm.addr(ownerPk);
    vm.prank(owner);
    token = new DemoERC20Permit(owner);
  }

  function test_PermitSetsAllowance() public {
    uint256 value = 100 ether;
    uint256 deadline = block.timestamp + 1 hours;

    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, token.nonces(owner), deadline));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", token.DOMAIN_SEPARATOR(), structHash));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

    token.permit(owner, spender, value, deadline, v, r, s);
    assertEq(token.allowance(owner, spender), value);

    vm.prank(spender);
    token.transferFrom(owner, spender, value);
    assertEq(token.balanceOf(spender), value);
  }
}
