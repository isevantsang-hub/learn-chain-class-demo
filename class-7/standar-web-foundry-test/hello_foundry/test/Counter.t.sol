// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;
    uint256 testNumber;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
        testNumber = 33;
    }

    function test_Increment() public {
        counter.increment();
         assertEq(testNumber, 33);
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }

    function testFail_Subtract43() public {
        testNumber -= 43;
    }


    
}
