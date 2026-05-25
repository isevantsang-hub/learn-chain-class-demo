# ERC 标准体系教程：从 ERC-20 到多标准串联实战

> 配套代码仓库路径：`erc-demo/`  
> 每个标准独立章节目录；统一用 **Foundry + Soldeer** 管理依赖（与 `class-7/my-foundry-project` 一致）。

---

## 阅读地图

| 顺序 | 标准 | EIP | 代码目录 | 你在学什么 |
|------|------|-----|----------|------------|
| 1 | ERC-20 | [EIP-20](https://eips.ethereum.org/EIPS/eip-20) | `erc-demo/erc20/` | 同质化代币：余额、转账、授权 |
| 2 | ERC-721 | [EIP-721](https://eips.ethereum.org/EIPS/eip-721) | `erc-demo/erc721/` | NFT：每枚 `tokenId` 唯一 |
| 3 | ERC-2612 | [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612) | `erc-demo/erc2612/` | 链下签名换 `approve`（Permit） |
| 4 | ERC-777 | [EIP-777](https://eips.ethereum.org/EIPS/eip-777) | `erc-demo/erc777/` | 带 Hook 的代币（**教学向，生产慎用**） |
| 5 | ERC-1155 | [EIP-1155](https://eips.ethereum.org/EIPS/eip-1155) | `erc-demo/erc1155/` | 单合约多 `id` 余额（半同质化） |
| 6 | 串联 | — | `erc-demo/integration/` | 金库：20 + 2612 + 1155 + 721 一条业务流 |

测试统一在 `erc-demo/test/<章节>/`（Foundry 约定 `test/` 根目录）。

```bash
cd erc-demo
forge soldeer install
forge test
```

---

## 0. 为什么需要这么多「ERC」

以太坊上的资产与权限，本质是 **合约状态 + 标准接口**。钱包、区块浏览器、DEX、NFT 市场都依赖 **固定 ABI** 才能「认」你的合约。

- **同质化（Fungible）**：每个单位可互换 → ERC-20 / ERC-777 / ERC-1155 的某一 `id`。
- **非同质化（Non-Fungible）**：每个单位不可互换 → ERC-721；或 ERC-1155 中某 `id` 供应量为 1。
- **授权（Approval）**：第三方代你动资产 → `approve` / `transferFrom`；ERC-2612 用签名代替一次链上 `approve`。

成熟实践：**优先 OpenZeppelin 实现 + 最小自定义逻辑**；本教程在 `erc-demo` 中即采用 OZ 5.6（Soldeer 安装）。

---

## 1. ERC-20：同质化代币

### 1.1 规范要点（EIP-20）

| 函数 / 事件 | 作用 |
|-------------|------|
| `totalSupply()` | 总供应量 |
| `balanceOf(account)` | 账户余额 |
| `transfer(to, amount)` | 直接转账 |
| `approve(spender, amount)` | 授权 `spender` 可动用额度 |
| `transferFrom(from, to, amount)` | 被授权方代转 |
| `allowance(owner, spender)` | 剩余授权额度 |
| `Transfer` / `Approval` 事件 | 链上可索引 |

可选扩展：**`decimals`**（展示用，链上仍是整数）、**`name` / `symbol`**（元数据）。

### 1.2 本仓库案例：`DemoERC20`

路径：`erc-demo/erc20/DemoERC20.sol`

- 继承 OZ `ERC20` + `Ownable`。
- 部署时给 `owner` **100 万枚**（18 位小数）。
- `mint` 仅 `owner` 可调用（教学用；主网应加上限、暂停、审计）。

### 1.3 典型调用顺序

```text
用户 A                    代币合约                 用户 B / 协议 C
  | transfer(B, 100)  -->  余额 A↓ B↑
  | approve(C, 50)    -->  allowance[A][C]=50
  |                       <-- transferFrom(A, B, 50)  (由 C 发起)
```

### 1.4 安全注意

- **`transfer` 误转到合约地址**且合约无取款逻辑 → 永久锁死（除非合约专门实现 rescue）。
- **`approve` 竞态**：先 `approve(0)` 再设新额度，或使用 **increaseAllowance**（OZ 已提供）。
- **不要用 `tx.origin` 做授权判断**（钓鱼风险）。

### 1.5 本地测试

```bash
forge test --match-path test/erc20/**
```

---

## 2. ERC-721：非同质化代币（NFT）

### 2.1 与 ERC-20 的核心差异

| | ERC-20 | ERC-721 |
|---|--------|---------|
| 余额 | `balanceOf` = 数量 | `balanceOf` = 持有 **枚数** |
| 唯一性 | 无 tokenId | `ownerOf(tokenId)` 唯一所有者 |
| 转账 | `transfer(to, amount)` | `transferFrom(from, to, tokenId)` |
| 元数据 | 通常仅 name/symbol | **`tokenURI(tokenId)`** → JSON（图片等） |

### 2.2 本仓库案例：`DemoERC721`

路径：`erc-demo/erc721/DemoERC721.sol`

- `ERC721` + `ERC721URIStorage`：每枚 NFT 独立 URI。
- `mint(to, uri)` 由 owner 铸造，`tokenId` 自增。

### 2.3 `safeTransferFrom` 的意义

若接收方是 **合约**，应实现 `IERC721Receiver.onERC721Received`，否则用 `safeTransferFrom` 会 revert，避免 NFT 卡在无处理能力合约里。

### 2.4 测试

```bash
forge test --match-path test/erc721/**
```

---

## 3. ERC-2612：Permit（链下签名授权）

### 3.1 解决什么问题

传统流程：用户先发一笔 **`approve(router, amount)`**（付 gas），再让 DEX **`transferFrom`**。  
**Permit**：用户对 EIP-712 结构化消息签名，任意人可把签名提交到链上 `permit(...)`，一次性写入 `allowance`，用户少一笔交易。

### 3.2 依赖关系

- 建立在 **ERC-20** 之上（不是独立代币标准，是 **扩展**）。
- 使用 **EIP-712** 域分隔符：`DOMAIN_SEPARATOR = hash(name, version, chainId, verifyingContract)`。
- 防重放：**`nonces(owner)`** 每笔 permit 递增。

### 3.3 本仓库案例：`DemoERC20Permit`

路径：`erc-demo/erc2612/DemoERC20Permit.sol`

- `ERC20` + `ERC20Permit`（OZ 已实现 `permit` / `nonces` / `DOMAIN_SEPARATOR`）。

测试中使用 `vm.sign` + `permit` + `transferFrom` 走通全流程（见 `test/erc2612/DemoERC20Permit.t.sol`）。

### 3.4 与 EIP-3009、账户抽象的关系

- **EIP-3009**（USDC 等）：`transferWithAuthorization`，语义类似但接口不同。
- **ERC-4337**：账户抽象；Permit 仍是 EOA 时代 DEX 体验优化的主流方案之一。

---

## 4. ERC-777：带 Hook 的代币（了解即可）

### 4.1 设计动机

在 **转账前后** 通知发送方 / 接收方合约（`tokensToSend` / `tokensReceived`），便于「转账即订阅」类业务；并支持 **operators** 代操作。

### 4.2 为何生产环境谨慎

- **接收 Hook** 在转账流程中执行外部调用 → 历史上曾出现 **重入、恶意回调** 等风险。
- OpenZeppelin **已在新版库中移除 ERC777 实现**；主流新项多用 ERC-20 + 明确的安全模式。

### 4.3 本仓库案例（精简教学）

| 文件 | 说明 |
|------|------|
| `erc777/DemoERC777.sol` | 精简 `send` / `operatorSend` + ERC-1820 查询 |
| `erc777/ERC777Vault.sol` | 实现 `tokensReceived`，统计入账 |
| `erc777/IERC1820RegistryMinimal.sol` | 本地测试用注册表（主网 canonical：`0x1820…`） |

**结论**：学懂 Hook 与 **ERC-1820 注册** 即可；新项目优先 **ERC-20**，不要默认选 777。

---

## 5. ERC-1155：多类型余额（半同质化）

### 5.1 一个合约，多种 `id`

- `balanceOf(account, id)`：某账户在某 **id** 下的数量。
- `balanceOfBatch`：一次查询多组 `(account, id)`。
- `safeTransferFrom` / `safeBatchTransferFrom`：单笔或批量转移。
- 适合：**游戏道具**（金币 id=1 大量、稀有卡 id=2 少量）、**门票 + 纪念品** 等同合约管理。

### 5.2 与 ERC-20 / 721 选型

| 场景 | 更合适的标准 |
|------|----------------|
| 纯货币、积分 | ERC-20 |
| 每件独一无二、强收藏 | ERC-721 |
| 同合约多种道具、批量空投 | ERC-1155 |

### 5.3 本仓库案例：`DemoERC1155`

- `ID_GOLD = 1`：可大量持有。
- `ID_CARD = 2`：稀有卡。
- `mintBatch` 演示批量铸造。

---

## 6. 串联实战：`CrossAssetHub`

路径：`erc-demo/integration/CrossAssetHub.sol`

### 6.1 业务故事（一条用户旅程）

```text
                    ┌─────────────────────────────────────┐
                    │         CrossAssetHub（金库）          │
                    │  持有：ERC-20 存款                     │
                    │  控制：ERC-1155 / ERC-721 的 mint 权   │
                    └─────────────────────────────────────┘
                                      ▲
          deposit / depositWithPermit │
                                      │
用户持有 DemoERC20Permit ─────────────┘
        │
        ├─≥ 100 ether  → 铸造 ERC-1155 金币（每 100 ether → 10 金币）
        └─≥ 1000 ether → 额外铸造 ERC-721 会员 NFT
```

### 6.2 用到的标准如何配合

| 步骤 | 标准 | 实现 |
|------|------|------|
| 支付 | ERC-20 | `safeTransferFrom` 拉取代币 |
| 免 approve 支付 | ERC-2612 | `depositWithPermit` 先 `permit` 再 `transferFrom` |
| 游戏化奖励 | ERC-1155 | `badges.mintGold(user, gold)` |
| 高价值身份 | ERC-721 | `membership.mint(user, uri)` |
| 未接入 | ERC-777 | 教程中单独成章，避免与金库耦合 |

部署后需将 **1155 / 721 的 owner** 交给 Hub（测试里 `transferOwnership(address(hub))`），否则 Hub 无法代 mint。

### 6.3 测试

```bash
forge test --match-path test/integration/**
```

---

## 7. 标准对照总表

| 标准 | 可分割 | 唯一标识 | 批量操作 | 链下授权 | 合约回调 | 生态现状 |
|------|--------|----------|----------|----------|----------|----------|
| ERC-20 | 是 | 无 | 否 | 需 approve | 无 | 主流 |
| ERC-2612 | （扩展 20） | — | — | **permit 签名** | 无 | DeFi 常用 |
| ERC-721 | 否 | tokenId | 否 | approve 单枚 | safe 转账回调 | NFT 主流 |
| ERC-1155 | 按 id | id | **batch** | operator | safe 回调 | 游戏/空投 |
| ERC-777 | 是 | 无 | 否 | operator | **send/receive hook** | 不推荐新项目 |

---

## 8. Soldeer 与工程结构说明

### 8.1 依赖安装

```bash
cd erc-demo
forge soldeer install
```

依赖落在 `dependencies/`，**勿手改**。`foundry.toml` 中：

- `libs = ["dependencies"]`
- `remappings` 指向 `@openzeppelin-contracts-5.6.0/` 与 `forge-std/`

### 8.2 目录约定

```text
erc-demo/
├── erc20/DemoERC20.sol          # 章节约束：合约在章节目录
├── erc721/...
├── test/erc20/...               # Foundry 测试集中在 test/
├── integration/CrossAssetHub.sol
└── foundry.toml
```

### 8.3 编译器版本

本工程 **`solc = 0.8.24`**，与 OZ 5.6 中部分模块（如 `ERC721`）的 `pragma` 对齐。

---

## 9. 推荐学习顺序（动手清单）

1. 读 `erc20/DemoERC20.sol`，跑 `forge test --match-path test/erc20/**`。
2. 读 `erc721/DemoERC721.sol`，理解 `tokenId` 与 `tokenURI`。
3. 读 `erc2612/DemoERC20Permit.sol`，对照测试理解 `permit` 与 `nonces`。
4. 读 `erc1155/DemoERC1155.sol`，练习 `balanceOfBatch`。
5. 读 `erc777` 两合约 + 测试，理解 **为何 Hook 危险**。
6. 读 `integration/CrossAssetHub.sol`，画出自己的「存款 → 发徽章 → 发会员」流程图。
7. （可选）部署到 Sepolia：为各合约写 `script/Deploy*.s.sol`，参考 `class-7` 的验证攻略做 `forge verify-contract`。

---

## 10. 延伸阅读（官方与成熟项目）

- [Ethereum EIPs](https://eips.ethereum.org/)：规范原文。
- [OpenZeppelin Contracts 文档](https://docs.openzeppelin.com/contracts/5.x/)：生产级实现与 API。
- [Foundry Book](https://book.getfoundry.sh/)：测试、`vm` 作弊码、`forge script`。
- Uniswap、OpenSea 等协议接口：观察其如何 **只依赖标准 ABI** 集成任意符合标准的代币。

---

## 11. 安全清单（上线前自检）

- [ ] 使用经过审计的库版本，锁定 `soldeer.lock`。
- [ ] `mint` / `owner` / `upgrade` 权限最小化，考虑多签或 Timelock。
- [ ] ERC-20：`approve` 竞态与无限授权风险提示。
- [ ] ERC-721/1155：`safeTransfer` 与接收合约兼容性。
- [ ] 不使用 ERC-777 处理大额资产（除非团队精通 Hook 安全）。
- [ ] Permit：deadline、chainId、合约地址必须在签名域内（OZ 已处理，自定义时勿漏）。

---

*文档路径：`note/draf/ERC标准体系教程-串联实战.md` · 代码路径：`erc-demo/` · 与课内 Foundry + Soldeer 工程风格一致。*
