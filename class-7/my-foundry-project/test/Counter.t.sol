// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/Script.sol";
import {console} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        console2.log(unicode"CounterTest.现在在setUp:");
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }






    function testFuzz_SetNumber(uint256 x) public {
        console2.log(unicode"int256 x: testFuzz_SetNumber ", x);
        counter.setNumber(x);
        console2.log(unicode"CounterTest.现在在testFuzz_SetNumber: %" , counter.number());
        assertEq(counter.number(), x);

    }


    function test_SetNumber123(uint256 x) public {
        console2.log(unicode" test_SetNumber123 int256 x: ", x);
        counter.setNumber(x);
        console2.log(unicode"CounterTest.test_SetNumber123: %" , counter.number());
        assertEq(counter.number(), x);
    }

    function testFuzz_SetNumber123(uint256 x) public {
        console2.log(unicode" testFuzz_SetNumber123 int256 x: ", x);
        counter.setNumber(x);
        console2.log(unicode"CounterTest.testFuzz_SetNumber123: %" , counter.number());
        assertEq(counter.number(), x);
    }




    function test_Roll() public {
        counter.increment();
        assertEq(counter.number(), 1);

        uint256 newBlockNumber = block.number + 1;
        vm.roll(newBlockNumber);
        console2.log(unicode"CounterTest.现在在test_Roll:");
        console2.log(unicode"after roll Block number:", block.number);

        assertEq(block.number, newBlockNumber);
        assertEq(counter.number(), 1);
    }

    function test_Fork() public {
        console2.log(
            unicode"CounterTest test_Fork  block.number:",
            block.number
        );
        uint256 forkBlockNumber = block.number + 1;
        vm.roll(forkBlockNumber);
        console2.log(unicode"CounterTest.现在在test_Fork:");
        console2.log(unicode"after roll Block number:", block.number);

        assertEq(block.number, forkBlockNumber);
        assertEq(counter.number(), 0);
    }

    function test_Warp() public {
        console2.log(
            unicode"CounterTest.现在在test_Warp: block.timestamp",
            block.timestamp
        );
        uint256 targetTimestamp = block.timestamp + 1 days;
        vm.warp(targetTimestamp);
        console2.log(unicode"CounterTest.现在在test_Warp:");
        console2.log(unicode"after warp Timestamp:", block.timestamp);

        assertEq(block.timestamp, targetTimestamp);

        skip(1000);
        console2.log(
            unicode"CounterTest.现在在test_Warp: after skip 1000 seconds, block.timestamp",
            block.timestamp
        );
        assertEq(block.timestamp, targetTimestamp + 1000);
    }

    function test_Prank() public {
        console2.log(
            unicode"CounterTest.现在在test_Prank: before prank, msg.sender:",
            msg.sender
        );

        console2.log(
            unicode"CounterTest.现在在test_Prank: before prank, address:",
            address(this)
        );

        address prankAddress = address(0x1234);
        vm.prank(prankAddress);
        counter.increment();
        console2.log(unicode"CounterTest.现在在test_Prank:");
        console2.log(unicode"after prank, msg.sender:", prankAddress);
        assertEq(counter.number(), 1);
    }
}
