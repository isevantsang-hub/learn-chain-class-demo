// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {DemoERC721} from "../../erc721/DemoERC721.sol";

contract DemoERC721Test is Test {
  DemoERC721 internal nft;
  address internal owner = address(0xA11CE);
  address internal alice = address(0xA1);

  function setUp() public {
    vm.prank(owner);
    nft = new DemoERC721(owner);
  }

  function test_MintAndTransfer() public {
    vm.prank(owner);
    uint256 id = nft.mint(alice, "ipfs://demo/0.json");
    assertEq(nft.ownerOf(id), alice);

    address bob = address(0xB0B);
    vm.prank(alice);
    nft.safeTransferFrom(alice, bob, id);
    assertEq(nft.ownerOf(id), bob);
  }
}
