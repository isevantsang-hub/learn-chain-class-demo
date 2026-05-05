# 第 2 章：Keystore 与私钥——部署方式选择与 MetaMask

## 2.1 结论：不是「只能用明文私钥」

用 Foundry 部署时，可以 **全程使用 Keystore（加密 JSON）** + 终端交互密码完成签名，**不必**把 **`PRIVATE_KEY`** 写进 `.env`。

| 方式 | 说明 |
|------|------|
| **Keystore + CLI** | `forge script ... --broadcast --keystore /path/to.json`，按提示输入密码 |
| **明文私钥** | `export PRIVATE_KEY=0x...` 或 `--private-key`（省事但泄露风险大） |

链上签名底层仍是私钥运算；Keystore 只是在本地解密后再签名，**不必**再把同一串 hex 放进环境变量。

---

## 2.2 脚本内职责 vs 命令行职责

- **Solidity 脚本**：通过 **`KEYSTORE_PATH`** + **`vm.readFile`** 等确定 **`deployer` 地址**、余额检查、`startBroadcast(deployer)`。  
- **Forge 进程**：用 **`--keystore`** 解锁**同一文件**完成**真实签名**。

两者路径必须一致，否则会出现「脚本以为是地址 A，签名却是账户 B」。

---

## 2.3 MetaMask 与 Keystore 格式

- MetaMask 通常导出的是 **私钥** 或 **助记词**，**不会**直接给出 Geth/Cast 那种 **JSON Keystore 文件**。  
- **做法**：在测试环境用 MetaMask 导出私钥 → **`cast wallet import <名称> --interactive`** 生成加密 JSON（路径自定，**勿提交 Git**）。

---

## 2.4 基础命令模板

```bash
export KEYSTORE_PATH="/绝对或相对路径/到你的-keystore.json"
export LOCAL_RPC_URL="http://127.0.0.1:8545"   # 或测试网 RPC

forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$LOCAL_RPC_URL" \
  --broadcast \
  --keystore "$KEYSTORE_PATH"
```

- 模拟则去掉 **`--broadcast`**。  
- 若脚本使用 **`vm.readFile`**，需在 **`foundry.toml`** 配置 **`fs_permissions`**（见 **第 3 章**）。

---

## 2.5 安全提示

测试专用账户与密钥；主网大额资产勿照搬课堂写法；Keystore 与密码勿入库。
