// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Counter} from "../src/Counter.sol";

/// @dev Keystore：可用 KEYSTORE_PATH 读文件；若 JSON 无 `address` 字段，可用 CLI `--keystore` 解锁后由 `vm.getWallets()` 取地址。
/// @dev 本地 Anvil（31337）未配置密钥时可回落到公开测试私钥 #0。
contract DeployCounter is Script {
    using stdJson for string;

    uint256 internal constant ANVIL_DEFAULT_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    function run() external {
        address deployer = getDeployer();
        console2.log("Deployer:", deployer);

        require(deployer.balance > 0.1 ether, "Insufficient balance");

        vm.startBroadcast(deployer);

        Counter counter = new Counter();

        vm.stopBroadcast();

        console2.log("Contract deployed at:", address(counter));
    }

    function getDeployer() internal view returns (address) {
        // if (vm.envOr("PRIVATE_KEY", uint256(0)) != 0) {
        //     return vm.addr(vm.envUint("PRIVATE_KEY"));
        // }

        if (vm.envExists("KEYSTORE_PATH")) {
            string memory keystorePath = vm.envString("KEYSTORE_PATH");
            if (bytes(keystorePath).length > 0) {
                string memory json = vm.readFile(keystorePath);
                if (vm.keyExistsJson(json, ".address")) {
                    return parseKeystoreAddressHex(json.readString(".address"));
                }
            }
        }

        // CLI 传入的 --keystore / --private-key / ledger 等：Forge 会把解锁的钱包地址放进 getWallets()
        //（解决「keystore JSON 没有 .address」且 vm.env 读不到 DEPLOYER_ADDRESS」的情况）
        address[] memory wallets = vm.getWallets();
        if (wallets.length == 1) {
            return wallets[0];
        }
        if (wallets.length > 1) {
            revert("Multiple signers from CLI; pass --sender <address> or leave only one --keystore");
        }

        if (vm.envExists("DEPLOYER_ADDRESS")) {
            return vm.envAddress("DEPLOYER_ADDRESS");
        }

        if (block.chainid == 31337) {
            return vm.addr(ANVIL_DEFAULT_PRIVATE_KEY);
        }

        revert("No deployer: PRIVATE_KEY, KEYSTORE_PATH+CLI signer, DEPLOYER_ADDRESS, or Anvil");
    }

    function parseKeystoreAddressHex(string memory hexAddr) internal pure returns (address) {
        bytes memory b = bytes(hexAddr);
        bool has018Prefix = b.length >= 2 && b[0] == 0x30 && (b[1] == 0x78 || b[1] == 0x58);
        if (has018Prefix) {
            return vm.parseAddress(hexAddr);
        }
        return vm.parseAddress(string.concat("0x", hexAddr));
    }
}
