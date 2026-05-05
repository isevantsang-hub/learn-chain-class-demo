# `forge script DeployCounter` 运行失败：原因与解决思路

## 现象

在项目根目录执行（仅模拟、不发链）：

```bash
forge script script/DeployCounter.s.sol:DeployCounter --rpc-url "$LOCAL_RPC_URL"
```

之前会直接失败，终端类似：

```text
Error: script failed: No deployer configured: set KEYSTORE_PATH or PRIVATE_KEY
```

## 根本原因

部署脚本里的 `getDeployer()` 约定通过下面两种方式之一解析「部署者地址」：

1. 环境变量 **`KEYSTORE_PATH`**：指向 keystore JSON，`vm.readFile` + JSON 解析 `address`（同时需在 `foundry.toml` 配置 **`fs_permissions`**，见《部署脚本-keystore-方案》）。
2. 环境变量 **`PRIVATE_KEY`**：非零时用 `vm.addr(private_key)`。

若两者都未设置，旧逻辑会在 **`getDeployer()`** 里 **`revert`**，脚本尚未执行到部署逻辑就已失败。  
这与 RPC、`forge build` 无关，属于**运行时环境变量未就绪**。

## 解决思路（本项目采用）

### 1. 本地 Anvil 下的「零配置」模拟（推荐课堂/本地调试）

连接 **`anvil`**（默认 RPC 一般为 `http://127.0.0.1:8545`，链 ID **`31337`**）时，常见需求是：**不配任何密钥也能跑通 dry-run**。

因此在脚本中增加第三优先级分支：

- 当 **`KEYSTORE_PATH`、`PRIVATE_KEY` 均未设置**，且 **`block.chainid == 31337`**（Anvil 默认链 ID）时，使用 **Anvil 文档公开的测试账户 #0** 对应的私钥推导地址（该私钥为本地测试众所周知，**绝不用于主网**）。

这样在本地执行：

```bash
anvil   # 终端 1
export LOCAL_RPC_URL="http://127.0.0.1:8545"
forge script script/DeployCounter.s.sol:DeployCounter --rpc-url "$LOCAL_RPC_URL"
```

即可得到成功的模拟输出（例如 Deployer 为 `0xf39F...2266`，并打出合约地址日志）。

### 2. 真实 Keystore / 私钥部署（测试网或需 `--broadcast`）

仍需按原设计设置其一：

```bash
export KEYSTORE_PATH="/path/to/keystore.json"
# 或
export PRIVATE_KEY=0x...
```

发链时再加 **`--broadcast`**，并按 Foundry 要求提供 **`--keystore`** / **`--private-key`** 等与签名一致的钱包参数（Keystore 路径需与脚本读取路径一致）。

### 3. 非 Anvil 链且未配环境变量

若 `--rpc-url` 指向 **Sepolia / 其他测试网或主网**，且未设置 **`KEYSTORE_PATH` / `PRIVATE_KEY`**，脚本仍会 **`revert`**，提示需配置部署者。这是预期行为，避免在未知链上误用默认测试密钥。

## 小结对照

| 场景 | 是否需要设置 `KEYSTORE_PATH` / `PRIVATE_KEY` |
|------|-----------------------------------------------|
| 本地 Anvil（31337），仅模拟 | 否（使用脚本内 Anvil #0 回退） |
| 本地 Anvil，真实 `--broadcast` | 通常仍需 CLI 传入与地址匹配的签名材料 |
| 非 31337 链（如 Sepolia） | 是，必须配置 |

## 仍可能失败的其它情况（扩展排查）

1. **RPC 不可达**：`$LOCAL_RPC_URL` 未启动或端口错误 → 先确认节点/anvil 已运行。  
2. **`KEYSTORE_PATH` 已设但 `readFile` 报错**：检查 **`foundry.toml` 的 `fs_permissions`** 是否覆盖该文件所在目录。  
3. **余额不足**：脚本中有 `require(deployer.balance > 0.1 ether)`；测试网需先领水。  
4. **`--broadcast` 签名失败**：CLI 未传与 `deployer` 一致的 `--keystore` / `--private-key`。

按上表配置后，`forge script ... --rpc-url "$LOCAL_RPC_URL"` 在本地 Anvil 上应能稳定完成模拟。
