# 第 6 章：Sepolia 部署——推荐操作顺序与 `Unlocked wallets` 排查

## 6.1 报错形态（两行分别什么意思）

```text
Error: No associated wallet for addresses: [0x1c40....].
Unlocked wallets: []
```

| 片段 | 含义 |
|------|------|
| **`addresses: [...]`** | 脚本中的 **`deployer`**（如 **`DEPLOYER_ADDRESS`** 或 JSON 里的 **`address`**） |
| **`Unlocked wallets: []`** | 没有任何已解锁钱包——多为 **`KEYSTORE_PATH` 未传入进程** 或 **`--keystore` 无效** |

优先保证：**`echo "$KEYSTORE_PATH"` 非空**，且命令使用 **`--keystore "$KEYSTORE_PATH"`**（带引号）。

---

## 6.2 原因速查

| 原因 | 如何发现 |
|------|----------|
| 未 `export KEYSTORE_PATH` | `echo` 为空 |
| 仅在 IDE 配了变量，终端未 export | 终端里 `echo` 为空 |
| `.env` 中有 `$(cast ...)` | 可能导致后续变量加载失败（见 **第 4 章**） |
| 路径含空格未加引号 | 参数被拆开 |
| 无 TTY / CI | 无法交互输入 keystore 密码 |
| **`DEPLOYER_ADDRESS`** 与 **`cast wallet address --keystore`** 不一致 | 地址与 signer 对不上 |

---

## 6.3 推荐顺序（同一终端窗口）

### 步骤 1：进入项目根并加载变量

```bash
cd /path/to/my-foundry-project
export SEPOLIA_RPC_URL="..."
export KEYSTORE_PATH="/..."
export SEPOLIA_ETHERSCAN_API_KEY="..."
```

或（确认 `.env` 无破坏解析的 `$(...)` 行后）：`set -a && source .env && set +a`

**立刻检查：** `echo "$KEYSTORE_PATH"`

### 步骤 2：确认 keystore 与地址

```bash
test -f "$KEYSTORE_PATH" && echo OK || echo MISSING
cast wallet address --keystore "$KEYSTORE_PATH"
```

若脚本依赖 **`DEPLOYER_ADDRESS`** 且无 JSON **`address`**：**.env 中地址必须与上面输出一致**。

### 步骤 3（可选）：确认 Sepolia

```bash
cast chain-id --rpc-url "$SEPOLIA_RPC_URL"
```

链 ID 一般为 **`11155111`**。

### 步骤 4：先模拟（不加 `--broadcast`）

```bash
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --keystore "$KEYSTORE_PATH" \
  -vvvv
```

此处仍出现 **`Unlocked wallets: []`** → 回到步骤 1～2。

### 步骤 5：广播 + 验证

```bash
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --keystore "$KEYSTORE_PATH" \
  --broadcast \
  --verify \
  --etherscan-api-key "$SEPOLIA_ETHERSCAN_API_KEY" \
  --slow \
  -vvvv
```

合约入口建议写全：**`script/File.sol:ContractName`**。

---

## 6.4 备忘

1. **`echo "$KEYSTORE_PATH"` 非空** + **`--keystore "$KEYSTORE_PATH"`**。  
2. **`cast wallet address`** 与 **`deployer` / `DEPLOYER_ADDRESS`** 一致。
