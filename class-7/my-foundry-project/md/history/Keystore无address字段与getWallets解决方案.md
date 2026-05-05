# Keystore 无 `.address` 时如何固定「部署者 = 我的 keystore」

## 更新说明（与当前脚本一致）

`DeployCounter.s.sol` **只支持 Keystore 部署**：已删除 **`PRIVATE_KEY`、Anvil 默认账户、`vm.getWallets()`** 等分支。  
此前若日志里的 **Deployer 不是你的 keystore**，常见原因是脚本走了 **`getWallets()` 或其它回落逻辑**，与 Forge 内部默认 sender / 多 signer 顺序有关，**不可靠**。

当前规则：

1. **必须**设置 **`KEYSTORE_PATH`**（与 **`forge script --keystore`** 指向**同一文件**）。  
2. 若 keystore JSON **含有**顶层 **`"address"`** → 脚本只认该字段作为 Deployer。  
3. 若 JSON **没有** `"address"`（常见）→ 必须在环境里提供 **`DEPLOYER_ADDRESS`**，且必须是对**同一 keystore 文件**执行下列命令得到的地址（保证与账户一致）：

```bash
export KEYSTORE_PATH="/path/to/your-keystore-file"
export DEPLOYER_ADDRESS="$(cast wallet address --keystore "$KEYSTORE_PATH")"
```

然后再运行：

```bash
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$LOCAL_RPC_URL" \
  --keystore "$KEYSTORE_PATH"
```

发链时追加 **`--broadcast`**。

这样 **Deployer 只可能来自「JSON 里的 address」或「cast 对同一文件的解析」**，不会再混入其它账户。

---

## 为何不能只在 Solidity 里「猜」地址？

未解密 keystore 前，合约脚本**无法**从密文推出地址；**`vm.getWallets()`** 在模拟阶段也可能**不是**你期望的那一个 signer。  
因此：要么 JSON 自带 `address`，要么用 **`cast wallet address --keystore`** 在链下写好 **`DEPLOYER_ADDRESS`**。

---

## 仍会报错时的自检

| 现象 | 处理 |
|------|------|
| `readFile` / fs | `foundry.toml` 配置 **`fs_permissions`**（见《部署脚本-keystore-方案》） |
| `DEPLOYER_ADDRESS` 仍无效 | 确认使用 **`export`**，或在项目根 `.env` 中书写（Foundry 会加载）；勿与 **`KEYSTORE_PATH`** 指向不同文件 |
| `Insufficient balance` | 该地址在目标链上需要足够 ETH（Sepolia 领水等） |

---

## `.env` 里写了 `DEPLOYER_ADDRESS` 仍报错？

常见原因：**同一 `.env` 里某一行写了 shell 插值**，例如：

```bash
KEYSTORE_PATH_ADDRESS=$(cast wallet address --keystore ...)
```

Foundry 读取 `.env` 的规则**不等于**你在 zsh 里 `source`；含 **`$(...)`** 的行容易导致解析异常，**后面的变量（含 `DEPLOYER_ADDRESS`）整块加载失败**，于是脚本里像是从未设置过 `DEPLOYER_ADDRESS`。

**做法：**删掉或注释掉这类 `$(cast ...)` 行；部署地址要么写在 **`DEPLOYER_ADDRESS="0x..."`**（纯字面量），要么在终端 **`export DEPLOYER_ADDRESS=$(cast wallet address --keystore "$KEYSTORE_PATH")`** 再运行 `forge script`。

脚本侧已改为用 **`vm.envOr("DEPLOYER_ADDRESS", string(""))` + `parseAddress`**，避免 `envExists` 与部分加载顺序不一致的问题。

---

## 相关文档

- **`KEYSTORE_PATH-envOr重载陷阱与-cli-keystore说明.md`**  
- **`部署脚本-keystore-方案.md`**
