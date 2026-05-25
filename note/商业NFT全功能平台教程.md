# 商业 NFT 全功能平台教程

> 对应代码：`erc-demo/src/erc721/`  
> 工程说明：`erc-demo/src/erc721/README.md`  
> 测试示例：`erc-demo/test/erc721/CommercialNFTCommerce.t.sol`

本教程讲解课内 **商业 NFT 主体 + 接受方登记 + 八大业务模块 + Hub 中枢** 的设计思路、合约职责、典型流程与本地运行方式。

**源码注释**：`erc-demo/src/erc721/` 下每个合约、每个方法、每个入参均已补充中文 NatSpec/行内注释，阅读代码时请直接打开对应 `.sol` 文件。

---

## 1. 你要解决什么问题

传统 ERC-721 只规定 **铸造、转移、授权**，不包含：

- 托管、质押、代拍、碎片化、租赁、抵押借贷、空投、时间锁等 **商业场景**；
- **接受方**（托管商、承租人、出借人、中标人）的身份校验；
- 多业务 **接力**（例如：先入托管库，再上架代拍）。

本仓库在 `src/erc721` 用 **「一个 NFT 主体 + 多个授权模块 + 一个 Hub」** 把上述能力串起来，便于学习与二次扩展。

---

## 2. 整体架构

```text
                         ┌─────────────────────┐
                         │   NFTCommerceHub    │  运营 / 编排 / 铸造
                         │   (OPERATOR_ROLE)   │
                         └──────────┬──────────┘
                                    │ wireCommerce / pipeline*
          ┌─────────────────────────┼─────────────────────────┐
          ▼                         ▼                         ▼
 ┌─────────────────┐      ┌──────────────────┐      ┌──────────────────┐
 │  CommercialNFT  │◄────►│ RecipientRegistry │      │   ERC-20 支付币   │
 │  (ERC-721 主体)  │      │  (接受方登记簿)    │      │  (质押/拍/租/贷)  │
 └────────┬────────┘      └──────────────────┘      └──────────────────┘
          │ lockToken / unlockToken
          │ 锁定期间仅 module 可驱动转移
          ▼
 ┌────────────────────────────────────────────────────────────────────┐
 │  NFTCustody │ NFTStaking │ NFTProxyAuction │ NFTFractional       │
 │  NFTRental  │ NFTCollateralLending │ NFTAirdrop │ NFTTimeLock    │
 └────────────────────────────────────────────────────────────────────┘
```

### 2.1 三类核心合约

| 合约 | 文件 | 角色 |
|------|------|------|
| **NFT 主体** | `CommercialNFT.sol` | 全平台统一的 ERC-721；每枚 `tokenId` 可有 `LockInfo`（业务锁定） |
| **接受方** | `RecipientRegistry.sol` | 登记「谁可以作为托管商、承租人、借款人…」 |
| **中枢** | `NFTCommerceHub.sol` | 部署模块、`wireCommerce` 接线、跨模块 pipeline |

### 2.2 八大业务模块

| 模块 | 文件 | `LockType` | 一句话 |
|------|------|------------|--------|
| 托管 | `modules/NFTCustody.sol` | `Custody` | NFT 存入托管库，指定托管接受方 |
| 质押 | `modules/NFTStaking.sol` | `Staking` | 质押 NFT 赚 ERC-20 奖励 |
| 代拍 | `modules/NFTProxyAuction.sol` | `ProxyAuction` | 委托人上架，竞拍人出价，结标交割 |
| 碎片化 | `modules/NFTFractional.sol` | `Fractional` | 锁定 NFT，铸造份额 ERC-20 |
| 租赁 | `modules/NFTRental.sol` | `Rental` | 出租人挂牌，承租人付租金+押金 |
| 抵押借贷 | `modules/NFTCollateralLending.sol` | `Collateral` | 抵押 NFT 借 ERC-20，逾期可清算 |
| 空投 | `modules/NFTAirdrop.sol` | `Airdrop` | Merkle 领取池内 NFT |
| 时间锁 | `modules/NFTTimeLock.sol` | `TimeLock` | 到期释放给指定 beneficiary |

所有模块继承 `modules/NFTCommerceBase.sol`，由 Hub 调用 `wireCommerce` 注入 `commercialNFT` 与 `recipientRegistry`。

---

## 3. NFT 主体：锁定模型（重点）

`CommercialNFT` 在标准 ERC-721 之上增加 **按 token 锁定**：

```solidity
struct LockInfo {
  LockType lockType;      // 当前业务类型
  address module;         // 负责该业务的合约地址
  address beneficiary;    // 商业接受方
  uint256 releaseAt;      // 可选：到期时间
  bytes32 refId;          // 业务单号
}
```

### 3.1 关键接口（`interfaces/ICommercialNFT.sol`）

| 方法 | 谁调用 | 作用 |
|------|--------|------|
| `authorizeModule(module, true)` | 管理员 | 允许某业务合约调用 `lockToken` |
| `lockToken(...)` | 已授权模块 | 登记锁定；**锁定后持有人不能私自转走** |
| `unlockToken(tokenId)` | 当前 `lockInfo.module` | 业务结束，恢复可转移 |
| `getLockInfo(tokenId)` | 任何人 | 查询当前业务状态 |

### 3.2 为何这样设计

- **一个 NFT 合约走天下**：钱包、浏览器只认一个 `CommercialNFT` 地址。
- **业务隔离**：质押逻辑在 `NFTStaking`，拍卖在 `NFTProxyAuction`，互不污染。
- **安全**：`_update` 中若 `lockType != None`，仅允许 `module` 相关转移，避免「质押中被人转走」。

### 3.3 铸造

- `mintCommercial(to, uri)`：需 `MINTER_ROLE`（接线后 Hub 持有）。
- 课内仍保留 `DemoERC721.sol` 作为 **最小 ERC-721 示例**；商业全流程请用 `CommercialNFT`。

---

## 4. 接受方：RecipientRegistry

商业上除了 **NFT 持有人**，还有 **服务提供方 / 交易对手方**（接受方）。

| 角色常量 | 含义 | 典型模块 |
|----------|------|----------|
| `ROLE_CUSTODIAN` | 托管商 | `NFTCustody` |
| `ROLE_CONSIGNOR` | 代拍委托人 | `NFTProxyAuction` |
| `ROLE_BIDDER` | 竞拍人 | `NFTProxyAuction` |
| `ROLE_TENANT` | 承租人 | `NFTRental` |
| `ROLE_BORROWER` | 借款人 | `NFTCollateralLending` |
| `ROLE_LENDER` | 出借人 | `NFTCollateralLending` |
| `ROLE_FRACTION_BUYER` | 份额买方 | （扩展用） |
| `ROLE_AIRDROP_CLAIMER` | 空投领取人 | `NFTAirdrop` |

运营通过 Hub：

```solidity
hub.registerRecipient(account, role, "备注标签");
```

模块内部用 `_requireActiveRecipient(account, role)` 校验，避免与未登记地址成交。

---

## 5. 八大模块：各自怎么用

以下默认已完成：`wireCommerce()`、支付代币 `Pay`、相关地址已 `registerRecipient`。

### 5.1 托管 `NFTCustody`

| 用户操作 | 函数 | 说明 |
|----------|------|------|
| 存入 | `deposit(tokenId, custodian)` | NFT 转入托管合约 → `lockType = Custody` |
| 取出 | `release(tokenId, to)` | 存款人或 Hub 触发，解锁并转回 |
| 接力 | `handoverToModule(tokenId, module, newLock, beneficiary)` | **仅 Hub** 调用；解锁后改锁并转给下一模块 |

**典型入口**：用户先把 NFT 放进托管，再由 Hub 接力到代拍 / 时间锁 / 碎片化。

### 5.2 质押 `NFTStaking`

| 操作 | 函数 |
|------|------|
| 质押 | `stake(tokenId)` |
| 查看收益 | `pendingReward(tokenId)` |
| 退出 | `unstake(tokenId)`（发奖励 ERC-20） |

Hub 可向质押合约充值：`hub.fundStakingRewards(amount)`。

### 5.3 代拍 `NFTProxyAuction`

| 操作 | 函数 |
|------|------|
| 上架 | `listFromCustody(tokenId, consignor, duration)`（Hub 在 handover 后调用） |
| 出价 | `bid(tokenId, amount)`（需 `ROLE_BIDDER`，ERC-20 转入合约） |
| 结标 | `settle(tokenId)`（到期后：NFT→中标人，款→委托人扣平台费） |

**Hub 编排**：`pipelineCustodyToAuction(tokenId, consignor, custodian, auctionSeconds)`。

### 5.4 碎片化 `NFTFractional`

| 操作 | 函数 |
|------|------|
| 持有人碎片化 | `fractionalize(tokenId, totalShares, buyoutPrice)` |
| Hub 接力碎片化 | `fractionalizeHeld(tokenId, owner, shares, buyoutPrice)` |
| 回购 | `buyout(tokenId)`（付 ERC-20 + 收齐份额代币） |

会为每个 `tokenId` 部署一枚 **`FractionShareToken`（ERC-20 份额）**。

**Hub 编排**：`pipelineCustodyToFractional(tokenId, owner, totalShares, buyoutPrice)`。

### 5.5 租赁 `NFTRental`

| 操作 | 函数 |
|------|------|
| 挂牌 | `listForRent(tokenId, rentPerDay, deposit, durationDays)` |
| 承租 | `rent(tokenId, daysToRent)`（需 `ROLE_TENANT`） |
| 结束 | `complete(tokenId)`（租期满，NFT 回出租人，退押金） |

### 5.6 抵押借贷 `NFTCollateralLending`

| 操作 | 函数 |
|------|------|
| 借款 | `borrow(tokenId, lender, principal, interestBps, durationDays)` |
| 还款 | `repay(tokenId)` |
| 清算 | `liquidate(tokenId)`（逾期，NFT 归出借人） |

借款人、出借人均需在 `RecipientRegistry` 登记。

### 5.7 空投 `NFTAirdrop`

| 操作 | 函数 |
|------|------|
| 入池 | `depositToPool(tokenId)` 或 Hub `addToPool` |
| 设置 Merkle 根 | `setMerkleRoot(root)`（Hub） |
| 领取 | `claim(tokenId, proof)`（需 `ROLE_AIRDROP_CLAIMER`） |

叶子节点：`keccak256(bytes.concat(keccak256(abi.encode(account, tokenId))))`（与 OpenZeppelin Merkle 双哈希一致）。

### 5.8 时间锁 `NFTTimeLock`

| 操作 | 函数 |
|------|------|
| 持有人设锁 | `scheduleRelease(tokenId, beneficiary, releaseAt)` |
| Hub 接力 | `scheduleReleaseHeld(...)`（NFT 已在合约内） |
| 到期释放 | `release(tokenId)` → NFT 转给 `beneficiary` |

**Hub 编排**：`pipelineCustodyToTimelock(tokenId, custodian, beneficiary, releaseAt)`。

---

## 6. Hub 编排流程（跨模块）

接线一次：

```solidity
hub.wireCommerce();
```

### 6.1 托管 → 代拍（课内测试覆盖）

```text
1. 用户 hub.custody().deposit(tokenId, custodian)
2. 运营 hub.pipelineCustodyToAuction(tokenId, consignor, custodian, 拍卖秒数)
   └─ custody.handoverToModule → proxyAuction
   └─ proxyAuction.listFromCustody
3. 竞拍人 proxyAuction.bid(tokenId, amount)
4. 到期后 proxyAuction.settle(tokenId)
```

### 6.2 托管 → 时间锁

```text
deposit → pipelineCustodyToTimelock → scheduleReleaseHeld → 到期 release
```

### 6.3 托管 → 碎片化

```text
deposit → pipelineCustodyToFractional → fractionalizeHeld → 可选 buyout
```

---

## 7. 目录与文件说明

```text
erc-demo/src/erc721/
├── CommercialNFT.sol          # NFT 主体
├── RecipientRegistry.sol    # 接受方
├── NFTCommerceHub.sol         # 中枢
├── DemoERC721.sol             # 简易 721（非商业全功能）
├── interfaces/
│   ├── ICommercialNFT.sol
│   └── INFTCommerceModule.sol
└── modules/
    ├── NFTCommerceBase.sol
    ├── NFTCustody.sol
    ├── NFTStaking.sol
    ├── NFTProxyAuction.sol
    ├── NFTFractional.sol
    ├── NFTRental.sol
    ├── NFTCollateralLending.sol
    ├── NFTAirdrop.sol
    └── NFTTimeLock.sol
```

---

## 8. 本地编译与测试

```bash
cd /Users/evan/web3Code/learn-chain-class-demo/erc-demo
forge soldeer install
forge build
forge test --match-path test/erc721/** -vv
```

`CommercialNFTCommerce.t.sol` 演示：**铸造 → 托管 → Hub 代拍 pipeline → 出价 → 结标**。

---

## 9. 部署顺序建议（测试网）

1. 部署 `MockPayToken` 或使用已有 ERC-20（若需 Permit 需代币支持，本 Hub 支付流以 `transferFrom` 为主）。
2. 部署 `CommercialNFT(admin)`、`RecipientRegistry(admin)`。
3. 部署 `NFTCommerceHub(nft, registry, payToken, rewardPerSecond, auctionFeeBps)`。
4. 调用 `hub.wireCommerce()`。
5. `hub.registerRecipient(...)` 登记各方角色。
6. `hub.mintCommercialNFT(user, uri)` 发 NFT。
7. 用户 `approve` 对应模块地址后，按上文调用各业务函数。

---

## 10. 安全与局限（必读）

本仓库为 **教学演示**，未做审计，勿直接用于主网资产：

| 点 | 说明 |
|----|------|
| 权限 | 依赖 `Ownable` / `AccessControl`；生产应使用多签 + Timelock |
| 重入 | 模块使用 `ReentrancyGuard`；扩展时保持 checks-effects-interactions |
| 价格 / 清算 | 借贷、租赁参数极简，无预言机、无健康因子 |
| 碎片化 | `buyout` 需持有人集齐份额，未实现 AMM 二级流通 |
| ERC-777 | 本商业栈 **未接入** 777（见 `draf/business/ERC777-商业案例讲解.md`） |

---

## 11. 延伸阅读（本仓库其他笔记）

| 类型 | 路径 |
|------|------|
| ERC-721 标准与 Demo 代码 | `note/draf/code/ERC721-代码讲解.md` |
| ERC-721 商业案例 | `note/draf/business/ERC721-商业案例讲解.md` |
| ERC-20 支付 / Permit | `note/draf/code/ERC20-代码讲解.md`、`ERC2612-代码讲解.md` |
| 多标准金库 Demo | `erc-demo/src/integration/CrossAssetHub.sol` + `note/draf/code/Integration-代码讲解.md` |

---

## 12. 学习路径建议

1. 读 `CommercialNFT.sol` 注释，理解 `lockToken` / `_update`。
2. 读 `NFTCustody.sol` + `NFTProxyAuction.sol`，跑通 `CommercialNFTCommerce.t.sol`。
3. 逐个模块用 `forge test` 或写小测试调用 `stake`、`listForRent`、`borrow` 等。
4. 用 Hub 的 `pipeline*` 理解 **运营编排**，对照业务文档画自己的流程图。

---

*文档路径：`note/商业NFT全功能平台教程.md` · 代码路径：`erc-demo/src/erc721/`*
