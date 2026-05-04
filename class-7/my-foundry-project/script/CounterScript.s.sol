// script/CounterScript.s.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract CounterScript is Script {
    function run() public returns (address) {
        // 注意：这里不处理 keystore，直接从环境变量获取地址
        // 或者让 Foundry 自动处理
        
        // 方法1: 从环境变量获取地址
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        
        // 方法2: 如果没有设置，使用默认测试账户
        if (deployer == address(0)) {
            deployer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Anvil 第一个账户
        }
        
        console2.log(unicode"部署者地址:", deployer);
        console2.log(unicode"部署者余额:", deployer.balance);
        
        // 检查余额
        require(deployer.balance > 0.1 ether, unicode"余额不足");
        
        // 开始广播交易
        // 注意：当通过命令行使用 --keystore 时，
        // Foundry 会自动将 keystore 中的地址用于签名
        vm.startBroadcast(deployer);
        
        // 部署合约
        Counter counter = new Counter();
        
        // 停止广播
        vm.stopBroadcast();
        
        console2.log(unicode"Counter 合约已部署到:", address(counter));
        
        return address(counter);
    }
}