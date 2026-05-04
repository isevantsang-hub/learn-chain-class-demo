// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {CallbackReceiverDemo} from "../src/CallbackReceiverDemo.sol";
import {Token10000WithCallbacks} from "../src/Token10000WithCallbacks.sol";

contract CallbackReceiverDemoTest is Test {
    event NativeReceived(address indexed from, uint256 amount);
    event TransferCallback(address indexed operator, address indexed from, uint256 value, bytes data);
    event ApprovalCallback(address indexed owner, uint256 value, bytes data);

    CallbackReceiverDemo internal receiver;

    function setUp() public {
        receiver = new CallbackReceiverDemo();
    }

    function test_nativeReceive_increasesBalance() public {
        uint256 amt = 1 ether;
        vm.deal(address(this), amt);
        (bool ok,) = payable(address(receiver)).call{value: amt}("");
        assertTrue(ok);
        assertEq(address(receiver).balance, amt);
    }

    function test_nativeReceive_emitsNativeReceived() public {
        uint256 amt = 0.1 ether;
        vm.deal(address(this), amt);
        vm.expectEmit(true, false, false, true);
        emit NativeReceived(address(this), amt);
        (bool ok,) = payable(address(receiver)).call{value: amt}("");
        assertTrue(ok);
    }

    function test_onTransferReceived_emitsTransferCallback() public {
        address operator = address(0xBEEF);
        address from = address(0xCAFE);
        uint256 value = 123;
        bytes memory data = hex"abcd";

        vm.expectEmit(true, true, false, true);
        emit TransferCallback(operator, from, value, data);
        vm.prank(operator);
        receiver.onTransferReceived(operator, from, value, data);
    }

    function test_onApprovalReceived_emitsApprovalCallback() public {
        address owner = address(0xFACE);
        uint256 value = 456;
        bytes memory data = hex"";

        vm.expectEmit(true, false, false, true);
        emit ApprovalCallback(owner, value, data);
        receiver.onApprovalReceived(owner, value, data);
    }

    function test_pullFrom_transfersFromOwnerWhenAllowanceSet() public {
        Token10000WithCallbacks token = new Token10000WithCallbacks();
        address alice = address(0xA11CE);
        uint256 amount = 100 * 10 ** 18;

        token.transfer(alice, amount);
        vm.startPrank(alice);
        token.approve(address(receiver), amount);
        vm.stopPrank();

        receiver.pullFrom(address(token), alice, amount);
        assertEq(token.balanceOf(address(receiver)), amount);
        assertEq(token.balanceOf(alice), 0);
    }
}
