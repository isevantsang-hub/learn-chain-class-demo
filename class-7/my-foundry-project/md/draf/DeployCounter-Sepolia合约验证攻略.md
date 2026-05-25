# DeployCounter 脚本部署后：Sepolia 合约验证攻略

本文针对 **`script/DeployCounter.s.sol`** 的部署结果，说明如何在 **Sepolia** 上完成 **Etherscan 源码验证**。  
该脚本仅部署 **`src/Counter.sol` 中的 `Counter`**，**无构造函数参数**。

---

## 一、先确认「要验证的是什么」

| 项目 | 值 |
|------|-----|
| 合约路径与名称 | `src/Counter.sol` → **`Counter`** |
| 构造参数 | **无**（不必传 `--constructor-args`） |
| 编译器（以仓库 `foundry.toml` 为准） | **Solidity 0.8.20** |
| 优化器 | **开启**，**200 runs** |

若你实际修改过 `foundry.toml` 里的 `solc` / `optimizer` / `optimizer_runs`，验证时必须与**部署当次编译配置**一致，否则比对会失败。

---

## 二、前置条件

1. 已在项目根目录能成功执行 `forge build`。
2. `.env`（或当前 shell）中配置 **Sepolia Etherscan API Key**，且与 `foundry.toml` 中变量名一致：

   - `foundry.toml` 片段：`sepolia = { key = "${SEPOLIA_ETHERSCAN_API_KEY}" }`
   - 因此需设置：`SEPOLIA_ETHERSCAN_API_KEY=你的key`  
   - Key 在 [Etherscan API Keys](https://etherscan.io/myapikey) 申请；Sepolia 与主网共用同一类 key 即可。

3. 执行前进入项目根并加载环境变量：

```bash
cd /Users/evan/web3Code/learn-chain-class-demo/class-7/my-foundry-project
source .env
```

---

## 三、推荐方式：`forge verify-contract`（部署后补验证）

将 **`YOUR_COUNTER_ADDRESS`** 换成链上 `Counter` 地址（部署日志里的 `Contract deployed at:`，例如课内示例 `0xCe41FF0A4f093A70b098C6B9e28c3E6Eb9806f58`）。

```bash
cd /Users/evan/web3Code/learn-chain-class-demo/class-7/my-foundry-project
source .env

forge verify-contract \
  YOUR_COUNTER_ADDRESS \
  src/Counter.sol:Counter \
  --chain sepolia \
  --etherscan-api-key "$SEPOLIA_ETHERSCAN_API_KEY"
```

若 `foundry.toml` 的 `[etherscan]` 已写好且环境变量名匹配，也可省略 `--etherscan-api-key`，由 Foundry 自动读取（视版本而定，失败时再显式传入 key）。

**成功标志：** 终端出现类似 **`Contract successfully verified`**；浏览器打开：

`https://sepolia.etherscan.io/address/YOUR_COUNTER_ADDRESS#code`

应能看到 **Contract Source Code**。

---

## 四、可选：下次部署时顺带验证

在 `forge script ... --broadcast` 末尾增加 **`--verify`**，且保证 `[etherscan]` 与 API Key 已配置。广播成功后 Foundry 会尝试自动提交验证。

若出现 **`Could not detect deployment`** 类警告，多为浏览器索引延迟，Foundry 会重试；仍失败可等 1～2 分钟后单独执行第三节的 `forge verify-contract`。更细的说明见仓库内 **`md/conclution-txt/07-测试网验证警告与排查.md`**。

---

## 五、浏览器手动验证（CLI 失败时用）

1. 打开：`https://sepolia.etherscan.io/address/<你的地址>#code`  
2. 选择 **Verify and Publish**。  
3. **Compiler Type**：Solidity (Single file) 或 Standard JSON Input（Foundry 常用后者可从 `forge build` 产物中取；单文件需自行处理 import）。  
4. **Compiler Version**：`v0.8.20+commit.a1b79de6`（或与部署时完全一致的 patch）。  
5. **Optimization**：Yes，**200** runs。  
6. 粘贴与部署时一致的源码（或标准 JSON）。

手动路径较繁琐，**优先用 `forge verify-contract`**。

---

## 六、部署后自检（与「验证」不同）

「源码验证」是给人看代码；「链上是否是你的 Counter」可用 `cast` 读存储：

```bash
cast call YOUR_COUNTER_ADDRESS "number()(uint256)" --rpc-url sepolia
```

能正常返回 `uint256` 说明该地址上存在兼容 ABI 的合约（通常即你部署的 `Counter`）。

---

## 七、常见问题

| 现象 | 处理方向 |
|------|----------|
| **Bytecode does not match** | 核对 solc 版本、optimizer runs、是否改过源码、是否误选了其它合约名。 |
| **Already Verified** | 该地址已验证过，直接看浏览器 Contract 页。 |
| **Invalid API Key** | 检查 `SEPOLIA_ETHERSCAN_API_KEY` 与 `foundry.toml` 占位符是否一致。 |
| **网络不是 Sepolia** | `--chain sepolia` 与部署链必须一致；其它测试网需换浏览器与 chain 参数。 |

---

## 八、与「验证别人的合约」的关系

本文是 **你本人** 用本仓库脚本部署的 `Counter` 的验证步骤。若要在浏览器上「验证他人未公开的合约」，需要对方相同的源码与编译元数据；否则只能阅读对方已验证的源码，无法凭空替其完成 Etherscan 验证。

---

*文档路径：`md/draf/DeployCounter-Sepolia合约验证攻略.md`，与 `script/DeployCounter.s.sol` 配套。*
