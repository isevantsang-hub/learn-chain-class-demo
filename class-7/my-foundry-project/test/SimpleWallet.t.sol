// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";

contract SimpleWalletTest is Test {
    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    SimpleWallet internal wallet;
    address internal owner;

    function setUp() public {
        owner = address(this);
        wallet = new SimpleWallet();
    }

    receive() external payable {}

    function test_ownerIsDeployer() public view {
        assertEq(wallet.owner(), owner);
    }

    function test_deposit_viaReceive() public {
        uint256 amt = 2 ether;
        vm.deal(owner, amt);
        vm.expectEmit(true, false, false, true);
        emit Deposited(owner, amt);
        (bool ok,) = payable(address(wallet)).call{value: amt}("");
        assertTrue(ok);
        assertEq(wallet.getBalance(), amt);
    }

    function test_deposit_function() public {
        uint256 amt = 1 ether;
        vm.deal(owner, amt);
        vm.expectEmit(true, false, false, true);
        emit Deposited(owner, amt);
        wallet.deposit{value: amt}();
        assertEq(wallet.getBalance(), amt);
    }

    function test_withdraw_byOwner() public {
        uint256 amt = 3 ether;
        vm.deal(address(wallet), amt);
        uint256 beforeBal = owner.balance;
        vm.expectEmit(true, false, false, true);
        emit Withdrawn(owner, amt);
        wallet.withdraw(amt);
        assertEq(wallet.getBalance(), 0);
        assertEq(owner.balance, beforeBal + amt);
    }

    function test_withdraw_revertsWhenNotOwner() public {
        vm.deal(address(wallet), 1 ether);
        address stranger = address(0xB0B);
        vm.prank(stranger);
        vm.expectRevert(bytes("Not owner"));
        wallet.withdraw(1 ether);
    }

    function test_withdraw_revertsWhenInsufficientBalance() public {
        vm.expectRevert(bytes("Insufficient balance"));
        wallet.withdraw(1 wei);
    }
}
