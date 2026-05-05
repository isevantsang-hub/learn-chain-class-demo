# Forge Script：模拟运行、`--broadcast` 与钱包解锁教程

## 两条命令有什么区别？

| 命令特征 | 作用 |
|----------|------|
| **不加 `--broadcast`** | 只在本地 **模拟**（dry-run），不写链；一般不会要求你解锁真实钱包（取决于脚本是否读链状态）。 |
| **加 `--broadcast`** | 向 `--rpc-url` 指向的节点 **提交真实交易**，必须用 **私钥 / Keystore / 硬件钱包** 等在本地 **解锁账户并签名**。 |

脚本里若写了 **`vm.startBroadcast(deployer)`**，广播阶段会使用 **`deployer` 这个地址** 作为发送方；Forge 必须在进程里有一个 **已解锁、且与该地址一致** 的钱包，否则就会报错。

---

## 常见报错：`No associated wallet ... Unlocked wallets: []`

含义：

- 脚本认为发送地址是 **`0x....`**（例如来自 `DEPLOYER_ADDRESS` 或 keystore JSON 里的 `address`）；  
- 但你在命令行 **没有提供任何签名材料**，因此 **`Unlocked wallets` 为空**；  
- **`--broadcast`** 无法签名，于是失败。

**结论：**仅配置 `.env` 里的地址字符串 **不等于** 解锁钱包；**广播时必须额外传入 Keystore 或私钥等参数**。

---

## 正确示例（与本仓库 Keystore 脚本配套）

在项目根目录执行（路径按你本机修改）：

```bash
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$LOCAL_RPC_URL" \
  --broadcast \
  --keystore "$KEYSTORE_PATH" \
  -vvvv
```

要点：

1. **`KEYSTORE_PATH`** 与 **`--keystore`** 指向 **同一个 keystore 文件**。  
2. 终端会提示输入 **Keystore 密码**；解锁成功后，Forge 才能把交易签成链上可发送的格式。  
3. 若你的 JSON **没有** 顶层 `"address"`，仍需在 `.env` 或环境里配置 **`DEPLOYER_ADDRESS`**（与 `cast wallet address --keystore "$KEYSTORE_PATH"` 一致），详见 **`Keystore无address字段与getWallets解决方案.md`**。

---

## 本地 Anvil 的常见用法（可选）

若只想在本地链上 **快速发交易**，且 deployer 用的是 **Anvil 自带测试账户**，则需：

- 脚本里解析出的 **`deployer`** 与 Anvil 默认账户之一 **一致**；  
- 命令行传入对应的 **`--private-key`**（或使用文档里提供的 Anvil 测试私钥流程）。

这与「MetaMask 导出的 Keystore」不是同一路径，不要混用。

---

## 自检清单（广播失败时）

| 检查项 | 说明 |
|--------|------|
| 是否加了 `--broadcast` | 一加就必须能签名。 |
| 是否提供 `--keystore` / `--private-key` 等 | 缺少则 `Unlocked wallets: []`。 |
| deployer 地址是否与解锁钱包一致 | Keystore 解锁出来的地址必须等于脚本里的 `deployer`。 |
| RPC 是否可达 | `LOCAL_RPC_URL` 指向的节点（如 Anvil）需已启动。 |
| 账户 ETH 是否足够 | 脚本里若有 `require(deployer.balance > ...)`，本地链需提前 `eth` / `deal`（视脚本而定）。 |

---

## 与其它文档的关系

- **`部署脚本-keystore-方案.md`**：`readFile`、`fs_permissions`。  
- **`Keystore无address字段与getWallets解决方案.md`**：无 `.address` 时用 `DEPLOYER_ADDRESS`、`.env` 里勿写 `$(cast ...)`。  
- **`KEYSTORE_PATH-envOr重载陷阱与-cli-keystore说明.md`**：`envOr` 不要误用 `bytes` 重载。  
- **`部署攻略-Keystore与私钥如何选择.md`**：不必强制明文私钥，可用 Keystore。

掌握本节 **`--broadcast` + 解锁钱包** 后，本地部署报错「没有关联钱包」即可按表逐项排除。
