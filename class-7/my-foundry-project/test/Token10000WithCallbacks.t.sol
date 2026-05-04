// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Token10000WithCallbacks} from "../src/Token10000WithCallbacks.sol";
import {CallbackReceiverDemo} from "../src/CallbackReceiverDemo.sol";

contract Token10000WithCallbacksTest is Test {
    event TransferCallback(address indexed operator, address indexed from, uint256 value, bytes data);
    event ApprovalCallback(address indexed owner, uint256 value, bytes data);

    Token10000WithCallbacks internal token;
    address internal holder;

    function setUp() public {
        holder = address(this);
        token = new Token10000WithCallbacks();
    }

    function test_initialSupplyMintedToDeployer() public view {
        uint256 supply = token.INITIAL_SUPPLY();
        assertEq(token.balanceOf(holder), supply);
        assertEq(token.totalSupply(), supply);
    }

    function test_transferAndCall_toContract_invokesCallback() public {
        CallbackReceiverDemo recv = new CallbackReceiverDemo();
        uint256 amount = 10 * 10 ** 18;

        vm.expectEmit(true, true, false, true);
        emit TransferCallback(holder, holder, amount, hex"01");
        token.transferAndCall(address(recv), amount, hex"01");

        assertEq(token.balanceOf(address(recv)), amount);
        assertEq(token.balanceOf(holder), token.INITIAL_SUPPLY() - amount);
    }

    function test_transferAndCall_revertsWhenRecipientIsEOA() public {
        address eoa = address(0xE0A);
        vm.assume(eoa.code.length == 0);

        vm.expectRevert(bytes("ERC1363: transfer to non-contract"));
        token.transferAndCall(eoa, 1 ether);
    }

    function test_approveAndCall_invokesSpenderCallback() public {
        CallbackReceiverDemo spender = new CallbackReceiverDemo();
        uint256 value = 50 * 10 ** 18;

        vm.expectEmit(true, false, false, true);
        emit ApprovalCallback(holder, value, hex"02");
        token.approveAndCall(address(spender), value, hex"02");

        assertEq(token.allowance(holder, address(spender)), value);
    }

    function test_approveAndCall_revertsWhenSpenderIsEOA() public {
        address eoa = address(0xE0B);
        vm.assume(eoa.code.length == 0);

        vm.expectRevert(bytes("ERC1363: approve to non-contract"));
        token.approveAndCall(eoa, 1 ether, "");
    }

    function test_transferFromAndCall_operatorPath() public {
        CallbackReceiverDemo recv = new CallbackReceiverDemo();
        address alice = address(0xA11CE);
        uint256 amount = 20 * 10 ** 18;

        token.transfer(alice, amount);
        vm.prank(alice);
        token.approve(holder, amount);

        vm.expectEmit(true, true, false, true);
        emit TransferCallback(holder, alice, amount, "");
        token.transferFromAndCall(alice, address(recv), amount, "");

        assertEq(token.balanceOf(address(recv)), amount);
        assertEq(token.balanceOf(alice), 0);
    }
}
