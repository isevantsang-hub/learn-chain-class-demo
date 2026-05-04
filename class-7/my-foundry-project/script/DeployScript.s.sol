// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
import {Script} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
 
contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();
        
        Counter counter = new Counter();
        counter.setNumber(42);
        
        vm.stopBroadcast();
    }
}