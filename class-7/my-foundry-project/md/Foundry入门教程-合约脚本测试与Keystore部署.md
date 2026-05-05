# Foundry 智能合约开发入门教程（合约 + 脚本 + 测试 + MetaMask 与 Keystore 部署）

本教程面向初学者，给出一套**最小可跑通**的流程：编写合约、写脚本、写测试、把 MetaMask 侧密钥转为 Keystore（JSON）、再用脚本部署。**不涉及修改你仓库里已有源码**，仅作通用示范；你可对照本仓库中的 `src/Counter.sol`、`test/Counter.t.sol` 与部署脚本自行比对。

---

## 一、环境与项目骨架

1. 安装 [Foundry](https://book.getfoundry.sh/getting-started/installation)（含 `forge`、`cast`、`anvil`）。
2. 新建项目（若从零开始）：
   ```bash
   forge init my-project
   cd my-project
   ```
3. 默认目录含义简述：
   - `src/`：合约源码  
   - `test/`：测试（`*Test` / `test_*`）  
   - `script/`：部署或链上操作脚本  
   - `foundry.toml`：编译器版本、优化、RPC 别名、`fs_permissions` 等  

依赖管理可选用 **Soldeer**（本仓库用法）或 **forge install**，二者选其一即可；教程不强制某一种。

---

## 二、基本合约案例（Counter）

下面是一份典型的「计数器」合约，逻辑极简，便于专注工具链：

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

保存为例如 `src/Counter.sol`，然后在本项目根目录执行：

```bash
forge build
```

编译成功即表示 Solidity 与 `foundry.toml` 配置可用。

---

## 三、基本测试类

测试继承 `forge-std/Test.sol`，常用模式：`setUp` 里部署合约，测试函数以 `test` 或 `testFuzz` 开头。

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
```

保存为 `test/Counter.t.sol`，运行：

```bash
forge test
forge test -vv   # 更详细日志
```

---

## 四、基本部署脚本（思路）

脚本继承 `forge-std/Script.sol`，入口一般为 `run()`。典型步骤：

1.（可选）确定部署者地址、检查余额。  
2. `vm.startBroadcast(...)` 包裹需要上链的调用。  
3. `new YourContract()` 部署。  
4. `vm.stopBroadcast()`。

伪代码结构如下（具体字段名以你项目为准）：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {Counter} from "../src/Counter.sol";

contract DeployCounter is Script {
    function run() external {
        vm.startBroadcast(); // 或由 env / keystore 推导出的 deployer 传入 startBroadcast(deployer)
        Counter c = new Counter();
        vm.stopBroadcast();
        console2.log("Deployed at:", address(c));
    }
}
```

保存为 `script/DeployCounter.s.sol`，仅模拟运行（不发交易）：

```bash
forge script script/DeployCounter.s.sol:DeployCounter --rpc-url http://127.0.0.1:8545
```

---

## 五、MetaMask 私钥与 Keystore 的关系（重要）

- **MetaMask 面向浏览器**，通常导出的是：**账户私钥（hex）**或 **助记词**，**不会直接导出**与 Geth/Cast 相同格式的 **JSON Keystore 文件**。  
- **Foundry / 以太坊节点常用 Keystore**：磁盘上一个 **加密的 JSON 文件**，内含 `address`、`crypto`、`version` 等字段，由 **`cast wallet import`** 等工具生成或兼容 Geth 导出格式。

**推荐做法（开发环境）：**

1. 在 MetaMask 中仅使用**测试专用账户**，导出该账户的 **私钥**（界面：账户详情 → 导出私钥；务必远离主网大额资产）。  
2. 在终端用 **Cast** 把私钥导入为加密 Keystore（交互式输入密码更安全）：
   ```bash
   cast wallet import dev-account --interactive
   ```
   按提示粘贴私钥并设置密码。完成后会在 Foundry 默认密钥目录下生成 **JSON 文件**（具体路径以 `cast wallet list` 或文档为准）。  
3. **不要**把 Keystore 或私钥提交到 Git；`.gitignore` 中应忽略 `*.json` 密钥文件或专用目录。

若你希望「文件路径固定」，可把生成的 JSON **复制到项目下的专用目录**（例如 `secrets/`，且已加入 `.gitignore`），便于设置 `KEYSTORE_PATH`。

---

## 六、Keystore + 脚本部署指南（命令级）

### 1. 本地链（可选）

```bash
anvil
```

默认 RPC 一般为 `http://127.0.0.1:8545`。另开终端继续下面步骤。

### 2. 环境变量（示例）

```bash
export LOCAL_RPC_URL="http://127.0.0.1:8545"
export KEYSTORE_PATH="/绝对路径/到你的-keystore.json"
```

若脚本里使用 **`vm.readFile(KEYSTORE_PATH)`**，需在 **`foundry.toml`** 中为该路径所在目录配置 **`fs_permissions`** 读权限（详见本目录下《部署脚本-keystore-方案》）。

### 3. 给 Anvil 账号充值（测试用）

Anvil 会打印若干测试私钥；可将其中一号充值到你的部署地址（简化起见也可用脚本只部署到 Anvil 默认 funded 账户，此处略）。实际操作时常用 `cast send` 或脚本预先 `deal`（测试环境 cheat）。

### 4. 广播部署

```bash
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$LOCAL_RPC_URL" \
  --broadcast \
  --keystore "$KEYSTORE_PATH"
```

要点：

- **`KEYSTORE_PATH`**（脚本里若读取 JSON 取 `address`）与 **`--keystore`**（CLI 用来签名）应指向**同一文件**，否则 `msg.sender` / 广播签名可能与脚本里假设的 `deployer` 不一致。  
- Keystore **带密码**时，按当前 Foundry 版本说明通过交互或支持的环境变量提供密码（勿在公共场合明文保存密码）。

### 5. 验证

- 控制台应打印合约地址；也可用 `cast code <address> --rpc-url $LOCAL_RPC_URL` 查看链上是否有代码。

---

## 七、能力对照表（学完应能做到）

| 步骤           | 命令或动作 |
|----------------|------------|
| 编译           | `forge build` |
| 测试           | `forge test` |
| 模拟脚本       | `forge script ...`（不加 `--broadcast`） |
| 本地节点       | `anvil` |
| 私钥 → Keystore | `cast wallet import ...` |
| 链上部署       | `forge script ... --broadcast --keystore ...` |

---

## 八、安全提示（必读）

1. **主网真实资产**不要用教程里的「明文私钥粘贴」「共享测试脚本」等方式草率操作。  
2. Keystore 密码与文件权限仅限本机；备份策略自行负责。  
3. 任何示例地址、RPC、路径请替换为你自己的环境与测试网络。

---

更多与本仓库脚本细节（例如 `readFile`、`StdJson` 解析 `address`、`fs_permissions` 写法）可参考同目录下的 **`部署脚本-keystore-方案.md`**。
