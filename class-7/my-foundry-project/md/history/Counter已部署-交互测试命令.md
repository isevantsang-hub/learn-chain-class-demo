# Counter 合约部署后的交互与测试命令

以下假定你已部署 **`Counter`**，且已知：

- **合约地址**（你本次部署示例）：`0x8c699F3c2F76F8038348AA6b7e775F549FFb3152`  
- **RPC**：本地一般为 `http://127.0.0.1:8545`（变量 **`LOCAL_RPC_URL`**）；测试网则用 `.env` 里的 **`SEPOLIA_RPC_URL`** 等。

在终端里可先导出变量，后面命令可直接复制：

```bash
export RPC_URL="$LOCAL_RPC_URL"   # 或 export RPC_URL="$SEPOLIA_RPC_URL"
export COUNTER="0x8c699F3c2F76F8038348AA6b7e775F549FFb3152"
```

---

## 一、只读：查询当前 `number`

`number` 为 `public`，自动生成 getter **`number()`**。

```bash
cast call "$COUNTER" "number()(uint256)" --rpc-url "$RPC_URL"
```

预期返回十进制整数（例如 `0`）。

---

## 二、写链：调用 `increment()`

会改状态，需要 **签名账户**（与部署时一致即可）。

**方式 A：Keystore**

```bash
cast send "$COUNTER" "increment()" \
  --rpc-url "$RPC_URL" \
  --keystore "$KEYSTORE_PATH"
```

**方式 B：私钥（仅示例，注意安全）**

```bash
cast send "$COUNTER" "increment()" \
  --rpc-url "$RPC_URL" \
  --private-key "$PRIVATE_KEY"
```

成功后再读一次 `number()`，应比原来大 `1`。

---

## 三、写链：调用 `setNumber(uint256)`

例如设为 `42`：

```bash
cast send "$COUNTER" "setNumber(uint256)" 42 \
  --rpc-url "$RPC_URL" \
  --keystore "$KEYSTORE_PATH"
```

再查询：

```bash
cast call "$COUNTER" "number()(uint256)" --rpc-url "$RPC_URL"
```

应输出 `42`。

---

## 四、用交易哈希核对链上结果（可选）

你提到的部署交易哈希：

`0xbf35aa5478da41a55ce7589e5d218e1f5d55ab8302c5218ddb6a90d8c9c0cf98`

```bash
cast tx 0xbf35aa5478da41a55ce7589e5d218e1f5d55ab8302c5218ddb6a90d8c9c0cf98 --rpc-url "$RPC_URL"
```

可查看 `status`、`from`、`contractAddress`（创建合约时）等字段（具体字段名以 `cast tx` 输出为准）。

---

## 五、用 Foundry 测试本地逻辑（与「链上已部署实例」无关）

这是跑仓库里的 **Solidity 测试**，验证的是 `test/Counter.t.sol`，**不会自动连到你上面的部署地址**：

```bash
forge test --match-contract CounterTest -vv
```

链上已部署合约的验证请以 **`cast call` / `cast send`** 为主。

---

## 六、简短对照表

| 目的 | 命令思路 |
|------|----------|
| 读 `number` | `cast call ... "number()(uint256)"` |
| `number++` | `cast send ... "increment()"` + 钱包参数 |
| 设任意值 | `cast send ... "setNumber(uint256)" <值>` + 钱包参数 |
| 换一条链 / 另一个地址 | 改 **`RPC_URL`**、**`COUNTER`** 即可 |

---

## 七、常见问题

1. **`nonce too low` / `insufficient funds`**：当前 RPC 上该账户 ETH 不足或未对齐 nonce，本地 Anvil 一般不易出现；测试网需领水。  
2. **`Keystore` / 私钥报错**：`cast send` 与部署时一样，必须能解锁 **有权限改 Counter 状态** 的同一账户（一般为部署者）。  
3. **地址写错**：`COUNTER` 必须与部署日志里的 **`Contract Address`** 完全一致。

将上述命令中的哈希、地址换成你自己的多次部署结果即可重复使用。
