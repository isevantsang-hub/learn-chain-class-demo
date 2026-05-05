# 部署攻略：必须用私钥吗？还能不能用 Keystore？

## 直接结论

**不是「只能用私钥部署」。**  
用 Foundry 部署时，你完全可以 **全程用 Keystore（加密 JSON 钱包文件）** 完成签名与广播，而不必把 **明文私钥** 写成环境变量 `PRIVATE_KEY`。

区别在于：**链上交易总得有一次「解密 Keystore → 得到私钥 → 签名」**，这一步可以由 Foundry 在本地交互输入密码完成，也可以退而求其次用环境变量里的明文私钥——后者省事但不利于保管。

---

## 三种常见方式对照

| 方式 | 是否需要 `PRIVATE_KEY` 环境变量 | 是否需要 Keystore 文件 | 典型用法 |
|------|-----------------------------------|-------------------------|----------|
| **A. Keystore + Forge CLI** | **否**（不推荐把私钥放进 `.env`） | **是** | `forge script ... --broadcast --keystore /path/to.json`，按提示输入密码 |
| **B. 明文私钥（环境变量 / CLI）** | **是** | 否 | `export PRIVATE_KEY=0x...` 或 `--private-key 0x...` |
| **C. 硬件钱包 / 浏览器钱包** | **否** | 视钱包而定 | 使用 Foundry 对应版本支持的方式（以官方文档为准） |

因此：**「不用 Keystore、只能用私钥」不成立**；你完全可以选择 **只走 Keystore**。

---

## 为什么有人觉得「只能私钥」？

1. **教程常写 `PRIVATE_KEY`**：示例最短，容易复制粘贴，但安全上最糙。  
2. **概念混淆**：  
   - **Keystore** = 磁盘上的 **加密** 私钥包（JSON）。  
   - 部署时工具必须 **解锁** 它才能签名；解锁后 **在内存里** 仍是私钥在算签名，但 **不必** 你把同一串 hex 再放进 `.env`。  
3. **脚本里的分工**：  
   - Solidity 脚本（例如读取 `KEYSTORE_PATH` 解析 `address`）只负责 **知道「谁在部署」**、余额检查、`startBroadcast(deployer)` 与链 ID 等逻辑。  
   - **真正拿私钥签字** 的那一步，通常交给 **`forge script` 命令行** 的 `--keystore` / `--account` 等参数，而不是脚本里再声明一遍私钥。

---

## 推荐流程（坚持 Keystore、不写明文私钥）

### 1. 准备好 Keystore 文件

使用 **`cast wallet import`** 从 MetaMask 导出的私钥生成加密 JSON（或沿用已有 Geth/Cast 格式文件）。文件路径仅你自己掌握，**不要提交 Git**。

### 2. 环境变量（脚本侧）

- 设置 **`KEYSTORE_PATH`** = 上述 JSON 的绝对或相对路径（供脚本 `readFile` 解析 `address`）。  
- **不必** 设置 `PRIVATE_KEY`。  

若脚本使用 `vm.readFile`，需在 **`foundry.toml`** 里配置 **`fs_permissions`**，允许读取该路径所在目录（详见《部署脚本-keystore-方案.md》）。

### 3. 命令行（签名侧）

广播时必须让 Forge **用同一个 Keystore 解锁签名**，例如：

```bash
export KEYSTORE_PATH="/你的路径/account.json"

forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$YOUR_RPC_URL" \
  --broadcast \
  --keystore "$KEYSTORE_PATH"
```

并按提示输入 Keystore 密码（或通过当前 Foundry 版本支持的密码传递方式，以 **`forge script --help`** 为准）。

要点：**`KEYSTORE_PATH`（给脚本读地址）与 `--keystore`（给 CLI 签名）应指向同一文件**，否则容易出现「脚本以为是地址 A，签名却是账户 B」的不一致。

---

## 什么时候才会用到「明文私钥」？

- 你愿意接受风险，图省事：`PRIVATE_KEY`、CLI `--private-key`。  
- 或某些 CI 场景（仍强烈建议使用密钥管理服务替代明文 `.env`）。

这与「能不能用 Keystore」无关，只是 **另一条可选路径**。

---

## 一句话总结

| 问题 | 答案 |
|------|------|
| 现在能不能用 Keystore 部署？ | **能**，通过 **`forge script ... --keystore`**（再配合脚本里的 `KEYSTORE_PATH` / `fs_permissions`）。 |
| 是否一定要用私钥部署？ | **链上签名本质是私钥运算**，但 **不必把私钥写成环境变量**；用 **Keystore + 密码** 即可完成部署。 |

如需与本仓库脚本细节（`readFile`、`StdJson`、`fs_permissions`）对照阅读，可继续看 **`部署脚本-keystore-方案.md`** 与 **`forge-script-运行失败排查与解决.md`**。
