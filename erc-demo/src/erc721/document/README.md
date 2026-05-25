# 商业 NFT 模块（`src/erc721`）

## 架构

| 合约 | 职责 |
|------|------|
| `CommercialNFT.sol` | **NFT 主体**：ERC-721 + 按 token 锁定状态 + 授权业务模块 |
| `RecipientRegistry.sol` | **接受方登记**：托管商、承租人、借款人、竞拍人等 |
| `NFTCommerceHub.sol` | **中枢**：接线八大模块、跨模块编排 |
| `modules/NFTCustody.sol` | 托管 |
| `modules/NFTStaking.sol` | 质押 |
| `modules/NFTProxyAuction.sol` | 代拍 |
| `modules/NFTFractional.sol` | 碎片化（份额 ERC-20） |
| `modules/NFTRental.sol` | 租赁 |
| `modules/NFTCollateralLending.sol` | 抵押借贷 |
| `modules/NFTAirdrop.sol` | 空投（Merkle） |
| `modules/NFTTimeLock.sol` | 时间锁 |

## 部署与接线

```bash
cd erc-demo
forge soldeer install
forge test --match-path test/erc721/**
```

1. 部署 `CommercialNFT`、`RecipientRegistry`、`NFTCommerceHub`（传入支付代币地址等）。
2. 调用 `hub.wireCommerce()` 授权全部模块。
3. 通过 `hub.registerRecipient` 登记商业接受方。

## 交互关系

- 所有模块仅能通过已授权的 `lockToken` / `unlockToken` 驱动 **CommercialNFT** 的转移限制。
- **托管** 可作为入口；Hub 提供 `pipelineCustodyToAuction`、`pipelineCustodyToTimelock`、`pipelineCustodyToFractional` 等接力。

系统教程见：[note/商业NFT全功能平台教程.md](../../../note/商业NFT全功能平台教程.md)
