// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC1363Token} from "../src/ERC1363Token.sol";
import {BankWithToken} from "../src/BankWithToken.sol";
import {IERC1363} from "../src/IERC1363.sol";

contract BankWithTokenTest is Test {
    ERC1363Token public token;
    BankWithToken public bank;
    address public alice = address(0xA11CE);

    function setUp() public {
        token = new ERC1363Token();
        bank = new BankWithToken(IERC1363(address(token)));
        token.transfer(alice, 20_000 * 10 ** 18);
    }

    function test_bankReceivesDepositWithTransferAndCall() public {
        vm.prank(alice);
        token.transferAndCall(address(bank), 2_000 * 10 ** 18, "");

        assertEq(bank.deposits(alice), 2_000 * 10 ** 18);
        assertEq(token.balanceOf(address(bank)), 2_000 * 10 ** 18);
    }

    function test_bankReceivesDepositWithApproveAndCall() public {
        vm.prank(alice);
        token.approveAndCall(address(bank), 3_000 * 10 ** 18, "");

        assertEq(bank.deposits(alice), 3_000 * 10 ** 18);
        assertEq(token.balanceOf(address(bank)), 3_000 * 10 ** 18);
    }

    function test_withdrawToken_returnsDepositedTokens() public {
        vm.prank(alice);
        token.transferAndCall(address(bank), 1_000 * 10 ** 18, "");

        vm.prank(alice);
        bank.withdrawToken(500 * 10 ** 18);

        assertEq(bank.deposits(alice), 500 * 10 ** 18);
        assertEq(token.balanceOf(alice), 19_500 * 10 ** 18);
    }

    function test_withdrawToken_revertsWhenInsufficient() public {
        vm.prank(alice);
        token.transferAndCall(address(bank), 100 * 10 ** 18, "");

        vm.prank(alice);
        vm.expectRevert(bytes("Bank: insufficient deposit"));
        bank.withdrawToken(200 * 10 ** 18);
    }

    function test_recoverTokens_onlyOwnerCanRecoverExcess() public {
        token.transfer(address(bank), 1_000 * 10 ** 18);
        uint256 balanceBefore = token.balanceOf(address(this));

        bank.recoverTokens(1_000 * 10 ** 18);

        assertEq(token.balanceOf(address(bank)), 0);
        assertEq(token.balanceOf(address(this)), balanceBefore + 1_000 * 10 ** 18);
    }

    function test_recoverTokens_revertsForNonOwner() public {
        token.transfer(address(bank), 1_000 * 10 ** 18);

        vm.prank(alice);
        vm.expectRevert(bytes("Bank: not owner"));
        bank.recoverTokens(1_000 * 10 ** 18);
    }
}
