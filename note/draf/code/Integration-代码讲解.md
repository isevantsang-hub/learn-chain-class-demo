# Integration（多标准串联）代码讲解

**源码**：[`erc-demo/integration/CrossAssetHub.sol`](../../../erc-demo/integration/CrossAssetHub.sol)  
**依赖合约**：`DemoERC20Permit`（20+2612）、`DemoERC1155`、`DemoERC721`。

本合约 **不是** 某个 EIP 的标准接口，而是 **组合调用** 多个标准的应用层金库。

---

## 1. 状态变量与常量

| 名称 | 类型 | 干什么 | 为何这样设计 |
|------|------|--------|--------------|
| `paymentToken` | `IERC20` | 用户存入的支付代币 | 用接口类型，便于换成 USDC 等任意 20 |
| `paymentTokenPermit` | `IERC20Permit` | 同一合约的 Permit 视图 | `IERC20Permit(address(paymentToken))` 强制支付币实现 2612 |
| `badges` | `DemoERC1155` | 发金币（id=1） | 1155 适合批量、可叠加数量 |
| `membership` | `DemoERC721` | 发会员 NFT | 721 适合「唯一身份」 |
| `MIN_BADGE_DEPOSIT` | `100 ether` | 发徽章最低存款 | 业务分层阈值（课内用 18 位小数单位） |
| `MIN_MEMBERSHIP_DEPOSIT` | `1000 ether` | 发会员最低存款 | 更高档位权益 |
| `GOLD_PER_100_ETHER` | `10` | 每满 100 发 10 金币 | 线性激励，便于测试断言 |

`immutable`：部署后不可改引用，省 gas、防管理员换币跑路（地址仍固定）。

---

## 2. `constructor`

```solidity
constructor(IERC20 paymentToken_, DemoERC1155 badges_, DemoERC721 membership_)
```

| 项 | 说明 |
|----|------|
| 不部署子合约 | 由外部先部署 20/1155/721，再注入，利于测试与升级组合 |
| **部署后必做**（测试里体现） | `badges.transferOwnership(hub)`、`membership.transferOwnership(hub)`，否则 Hub 无法 `mint` |

---

## 3. `deposit(uint256 amount)`

```solidity
function deposit(uint256 amount) external {
  paymentToken.safeTransferFrom(msg.sender, address(this), amount);
  _settleRewards(msg.sender, amount);
}
```

| 步骤 | 调用的标准能力 | 干什么 |
|------|----------------|--------|
| 1 | **IERC20** `transferFrom`（经 `SafeERC20`） | 从用户拉取代币到金库；需用户事先 **`approve(hub, amount)`** |
| 2 | 自定义 `_settleRewards` | 按金额发 1155/721 |

### `SafeERC20.safeTransferFrom`（OZ 工具，非 EIP）

| 作用 | 说明 |
|------|------|
| 处理非标准 ERC-20 | 有的老币 `transfer` 不返回 `bool`，SafeERC20 兼容 |
| 失败即 revert | 避免金库记账了但没收到币 |

---

## 4. `depositWithPermit(...)`

```solidity
function depositWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external
```

| 步骤 | 标准 | 干什么 |
|------|------|--------|
| 1 | **IERC20Permit.permit** | 用签名把 `allowance[msg.sender][hub]` 设为 `amount` |
| 2 | **IERC20.transferFrom** | 与 `deposit` 相同拉款 |
| 3 | `_settleRewards` | 相同发奖 |

**设计原因**：合并「授权 + 存款」为用户少签一笔 **`approve` 交易**（仍可能需一笔含 `permit` 的 tx，或由 relayer 提交）。

参数 `v,r,s`：ECDSA 签名；`deadline` 过期则 `permit` 失败。

---

## 5. `_settleRewards`（内部业务逻辑）

```solidity
function _settleRewards(address user, uint256 amount) internal
```

| 条件 | 调用 | 标准行为 |
|------|------|----------|
| `amount >= 1000 ether` | `membership.mint(user, uri)` | **721** 铸造唯一 token，`uri` 含存款额字符串 |
| `amount >= 100 ether` | `badges.mintGold(user, gold)` | **1155** `_mint` id=1；`gold = (amount/100 ether) * 10` |

| 设计点 | 说明 |
|--------|------|
| 大额同时触发两档 | 2000 ether 既 mint 721 又 mint 1155（测试 `test_LargeDepositMintsMembershipAndGold`） |
| `string.concat("ipfs://demo/member/", _toString(amount))` | 会员 metadata 与存款额关联（仅演示） |

### `_toString(uint256 value)`

纯工具函数，**非标准**：把数字转成十进制字符串，供 `tokenURI` 使用。

---

## 6. 事件 `Deposited`

```solidity
event Deposited(address indexed user, uint256 amount, bool membershipMinted, uint256 goldMinted);
```

| 字段 | 用途 |
|------|------|
| `user` | 索引存款人 |
| `amount` | 存款额 |
| `membershipMinted` | 是否发了 721 |
| `goldMinted` | 发了多少 1155 金币（0 表示未达徽章档） |

链下监听此事件可做 CRM、风控、运营报表。

---

## 7. 跨标准调用链（一图）

```text
用户
  │  ERC-2612 permit（可选）
  │  ERC-20 transferFrom
  ▼
CrossAssetHub ──owner──► DemoERC1155.mintGold  (ERC-1155)
              └──owner──► DemoERC721.mint      (ERC-721)
```

**未使用 ERC-777**：避免 Hook 重入与生态兼容成本；见 [ERC777-代码讲解](./ERC777-代码讲解.md)。

---

## 8. 测试文件对照

[`test/integration/CrossAssetHub.t.sol`](../../../erc-demo/test/integration/CrossAssetHub.t.sol)

| 测试 | 验证点 |
|------|--------|
| `test_DepositMintsGoldBadge` | 500 ether → 50 金币，无 721 |
| `test_LargeDepositMintsMembershipAndGold` | 2000 ether → 1 枚 721 + 200 金币 |
| `test_DepositWithPermit` | 签名 + 300 ether → 30 金币 |

---

## 9. 若扩展为生产金库还需什么（非本课范围）

- 提款、`pause`、重入锁、价格预言机、额度上限  
- `paymentToken` 不限定为 `DemoERC20Permit`  
- 1155/721 用角色 `MINTER_ROLE` 代替 `Ownable` 移交  

---

*目录：[00-ERC代码讲解-阅读指南.md](./00-ERC代码讲解-阅读指南.md)*
