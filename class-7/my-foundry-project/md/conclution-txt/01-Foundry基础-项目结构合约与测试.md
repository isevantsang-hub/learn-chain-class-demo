# 第 1 章：Foundry 基础——项目结构、合约与测试

## 1.1 工具与目录

- 安装 [Foundry](https://book.getfoundry.sh/getting-started/installation)（`forge`、`cast`、`anvil`）。
- 从零创建项目：`forge init my-project && cd my-project`。
- 常用目录：
  - **`src/`**：合约源码  
  - **`test/`**：测试  
  - **`script/`**：部署 / 链上脚本  
  - **`foundry.toml`**：编译器、优化、RPC 别名、`fs_permissions` 等  

本仓库使用 **Soldeer** 管理依赖（`dependencies/`）；与经典 `lib/` + `forge install` 二选一即可。

---

## 1.2 最小合约示例（Counter）

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
```

保存为 `src/Counter.sol`，在项目根执行：

```bash
forge build
```

---

## 1.3 基本测试

测试继承 **`forge-std/Test.sol`**，`setUp` 里部署合约，测试函数名以 **`test`** 或 **`testFuzz`** 开头。

```bash
forge test
forge test -vv
```

链上已部署的合约实例**不会**自动被 `forge test` 使用；`forge test` 只在本地 EVM 里跑测试合约。

---

## 1.4 部署脚本（概念）

脚本继承 **`forge-std/Script.sol`**，典型流程：解析部署者 → **`vm.startBroadcast(deployer)`** → **`new Counter()`** → **`vm.stopBroadcast()`**。  
仅模拟发链（不写链）时不加 **`--broadcast`**：

```bash
forge script script/DeployCounter.s.sol:DeployCounter --rpc-url http://127.0.0.1:8545
```

具体与环境变量、Keystore 的配合见 **第 2～6 章**。
