// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    function setUp() public {
        owner = address(0xA11CE);
        alice = address(0xB0B);
        bob = address(0xC0DE);
        charlie = address(0xD00D);

        vm.deal(owner, 10 ether);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);

        bank = new Bank(owner);
    }

    function test_initialState() public view {
        assertEq(bank.getContractBalance(), 0);
        assertEq(bank.allAmount(), 0);
        assertEq(bank.topDepositAmounts(0), 0);
        assertEq(bank.topDepositAmounts(1), 0);
        assertEq(bank.topDepositAmounts(2), 0);
        assertEq(bank.topDepositors(0), address(0));
        assertEq(bank.topDepositors(1), address(0));
        assertEq(bank.topDepositors(2), address(0));
    }

    function test_deposit_updatesBalancesAndTopDepositors() public {
        vm.prank(alice);
        (bool success,) = address(bank).call{value: 1 ether}("");
        require(success);

        assertEq(bank.balances(alice), 1 ether);
        assertEq(bank.allAmount(), 1 ether);
        assertEq(bank.getContractBalance(), 1 ether);
        assertEq(bank.topDepositors(0), alice);
        assertEq(bank.topDepositAmounts(0), 1 ether);
    }

    function test_deposit_multipleUsers_maintainsTop3Order() public {
        vm.prank(alice);
        (bool successA,) = address(bank).call{value: 1 ether}("");
        require(successA);

        vm.prank(bob);
        (bool successB,) = address(bank).call{value: 2 ether}("");
        require(successB);

        vm.prank(charlie);
        (bool successC,) = address(bank).call{value: 1.5 ether}("");
        require(successC);

        assertEq(bank.topDepositors(0), bob);
        assertEq(bank.topDepositAmounts(0), 2 ether);
        assertEq(bank.topDepositors(1), charlie);
        assertEq(bank.topDepositAmounts(1), 1.5 ether);
        assertEq(bank.topDepositors(2), alice);
        assertEq(bank.topDepositAmounts(2), 1 ether);
    }

    function test_withdraw_reducesBalanceAndAllAmount() public {
        vm.prank(alice);
        (bool success,) = address(bank).call{value: 2 ether}("");
        require(success);

        vm.prank(alice);
        bank.withdraw(1 ether);

        assertEq(bank.balances(alice), 1 ether);
        assertEq(bank.allAmount(), 1 ether);
        assertEq(bank.getContractBalance(), 1 ether);
    }

    function test_withdraw_revertsWhenInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Insufficient balance"));
        bank.withdraw(1 ether);
    }

    function test_withdrawAll_ownerCanWithdrawAndResetRankings() public {
        vm.prank(alice);
        (bool successA,) = address(bank).call{value: 1 ether}("");
        require(successA);

        vm.prank(bob);
        (bool successB,) = address(bank).call{value: 1.5 ether}("");
        require(successB);

        uint256 balanceBefore = owner.balance;

        vm.prank(owner);
        bank.withdrawAll();

        assertEq(bank.allAmount(), 0);
        assertEq(bank.getContractBalance(), 0);
        assertEq(bank.topDepositors(0), address(0));
        assertEq(bank.topDepositors(1), address(0));
        assertEq(bank.topDepositors(2), address(0));
        assertEq(bank.topDepositAmounts(0), 0);
        assertEq(bank.topDepositAmounts(1), 0);
        assertEq(bank.topDepositAmounts(2), 0);
        assertEq(owner.balance, balanceBefore + 2.5 ether);
    }

    function test_withdrawAll_revertsForNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(bytes("Not owner"));
        bank.withdrawAll();
    }

    function test_deposit_existingTopDepositor_keepsRanking() public {
        vm.prank(alice);
        (bool successA,) = address(bank).call{value: 1 ether}("");
        require(successA);

        vm.prank(alice);
        (bool successB,) = address(bank).call{value: 2 ether}("");
        require(successB);

        assertEq(bank.balances(alice), 3 ether);
        assertEq(bank.topDepositors(0), alice);
        assertEq(bank.topDepositAmounts(0), 3 ether);
    }
}
