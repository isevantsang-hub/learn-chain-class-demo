// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {LearnNFT} from "../src/LearnNFT.sol";

contract LearnNFTTest is Test {
    LearnNFT internal nft;
    address internal owner = address(0xA11CE);
    address internal alice = address(0xA1);

    function setUp() public {
        vm.prank(owner);
        nft = new LearnNFT(owner);
    }

    function test_MintSetsOwnerAndUri() public {
        vm.prank(owner);
        uint256 id = nft.mint(alice, "ipfs://QmExample/0.json");
        assertEq(id, 0);
        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.tokenURI(0), "ipfs://QmExample/0.json");
        assertEq(nft.totalMinted(), 1);
    }

    function test_RevertWhenNotOwnerMints() public {
        vm.prank(alice);
        vm.expectRevert();
        nft.mint(alice, "x");
    }

    function test_TransferUpdatesBalance() public {
        vm.startPrank(owner);
        nft.mint(alice, "ipfs://a");
        vm.stopPrank();

        address bob = address(0xB0B);
        vm.prank(alice);
        nft.safeTransferFrom(alice, bob, 0);

        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.balanceOf(bob), 1);
        assertEq(nft.ownerOf(0), bob);
    }
}
