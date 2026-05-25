// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin-contracts-5.6.0/token/ERC20/ERC20.sol";
import {CommercialNFT} from "../../src/erc721/CommercialNFT.sol";
import {RecipientRegistry} from "../../src/erc721/RecipientRegistry.sol";
import {NFTCommerceHub} from "../../src/erc721/NFTCommerceHub.sol";
import {ICommercialNFT} from "../../src/erc721/interfaces/ICommercialNFT.sol";

contract MockPayToken is ERC20 {
  constructor() ERC20("Pay", "PAY") {
    _mint(msg.sender, 1_000_000 ether);
  }
}

contract CommercialNFTCommerceTest is Test {
  CommercialNFT internal nft;
  RecipientRegistry internal registry;
  MockPayToken internal pay;
  NFTCommerceHub internal hub;

  address internal admin = address(this);
  address internal alice = address(0xA1);
  address internal custodian = address(0xCUST);
  address internal consignor = address(0xC0N);

  function setUp() public {
    pay = new MockPayToken();
    nft = new CommercialNFT(admin);
    registry = new RecipientRegistry(admin);
    hub = new NFTCommerceHub(nft, registry, pay, 1 wei, 250);
    hub.wireCommerce();

    registry.setRecipient(custodian, registry.ROLE_CUSTODIAN(), true, "custodian");
    registry.setRecipient(consignor, registry.ROLE_CONSIGNOR(), true, "consignor");
    registry.setRecipient(alice, registry.ROLE_BIDDER(), true, "bidder");

    uint256 id = hub.mintCommercialNFT(alice, "ipfs://commercial/0");
    vm.prank(alice);
    nft.approve(address(hub.custody()), id);
  }

  function test_CustodyDepositAndAuctionPipeline() public {
    uint256 tokenId = 0;
    vm.prank(alice);
    hub.custody().deposit(tokenId, custodian);

    assertEq(
      uint8(nft.getLockInfo(tokenId).lockType),
      uint8(ICommercialNFT.LockType.Custody)
    );

    hub.pipelineCustodyToAuction(tokenId, consignor, custodian, 1 days);

    pay.transfer(alice, 1000 ether);
    vm.startPrank(alice);
    pay.approve(address(hub.proxyAuction()), 500 ether);
    hub.proxyAuction().bid(tokenId, 500 ether);
    vm.stopPrank();

    vm.warp(block.timestamp + 1 days);
    hub.proxyAuction().settle(tokenId);

    assertEq(nft.ownerOf(tokenId), alice);
  }
}
