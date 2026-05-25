// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DemoERC777} from "../../erc777/DemoERC777.sol";
import {ERC777Vault} from "../../erc777/ERC777Vault.sol";
import {ERC1820RegistryMinimal} from "../../erc777/IERC1820RegistryMinimal.sol";

contract DemoERC777Test is Test {
  ERC1820RegistryMinimal internal registry;
  DemoERC777 internal token;
  ERC777Vault internal vault;
  address internal alice = address(0xA1);
  address internal bob = address(0xB0B);

  function setUp() public {
    registry = new ERC1820RegistryMinimal();
    address[] memory ops = new address[](0);
    token = new DemoERC777("Demo777", "D777", 1_000 ether, ops, address(registry));
    vault = new ERC777Vault(address(registry));
    token.send(alice, 500 ether, "");
  }

  function test_SendToEOA() public {
    vm.prank(alice);
    token.send(bob, 100 ether, "");
    assertEq(token.balanceOf(bob), 100 ether);
  }

  function test_SendToVaultTriggersHook() public {
    vm.prank(alice);
    token.send(address(vault), 50 ether, "");
    assertEq(vault.totalReceived(), 50 ether);
    assertEq(vault.lastSender(), alice);
  }
}
