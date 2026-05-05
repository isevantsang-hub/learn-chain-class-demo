# Sepolia 部署报错：`Unlocked wallets: []` 排查与操作顺序

**适用场景：** 使用 `forge script ... --broadcast --keystore ...` 在 Sepolia 上发交易时，出现 **没有已解锁钱包** 或 **地址与签名器对不上** 的提示。

---

## 一、报错长什么样，两行分别是什么意思

```text
Error: No associated wallet for addresses: [0x1c40c125e5d5eba2d67f88bfb7e9dce3787f46fd].
Unlocked wallets: []
```

| 片段 | 含义 |
|------|------|
| **`addresses: [0x1c40...]`** | 脚本里 **`deployer`**（例如 `.env` 的 **`DEPLOYER_ADDRESS`**，或 keystore JSON 里的 **`address`**）被认为是这个地址。 |
| **`Unlocked wallets: []`** | Foundry **没有**成功解锁任何钱包用来签名；最常见是 **`$KEYSTORE_PATH` 为空** 或 **`--keystore` 没传进去**。 |

**结论：** 先把 **`KEYSTORE_PATH` 在当前终端非空 + `--keystore "$KEYSTORE_PATH"`** 跑通，再谈 `--verify`、RPC 等。

---

## 二、原因速查（不必改代码也能自查）

| 原因 | 你怎么发现 |
|------|------------|
| **`KEYSTORE_PATH` 未 export** | 同一终端执行 **`echo "$KEYSTORE_PATH"`** 输出为空。 |
| **IDE 里配了变量，终端里没有** | IDE 一键运行有 env，你在 **Terminal 手敲命令** 时没有 `export`。 |
| **`.env` 里有 `$(cast ...)` 等 shell 插值** | 可能导致后续变量加载异常（详见 **`Keystore无address字段与getWallets解决方案.md`**）。 |
| **路径含空格却未加引号** | **`--keystore $KEYSTORE_PATH`** 被拆参。应使用 **`--keystore "$KEYSTORE_PATH"`**。 |
| **无终端密码交互（CI / 某些 IDE）** | `--keystore` 需要输入密码；非交互环境可能无法解锁。 |
| **`DEPLOYER_ADDRESS` ≠ keystore 对应地址** | **`cast wallet address --keystore`** 与脚本使用的 **`deployer`** 不一致。 |

---

## 三、推荐操作顺序（同一终端窗口内从头到尾）

**原则：** 先 **`cd` + `export` → 确认文件与地址 → 可选链 ID → 先模拟再广播。**  
以下均在 **项目根目录**（含 `foundry.toml`）执行。

### 步骤 1：进入目录并加载环境变量

```bash
cd /path/to/my-foundry-project
```

**推荐：** 手动把 `.env` 里的值拷出来 export（最不容易踩坑）：

```bash
export SEPOLIA_RPC_URL="你的 RPC URL"
export KEYSTORE_PATH="/你的/keystore 文件路径"
export SEPOLIA_ETHERSCAN_API_KEY="你的 Key"
```

**可选：** 若 `.env` 里没有 `$(...)` 这类会破坏加载的行，可用：

```bash
set -a && source .env && set +a
```

**立刻检查（为空就别往下）：**

```bash
echo "$KEYSTORE_PATH"
echo "$SEPOLIA_RPC_URL"
```

---

### 步骤 2：确认 keystore 文件存在，并能算出地址

```bash
test -f "$KEYSTORE_PATH" && echo "keystore OK" || echo "keystore 缺失"
cast wallet address --keystore "$KEYSTORE_PATH"
```

输入密码后得到地址。**若脚本依赖 `DEPLOYER_ADDRESS`**（且 JSON 无顶层 `"address"`），请保证 **`.env` 里的 `DEPLOYER_ADDRESS` 与该输出一致**，否则脚本里的 **`deployer`** 仍会指向错误地址。

---

### 步骤 3（可选）：确认连的是 Sepolia

```bash
cast chain-id --rpc-url "$SEPOLIA_RPC_URL"
```

Sepolia 链 ID 一般为 **`11155111`**。

---

### 步骤 4：只模拟，不发链（先不要 `--broadcast`）

```bash
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --keystore "$KEYSTORE_PATH" \
  -vvvv
```

- 会提示输入 **keystore 密码**。  
- **若这里仍出现 `Unlocked wallets: []`**：回到 **步骤 1～2**，重点查 **`echo "$KEYSTORE_PATH"`** 与 **`cast wallet address`**。

---

### 步骤 5：再广播 + 链上验证（模拟正常后再做）

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

到这一步若报错，再区分是 **gas / RPC / 合约验证**，而不是「钱包一条都没解锁」。

---

## 四、参考命令模板（复制后替换占位）

```bash
# 合约入口建议写全 script/File.sol:ContractName
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --keystore "$KEYSTORE_PATH" \
  --broadcast \
  --verify \
  --etherscan-api-key "$SEPOLIA_ETHERSCAN_API_KEY" \
  --slow \
  -vvvv
```

**切记：** `--rpc-url`、`--keystore`、`--etherscan-api-key` 一侧都用 **`"$变量"`** 带引号。

---

## 五、两条最容易踩的点（备忘）

1. **`echo "$KEYSTORE_PATH"` 非空**，且 forge 命令里是 **`--keystore "$KEYSTORE_PATH"`**。  
2. **`cast wallet address --keystore "$KEYSTORE_PATH"`** 的结果与脚本 **`deployer`**（如 **`DEPLOYER_ADDRESS`**）**一致**。

---

## 六、相关文档（本仓库 `md`）

| 文档 | 内容 |
|------|------|
| **`forge-script-broadcast与钱包解锁教程.md`** | `--broadcast` 为何要解锁钱包 |
| **`Keystore无address字段与getWallets解决方案.md`** | `DEPLOYER_ADDRESS`、`.env`、勿写 `$(...)` |
| **`KEYSTORE_PATH-envOr重载陷阱与-cli-keystore说明.md`** | `KEYSTORE_PATH` 与脚本 `readFile` |
