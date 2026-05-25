# LearnNFT（ERC-721）+ Foundry Soldeer：零基础学习与 Sepolia 验证攻略

本文配合本目录工程 **`class-10/erc721-learn`**，说明：

1. **Soldeer** 如何管理依赖（与 `class-7/my-foundry-project` 同套路）；  
2. **ERC-721** 最小概念；  
3. 本地 **编译 / 测试**；  
4. **Sepolia** 部署与 **Etherscan 源码验证**（含构造函数参数）。

主合约：`src/LearnNFT.sol` → **`LearnNFT`**。  
部署脚本：`script/DeployLearnNFT.s.sol` → **`DeployLearnNFT`**。

---

## 一、先确认「本项目在用什么」

| 项目 | 值 |
|------|-----|
| 依赖管理 | **Soldeer**（依赖落在 `dependencies/`，勿手改包内代码） |
| OpenZeppelin | **5.6.0**（映射前缀 `@openzeppelin-contracts-5.6.0/`） |
| forge-std | **1.16.0** |
| 编译器（以 `foundry.toml` 为准） | **Solidity 0.8.24**（与 OpenZeppelin 5.6 中 `ERC721` 的 `pragma` 一致） |
| 优化器 | **开启**，**200 runs** |
| 合约路径与名称 | `src/LearnNFT.sol` → **`LearnNFT`** |
| 构造参数 | **1 个**：`address initialOwner`（管理员，通常为部署地址） |

若你修改过 `solc` / `optimizer` / `optimizer_runs`，**验证时必须与部署当次编译配置一致**，否则会出现 **Bytecode does not match**。

---

## 二、Soldeer：拉依赖与目录含义

### 2.1 为什么用 Soldeer

依赖版本写在 **`foundry.toml` 的 `[dependencies]`**（本仓库同时保留 **`soldeer.toml`** 便于单独用 Soldeer CLI 对照）。执行安装后，包体在 **`dependencies/`** 下，例如：

- `dependencies/@openzeppelin-contracts-5.6.0/`（合约内 import 形如 **`@openzeppelin-contracts-5.6.0/token/...`**，Soldeer 包布局**无** `contracts/` 这一层目录，勿与 npm 文档路径混淆。）
- `dependencies/forge-std-1.16.0/`

`foundry.toml` 里 **`libs = ["dependencies"]`** 与 **`remappings`** 已指向上述路径；合约里 `import` 使用 **`@openzeppelin-contracts-5.6.0/token/...`**、**`@openzeppelin-contracts-5.6.0/access/...`** 与 **`forge-std/...`**。

### 2.2 首次安装 / 换机后安装

在**项目根**（含 `foundry.toml` 的目录）执行：

```bash
cd /Users/evan/web3Code/learn-chain-class-demo/class-10/erc721-learn
forge soldeer install
```

成功后应出现 `dependencies/` 目录，且可执行：

```bash
forge build
forge test
```

若网络或 registry 异常，检查代理与 Foundry 版本；仍失败可对照 **`class-7/my-foundry-project`** 的 Soldeer 配置逐项比对。

---

## 三、ERC-721 是什么（与 ERC-20 对比）

| 维度 | ERC-20 | ERC-721（NFT） |
|------|--------|----------------|
| 余额含义 | 代币「数量」 | 持有「多少枚」NFT |
| 唯一标识 | 合约地址一类资产 | **合约地址 + tokenId** 标识一枚 |

本仓库 **`LearnNFT`**：`mint(to, uri)` 为 `to` 铸造一枚新 token，并设置 **`tokenURI`**（多为 `ipfs://...` 或 `https://...` 的 metadata JSON 链接）。仅 **`owner`**（`Ownable`）可 `mint`。

---

## 四、前置条件（环境变量）

1. 复制模板并编辑（**勿**将 `.env` 提交到 Git）：

```bash
cd /Users/evan/web3Code/learn-chain-class-demo/class-10/erc721-learn
cp .env.example .env
```

2. 在 `.env` 中至少配置：

   - `SEPOLIA_RPC_URL`：Sepolia JSON-RPC。  
   - `SEPOLIA_ETHERSCAN_API_KEY`：与 `foundry.toml` 中 `${SEPOLIA_ETHERSCAN_API_KEY}` 一致；在 [Etherscan API Keys](https://etherscan.io/myapikey) 申请。  
   - `PRIVATE_KEY`：部署账户私钥（**仅建议测试网**；脚本通过 `vm.envUint("PRIVATE_KEY")` 读取）。

3. 执行前加载环境变量：

```bash
source .env
```

---

## 五、本地编译与测试

```bash
cd /Users/evan/web3Code/learn-chain-class-demo/class-10/erc721-learn
forge build
forge test -vv
```

测试文件 **`test/LearnNFT.t.sol`** 覆盖：owner 铸造、非 owner 铸造失败、转账后 `ownerOf` / `balanceOf` 变化。建议先读 **`src/LearnNFT.sol`**，再对照测试。

---

## 六、部署到 Sepolia（可选顺带验证）

`foundry.toml` 已配置 **`[rpc_endpoints]`** 的 **`sepolia`** 与 **`[etherscan]`**，可直接：

```bash
cd /Users/evan/web3Code/learn-chain-class-demo/class-10/erc721-learn
source .env

forge script script/DeployLearnNFT.s.sol:DeployLearnNFT \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv
```

说明：

- 脚本将 **`LearnNFT(initialOwner)`** 中的 **`initialOwner`** 设为 **`PRIVATE_KEY` 对应地址**，即部署者与合约管理员为同一地址。  
- **`--verify`** 在广播成功后向 Etherscan 提交验证；若出现 **`Could not detect deployment`** 等提示，多为索引延迟，可等待 1～2 分钟后用下一节命令**单独补验证**。

部署完成后，终端或 **`broadcast/.../run-latest.json`** 中可找到合约地址，请记下用于验证与 `cast` 调用。

---

## 七、推荐方式：`forge verify-contract`（部署后补验证）

将 **`YOUR_NFT_ADDRESS`** 换成链上 **`LearnNFT`** 地址；将 **`OWNER_ADDRESS`** 换成部署时传入构造函数的 **`initialOwner`**（本仓库脚本下与部署者地址相同）。

```bash
cd /Users/evan/web3Code/learn-chain-class-demo/class-10/erc721-learn
source .env

forge verify-contract \
  YOUR_NFT_ADDRESS \
  src/LearnNFT.sol:LearnNFT \
  --chain sepolia \
  --constructor-args $(cast abi-encode "constructor(address)" OWNER_ADDRESS) \
  --etherscan-api-key "$SEPOLIA_ETHERSCAN_API_KEY"
```

若 `[etherscan]` 已匹配环境变量，部分 Foundry 版本可省略 **`--etherscan-api-key`**；失败时再显式传入。

**成功标志：** 终端出现类似 **`Contract successfully verified`**；浏览器打开：

`https://sepolia.etherscan.io/address/YOUR_NFT_ADDRESS#code`

应能看到 **Contract Source Code**。

---

## 八、部署后自检（与「验证」不同）

「源码验证」是给人看代码；链上是否存在预期接口可用 **`cast`**：

```bash
cast call YOUR_NFT_ADDRESS "owner()(address)" --rpc-url sepolia
cast call YOUR_NFT_ADDRESS "totalMinted()(uint256)" --rpc-url sepolia
```

能正常返回说明该地址上存在兼容 ABI 的合约（通常即你部署的 **`LearnNFT`**）。

---

## 九、常见问题

| 现象 | 处理方向 |
|------|----------|
| **`dependencies/` 为空 / import 找不到** | 在项目根执行 **`forge soldeer install`**，确认 `foundry.toml` 的 **`libs`** 与 **`remappings`** 未被改坏。 |
| **Bytecode does not match** | 核对 solc 版本、optimizer runs、源码是否与部署时一致；构造函数参数是否传错。 |
| **Already Verified** | 该地址已验证，直接看浏览器 Contract 页。 |
| **Invalid API Key** | 检查 **`SEPOLIA_ETHERSCAN_API_KEY`** 与 `foundry.toml` 占位符是否一致。 |

---

## 十、与「验证别人的合约」的关系

本文面向 **你本人** 使用本仓库脚本部署的 **`LearnNFT`**。若验证他人未公开的合约，需要对方相同的源码与编译元数据；否则无法替其在 Etherscan 上完成验证。

---

*文档路径：`md/draf/LearnNFT-ERC721与Soldeer及Sepolia验证攻略.md`，与 `script/DeployLearnNFT.s.sol`、`src/LearnNFT.sol` 配套。*
