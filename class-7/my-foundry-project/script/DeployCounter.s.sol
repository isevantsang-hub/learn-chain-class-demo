// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Counter} from "../src/Counter.sol";

/// @dev 仅支持 Keystore：`KEYSTORE_PATH` 指向账号 JSON；部署地址必须与该文件、`forge script --keystore` 为同一账户。
/// @dev 若 JSON 无顶层 `address`（常见于 cast import），请在运行前设置 `DEPLOYER_ADDRESS`，其值须来自同一文件的链下解析：
///      export DEPLOYER_ADDRESS=$(cast wallet address --keystore "$KEYSTORE_PATH")
contract DeployCounter is Script {
    using stdJson for string;

    function run() external {
        address deployer = getDeployerFromKeystoreOnly();
        console2.log("Deployer:", deployer);

        require(deployer.balance > 0.1 ether, "Insufficient balance");

        vm.startBroadcast(deployer);

        Counter counter = new Counter();

        vm.stopBroadcast();

        console2.log("Contract deployed at:", address(counter));
    }

    /// @notice 仅从 keystore 文件内的 `.address` 或与之配套的 `DEPLOYER_ADDRESS` 解析部署者；不使用私钥、Anvil、`getWallets()` 等其它来源。
    function getDeployerFromKeystoreOnly() internal view returns (address) {
        if (!vm.envExists("KEYSTORE_PATH")) {
            revert("KEYSTORE_PATH required");
        }
        string memory keystorePath = vm.envString("KEYSTORE_PATH");
        if (bytes(keystorePath).length == 0) {
            revert("KEYSTORE_PATH empty");
        }

        string memory json = vm.readFile(keystorePath);

        if (vm.keyExistsJson(json, ".address")) {
            return parseKeystoreAddressHex(json.readString(".address"));
        }

        // 用 string 版 envOr：部分环境下 envExists/envAddress 对 .env 加载不稳定；勿使用 envOr(..., bytes(""))。
        string memory deployerLiteral = vm.envOr("DEPLOYER_ADDRESS", string(""));
        if (bytes(deployerLiteral).length > 0) {
            return vm.parseAddress(deployerLiteral);
        }

        revert(
            'Keystore JSON has no ".address"; set DEPLOYER_ADDRESS in .env (avoid $(...) lines that break dotenv) or: export DEPLOYER_ADDRESS=$(cast wallet address --keystore "$KEYSTORE_PATH")'
        );
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
