// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =============================================================================
// 统一部署脚本 — 用法示例（在项目根目录执行）：
//
//   本地 Anvil（需先启动 anvil；若 8545 被占用可改用 --port 8546 并改 rpc-url）：
//   forge script script/DeployAll.s.sol:DeployAll \
//     --rpc-url http://127.0.0.1:8545 --broadcast \
//     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
//
//   仅模拟、不上链（去掉 --broadcast）：
//   forge script script/DeployAll.s.sol:DeployAll --rpc-url http://127.0.0.1:8545
//
//   Sepolia（需配置 .env 中 SEPOLIA_RPC_URL，并使用你自己的测试私钥）：
//   forge script script/DeployAll.s.sol:DeployAll --rpc-url sepolia --broadcast --private-key $PRIVATE_KEY
// =============================================================================

import {Script, console2} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";
import {Token10000WithCallbacks} from "../src/Token10000WithCallbacks.sol";
import {CallbackReceiverDemo} from "../src/CallbackReceiverDemo.sol";
import {SimpleWallet} from "../src/SimpleWallet.sol";

/// @notice 一次性部署 `src/` 下四个示例合约（`IERC1363*.sol` 为接口，无需部署）。
contract DeployAll is Script {
    function run() public {
        vm.startBroadcast();

        Counter counter = new Counter();
        Token10000WithCallbacks token = new Token10000WithCallbacks();
        CallbackReceiverDemo receiver = new CallbackReceiverDemo();
        SimpleWallet wallet = new SimpleWallet();

        vm.stopBroadcast();

        console2.log("=== Deployed addresses ===");
        console2.log("Counter", address(counter));
        console2.log("Token10000WithCallbacks", address(token));
        console2.log("CallbackReceiverDemo", address(receiver));
        console2.log("SimpleWallet", address(wallet));
    }
}
