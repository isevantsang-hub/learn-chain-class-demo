// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC1363Token} from "../src/ERC1363Token.sol";
import {BankWithToken} from "../src/BankWithToken.sol";
import {IERC1363} from "../src/IERC1363.sol";

contract ERC1363TokenTest is Test {
    ERC1363Token public token;
    BankWithToken public bank;
    address public alice = address(0xA11CE);

    function setUp() public {
        token = new ERC1363Token();
        bank = new BankWithToken(IERC1363(address(token)));
        token.transfer(alice, 20_000 * 10 ** 18);
    }

    function test_initialSupplyIsMinted() public view {
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
        assertEq(token.balanceOf(address(this)), token.INITIAL_SUPPLY() - 20_000 * 10 ** 18);
        assertEq(token.balanceOf(alice), 20_000 * 10 ** 18);
    }

    function test_transferAndCall_depositsToBank() public {
        vm.prank(alice);
        token.transferAndCall(address(bank), 2_000 * 10 ** 18, "");

        assertEq(token.balanceOf(address(bank)), 2_000 * 10 ** 18);
        assertEq(bank.deposits(alice), 2_000 * 10 ** 18);
    }

    function test_approveAndCall_depositsToBank() public {
        vm.prank(alice);
        token.approveAndCall(address(bank), 3_000 * 10 ** 18, "");

        assertEq(token.balanceOf(address(bank)), 3_000 * 10 ** 18);
        assertEq(bank.deposits(alice), 3_000 * 10 ** 18);
        assertEq(token.allowance(alice, address(bank)), 0);
    }

    function test_transferAndCall_revertsForEOARecipient() public {
        address eoa = address(0xE0A);
        vm.assume(eoa.code.length == 0);

        vm.prank(alice);
        vm.expectRevert(bytes("ERC1363: transfer to non-contract"));
        token.transferAndCall(eoa, 1 ether, "");
    }
}
