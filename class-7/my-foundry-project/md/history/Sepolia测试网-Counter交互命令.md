# Sepolia 测试网：`Counter` 合约交互命令

下面命令用于在 **Sepolia** 上与已部署的 **`Counter`** 交互（读 `number`、调用 `increment`、`setNumber`）。  
请将 **`COUNTER`** 换成你自己的合约地址；文中示例为你此前部署成功的地址之一。

---

## 一、环境变量（在终端先执行）

```bash
export SEPOLIA_RPC_URL="你的 Sepolia RPC，可与 .env 中一致"
export COUNTER="0xCe41FF0A4f093A70b098C6B9e28c3E6Eb9806f58"
export KEYSTORE_PATH="/你的/keystore/文件路径"
```

说明：

- **`SEPOLIA_RPC_URL`**：Alchemy / Infura 等提供的 Sepolia HTTPS 端点。  
- **`COUNTER`**：部署日志里的 **Contract Address**。  
- **`KEYSTORE_PATH`**：与部署时相同的 keystore；**写操作**需要解锁签名。

---

## 二、只读：查询当前 `number`

```bash
cast call "$COUNTER" "number()(uint256)" --rpc-url "$SEPOLIA_RPC_URL"
```

返回为十进制整数（例如首次部署后多为 `0`）。

---

## 三、写链：`increment()`（`number` 加 1）

```bash
cast send "$COUNTER" "increment()" \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --keystore "$KEYSTORE_PATH"
```

按提示输入 **keystore 密码**。成功后可用第二节再读一次 `number`，应增加 `1`。

---

## 四、写链：`setNumber(uint256)`（例如设为 `99`）

```bash
cast send "$COUNTER" "setNumber(uint256)" 99 \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --keystore "$KEYSTORE_PATH"
```

注意：**函数签名与参数之间要有空格**，且函数名加引号：

```text
cast send "<合约地址>" "setNumber(uint256)" <数值> ...
```

---

## 五、一行命令速查

| 目的 | 命令 |
|------|------|
| 读 `number` | `cast call "$COUNTER" "number()(uint256)" --rpc-url "$SEPOLIA_RPC_URL"` |
| `number++` | `cast send "$COUNTER" "increment()" --rpc-url "$SEPOLIA_RPC_URL" --keystore "$KEYSTORE_PATH"` |
| 设为某值 | `cast send "$COUNTER" "setNumber(uint256)" <值> --rpc-url "$SEPOLIA_RPC_URL" --keystore "$KEYSTORE_PATH"` |

---

## 六、在浏览器核对（可选）

打开（地址用小写亦可打开）：

```text
https://sepolia.etherscan.io/address/0xCe41FF0A4f093A70b098C6B9e28c3E6Eb9806f58
```

在 **Contract** 页可用「Read / Write Contract」与合约交互（需连接钱包）。

---

## 七、常见问题

1. **`insufficient funds`**：该 keystore 对应账户在 Sepolia 上 **ETH 不足**，需领测试 ETH。  
2. ** gas / nonce**：同一账户频繁发交易一般问题不大；若报错可查 `cast nonce <地址> --rpc-url "$SEPOLIA_RPC_URL"`。  
3. **`KEYSTORE_PATH` 为空**：先 `echo "$KEYSTORE_PATH"`，必要时 `export`（参见 **`Sepolia广播-Unlocked-wallets为空排查攻略.md`**）。

---

## 相关文档

- **`Counter已部署-交互测试命令.md`**：通用写法（含本地 RPC 示例）。  
- **`md/Sepolia广播-Unlocked-wallets为空排查攻略.md`**：`KEYSTORE_PATH`、终端变量。
