# 第 3 章：部署脚本原理——`readFile`、无效 Cheatcode 与编译错误

## 3.1 不存在 `vm.getAddressFromKeystore`

若在脚本里写 **`vm.getAddressFromKeystore(keystorePath)`**，编译可能报错：

```text
Error (9582): Member "getAddressFromKeystore" not found ... in contract Vm.
```

**原因：** **forge-std** 的 **`Vm.sol` 接口里没有声明该函数**（例如本项目使用的 forge-std 版本）。Solidity 只能调用接口里声明的 cheatcode，**运行时是否存在**不能弥补编译期缺失。

**替代思路：** 按以太坊 **Keystore JSON** 标准，使用：

1. **`vm.readFile(KEYSTORE_PATH)`** 读入文件内容；  
2. **`stdJson`** 解析顶层 **`"address"`**（若有）；  
3. 用 **`vm.parseAddress`** 处理带或不带 **`0x`** 的 hex 字符串。

---

## 3.2 `foundry.toml` 与 `fs_permissions`

**`vm.readFile`** 受文件系统权限限制，必须在 **`foundry.toml`** 中声明可读路径，例如：

```toml
fs_permissions = [{ access = "read", path = "./" }]
```

若 **`KEYSTORE_PATH`** 指向**仓库外**目录，需**追加**该目录的读权限（TOML 中 **`$HOME` 一般不展开**，请写绝对路径）。

---

## 3.3 广播时 CLI 与脚本一致

```bash
forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$RPC_URL" \
  --broadcast \
  --keystore "$KEYSTORE_PATH"
```

**`KEYSTORE_PATH`（给脚本 `readFile`）** 与 **`--keystore`（给 Forge 签名）** 应指向 **同一文件**。

---

## 3.4 Soldeer / forge-std

当前方案依赖 **`StdJson`**、**`vm.parseAddress`** 等，一般 **无需** 为虚构 API 盲目升级 forge-std；升级时在 **`foundry.toml` / `soldeer.lock`** 中按需 bump 即可。
