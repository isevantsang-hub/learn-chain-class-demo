// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract DeployCounterErrorversion is Script {
    function run() public {
        // 获取部署者地址（从 keystore）
        address deployer = msg.sender;
        console2.log("Deployer:", deployer);
        
        // 开始广播交易
        vm.startBroadcast(deployer);
        
        // 部署合约
        Counter counter = new Counter();
        
        // 停止广播
        vm.stopBroadcast();
        
        console2.log("Counter deployed at:", address(counter));
    }
}