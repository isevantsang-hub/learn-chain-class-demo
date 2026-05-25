# 串联章节（Integration）

`CrossAssetHub.sol` 将各标准组合为一条业务流：

1. 用户持有 **ERC-20**（本示例为带 **ERC-2612** 的 `DemoERC20Permit`）
2. `deposit` 或 `depositWithPermit` 将代币存入金库
3. 达到阈值后金库（作为 owner）为用户铸造 **ERC-1155** 金币（`ID_GOLD`）
4. 更大额度时额外铸造 **ERC-721** 会员 NFT

**ERC-777** 未接入金库：因其 hooks 与生态支持已弱化，教程中单独成章对比即可。

测试：`../test/integration/CrossAssetHub.t.sol`
