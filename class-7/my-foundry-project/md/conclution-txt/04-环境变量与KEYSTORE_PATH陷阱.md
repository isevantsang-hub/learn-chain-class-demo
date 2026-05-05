# 第 4 章：环境变量陷阱——`KEYSTORE_PATH`、`DEPLOYER_ADDRESS` 与 `.env`

## 4.1 勿用 `envOr(..., bytes(""))` 读路径

若写成：

```solidity
vm.envOr("KEYSTORE_PATH", bytes(""))
```

编译器会选用 **`envOr` 的 `bytes` 重载**，把环境变量按 **bytes/hex 语义**解析，**不适合**普通路径字符串，表现为 **`if` 永远进不去**。

**应使用：**

- **`vm.envExists("KEYSTORE_PATH")` + `vm.envString("KEYSTORE_PATH")`**，或  
- **`vm.envOr("KEYSTORE_PATH", string(""))`**（默认值为 **string**）。

---

## 4.2 `--keystore` 不会自动写入 `KEYSTORE_PATH`

命令行 **`--keystore "$KEYSTORE_PATH"`** 只告诉 Forge **用哪个文件解锁签名**，**不会**自动创建名为 **`KEYSTORE_PATH`** 的环境变量。  
脚本里的 **`vm.env*`** 只能看到 **进程环境**（shell **`export`**、Foundry 加载的 **`.env`** 等）。

---

## 4.3 Keystore JSON 没有顶层 `"address"`

部分 **`cast wallet import`** 导出的 JSON **只有 `crypto` / `id` / `version`**，**没有** `"address"`。未解密前脚本**无法**从密文推出地址。

**做法：**

1. 在终端对**同一文件**执行：  
   **`cast wallet address --keystore "$KEYSTORE_PATH"`**  
2. 将得到的地址写入 **`.env`** 的 **`DEPLOYER_ADDRESS="0x..."`**（纯字面量），或：  
   **`export DEPLOYER_ADDRESS=$(cast wallet address --keystore "$KEYSTORE_PATH")`**  

脚本侧宜用 **`vm.envOr("DEPLOYER_ADDRESS", string(""))`** 再 **`parseAddress`**，避免仅依赖 **`envExists`** 与部分加载顺序不一致的问题。

---

## 4.4 `.env` 里不要写 `$(cast ...)`

例如：

```bash
KEYSTORE_PATH_ADDRESS=$(cast wallet address --keystore ...)
```

Foundry 加载 **`.env`** 的规则**不等于** shell **`source`**；含 **`$(...)`** 的行容易导致解析异常，**后续变量（含 `DEPLOYER_ADDRESS`）整块加载失败**，表现为脚本读不到地址。

**正确：** 注释掉这类行；地址用 **字面量 `DEPLOYER_ADDRESS`**，或在终端 **`export`**。

---

## 4.5 自检表

| 检查 | 说明 |
|------|------|
| `echo "$KEYSTORE_PATH"` | 执行 `forge` 前在同一终端确认非空 |
| `cast wallet address` 与 `DEPLOYER_ADDRESS` | 必须对应同一 keystore 文件 |
| `fs_permissions` | `readFile` 路径在仓库外时需追加可读目录 |
