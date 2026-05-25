// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {LearnNFT} from "../src/LearnNFT.sol";

/// @dev 在 `.env` 中配置 `PRIVATE_KEY`；或使用 `forge script ... --private-key` 覆盖。
contract DeployLearnNFT is Script {
    function run() external returns (LearnNFT nft) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        vm.startBroadcast(pk);
        nft = new LearnNFT(deployer);
        console2.log("LearnNFT:", address(nft));
        vm.stopBroadcast();
    }
}
