# DeployCounter：Soldeer + Keystore 部署方案说明

## 背景：为什么会出现 `getAddressFromKeystore` 报错？

官方 **forge-std** 的 `Vm` 接口（`Vm.sol`）里 **没有** `vm.getAddressFromKeystore` 这一 cheatcode。教程或示例若写了该方法，在当前任意常用 forge-std 版本下都无法通过 Solidity 编译。

部署脚本若要在 Solidity 里「仍坚持走 keystore」，可行做法是：**按以太坊账号 keystore 标准 JSON 格式**，用 `vm.readFile` 读文件，再用 **StdJson** 解析顶层字段 `address`（与 Cast/Geth 导出格式一致）。这样既保留「环境变量里放 keystore 路径」的工作流，又与链下真实账号文件格式对齐。

## 本仓库采用的解决思路

1. **不再调用不存在的 cheatcode**，改为：
   - `KEYSTORE_PATH` → `vm.readFile` → 得到 JSON 字符串；
   - `json.readString(".address")` 读出 hex 字符串；
   - 若无 `0x` 前缀（常见），则 `vm.parseAddress(string.concat("0x", hex))`，若有前缀则直接 `vm.parseAddress`。
2. **`foundry.toml` 增加 `fs_permissions`**：`vm.readFile` 在 Foundry 里受文件系统权限控制，必须声明可读路径，否则运行脚本时会拒绝读文件。
3. **可选保留 `PRIVATE_KEY` 分支**：仅作备用；主路径仍为 keystore。

## 你需要配合的配置与命令

### 1. 环境变量

- **`KEYSTORE_PATH`**：指向账号 keystore JSON 文件的**绝对或相对路径**（Cast/Geth 那种含 `"address"`、`"crypto"` 的文件）。
- **`LOCAL_RPC_URL`**（或你在命令里写的 RPC）：本地节点 URL。

若 keystore 在项目目录之外，`foundry.toml` 的 `[profile.default]` 下需为 `fs_permissions` **追加**一条对该目录的读权限（默认已包含仓库内 `./`）。示例：`{ access = "read", path = "/Users/you/.foundry/keystores" }`（路径改成你的绝对路径；TOML 不支持 `$HOME` 展开）。

### 2. 链上广播时必须与 keystore 对应

脚本里使用 `vm.startBroadcast(deployer)`，其中 `deployer` 是从 keystore JSON 读出的地址。**实际签名**仍由 Foundry 在 CLI 侧解锁的钱包完成，因此广播时请使用与 **同一 keystore** 对应的参数，例如：

```bash
export KEYSTORE_PATH="/绝对或相对路径/到你的-keystore.json"

forge script script/DeployCounter.s.sol:DeployCounter \
  --rpc-url "$LOCAL_RPC_URL" \
  --broadcast \
  --keystore "$KEYSTORE_PATH" \
  --password "${KEYSTORE_PASSWORD:-}"
```

说明：

- **`--keystore`**（或你习惯的 **`--account`**，取决于你如何导入钱包）用于让 Foundry 用该文件签名；需与 `KEYSTORE_PATH` 指向**同一文件**，这样脚本里解析出的 `deployer` 地址才会与签名者一致。
- **`--password`**：若 keystore 加密，通过交互或环境变量提供密码（具体以你使用的 Foundry 版本文档为准）。
- 若只做本地模拟、不发链，可去掉 `--broadcast`。

### 3. Soldeer 依赖

当前方案 **仅需现有 forge-std（含 StdJson / Vm.parseAddress）**，无需为了一个不存在的 API 去猜测性地升级版本；若你日后为其它原因升级 `forge-std`，在 `foundry.toml` / `soldeer.lock` 中照常 bump 即可。

## 小结

| 项目       | 说明 |
|------------|------|
| 编译错误根因 | `Vm` 未声明 `getAddressFromKeystore`，属无效 API。 |
| 替代实现   | `readFile` + 解析 keystore JSON 的 `address`。 |
| 运行前置   | `fs_permissions` + 广播时 CLI 指定同一 `--keystore`。 |

按上述配置后，使用入口 **`DeployCounter.s.sol:DeployCounter`** 即可完成基于 keystore 的部署流程。
