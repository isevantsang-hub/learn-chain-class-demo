# 第 5 章：`forge script`——模拟、`--broadcast` 与钱包解锁

## 5.1 模拟 vs 广播

| 对比项 | 不加 `--broadcast` | 加 `--broadcast` |
|--------|-------------------|------------------|
| **作用** | 本地模拟（dry-run），默认不写链 | 向 `--rpc-url` **发送真实交易** |
| **签名** | 通常不要求解锁钱包（视脚本是否读链状态） | **必须**提供 **`--keystore` / `--private-key`** 等 |

脚本中有 **`vm.startBroadcast(deployer)`** 时，广播阶段 Forge 必须能 **解锁与 `deployer` 一致** 的账户。

---

## 5.2 典型报错：`Unlocked wallets: []`

```text
Error: No associated wallet for addresses: [0x....].
Unlocked wallets: []
```

**含义：** 脚本认为发送方是 **`0x....`**，但 Foundry **没有解锁任何钱包**——最常见是 **`$KEYSTORE_PATH` 为空** 导致 **`--keystore`** 没传进去，或从未输入密码成功解锁。

**结论：** **`.env` 里只有地址字符串不等于解锁**；**`--broadcast` 必须带签名参数**。

---

## 5.3 正确示例（Keystore）

```bash
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$LOCAL_RPC_URL" \
  --broadcast \
  --keystore "$KEYSTORE_PATH" \
  -vvvv
```

- **`KEYSTORE_PATH`** 与 **`--keystore`** 指向 **同一文件**。  
- JSON **无 `"address"`** 时须配置 **`DEPLOYER_ADDRESS`**（与 **`cast wallet address --keystore`** 一致），见 **第 4 章**。

---

## 5.4 本地 Anvil 注意

若使用 Anvil 自带测试账户 + **`--private-key`**，需与脚本里的 **`deployer`** 一致；与 MetaMask Keystore 流程**不要混用**。

---

## 5.5 广播失败自检

| 项 | 说明 |
|----|------|
| 是否加了 `--broadcast` | 加了就必须能签名 |
| 是否提供 `--keystore` / `--private-key` | 缺则 `Unlocked wallets: []` |
| `deployer` 与解锁钱包 | 地址必须一致 |
| RPC | `anvil` / 节点需已启动 |

---

## 5.6 历史说明：「未配置 deployer」类 revert

若脚本要求 **`KEYSTORE_PATH` / 其它变量**，而终端里**完全未设置**，可能 early **`revert`**。解决思路仍是：**在同一终端 `export` 所需变量**，并保证 **Keystore + 广播参数** 齐全（细节以当前仓库脚本为准）。
