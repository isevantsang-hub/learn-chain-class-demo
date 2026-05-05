# 第 8 章：`Counter` 链上交互——`cast` 命令（本地与 Sepolia）

合约 **`Counter`** 含：**`number()`**（public 自动 getter）、**`increment()`**、**`setNumber(uint256)`**。  
下面 **`COUNTER`** 请替换为你部署日志里的 **Contract Address**。

---

## 8.1 环境变量

**本地（示例）：**

```bash
export RPC_URL="$LOCAL_RPC_URL"          # 如 http://127.0.0.1:8545
export COUNTER="0x你的合约地址"
export KEYSTORE_PATH="/你的/keystore"
```

**Sepolia：**

```bash
export SEPOLIA_RPC_URL="你的 HTTPS RPC"
export COUNTER="0x你的合约地址"
export KEYSTORE_PATH="/你的/keystore"
```

---

## 8.2 只读：查询 `number`

```bash
cast call "$COUNTER" "number()(uint256)" --rpc-url "$RPC_URL"
# Sepolia 则将 RPC_URL 换成 SEPOLIA_RPC_URL：
cast call "$COUNTER" "number()(uint256)" --rpc-url "$SEPOLIA_RPC_URL"
```

---

## 8.3 写链：`increment()`

```bash
cast send "$COUNTER" "increment()" \
  --rpc-url "$RPC_URL" \
  --keystore "$KEYSTORE_PATH"
```

（Sepolia 同理替换 **`--rpc-url`**。）

---

## 8.4 写链：`setNumber`（例如设为 `99`）

**正确格式：** 合约地址、函数签名、参数之间**分开**，函数签名加引号：

```bash
cast send "$COUNTER" "setNumber(uint256)" 99 \
  --rpc-url "$RPC_URL" \
  --keystore "$KEYSTORE_PATH"
```

**错误示例：** `"0x...)setNumber(uint256)"` —— 引号粘连会导致解析失败。

---

## 8.5 一行速查

| 目的 | 命令要点 |
|------|----------|
| 读 `number` | `cast call ... "number()(uint256)"` |
| +1 | `cast send ... "increment()"` + `--keystore` |
| 设为某值 | `cast send ... "setNumber(uint256)" <值>` + `--keystore` |

---

## 8.6 可选：浏览器

Sepolia：`https://sepolia.etherscan.io/address/<合约地址>` —— **Read / Write Contract** 需连接钱包。

---

## 8.7 常见问题

- **`insufficient funds`**：测试网需领水；本地 Anvil 一般充足。  
- **Keystore / 私钥错误**：写操作需与有权限的账户一致（多为部署者）。  
- **`COUNTER` 错误**：必须与部署输出地址**完全一致**。
