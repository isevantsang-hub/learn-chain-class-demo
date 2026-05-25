# ERC-20 代码讲解

**源码**：[`erc-demo/erc20/DemoERC20.sol`](../../../erc-demo/erc20/DemoERC20.sol)  
**继承**：`ERC20` → 实现 `IERC20`；`Ownable` → 单管理员。

---

## 1. 本合约自定义部分

### 1.1 `INITIAL_SUPPLY`

```solidity
uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10 ** 18;
```

| 项 | 说明 |
|----|------|
| 作用 | 部署时一次性铸造的上限基数（100 万枚，18 位小数）。 |
| 为何用 `constant` | 编译期固定，省 gas，表达「经济模型参数不可变」。 |
| 与标准关系 | EIP-20 **未规定**初始供应；由项目方在 `_mint` 时决定。 |

### 1.2 `constructor(address initialOwner)`

```solidity
constructor(address initialOwner) ERC20("Demo ERC20", "D20") Ownable(initialOwner) {
  _mint(initialOwner, INITIAL_SUPPLY);
}
```

| 调用 | 作用 |
|------|------|
| `ERC20("Demo ERC20", "D20")` | 设置 **EIP-20 元数据扩展** 中的 `name` / `symbol`（OZ 在 `ERC20` 内实现，非最简 `IERC20` 必选，但生态默认要求）。 |
| `Ownable(initialOwner)` | 将 `owner` 设为部署时传入地址，后续 `onlyOwner` 修饰符生效。 |
| `_mint(initialOwner, INITIAL_SUPPLY)` | **内部** 增加总供应与余额；对应一次 `Transfer(from=0, to=owner)`。 |

**设计原因**：把初始铸币权交给 `owner`，避免 `msg.sender` 与业务管理员不一致；教学项目常用模式。

### 1.3 `mint(address to, uint256 amount)`

```solidity
function mint(address to, uint256 amount) external onlyOwner {
  _mint(to, amount);
}
```

| 项 | 说明 |
|----|------|
| 标准中是否存在 | **否**。EIP-20 只定义转账与授权，**增发**是项目自定义。 |
| `onlyOwner` | 防止任意地址无限铸币（教学版；生产还需上限、事件、多签）。 |
| `_mint`（OZ 内部） | 更新 `_totalSupply`、`_balances[to]`，发出 `Transfer(address(0), to, amount)`。 |

---

## 2. 标准接口 `IERC20`（EIP-20 必选）

规范：[EIP-20](https://eips.ethereum.org/EIPS/eip-20)。  
OZ 定义：[`IERC20.sol`](../../../erc-demo/dependencies/@openzeppelin-contracts-5.6.0/token/ERC20/IERC20.sol)

### 2.1 事件

| 事件 | 参数 | 干什么 | 为何需要 |
|------|------|--------|----------|
| `Transfer` | `from`, `to`, `value` | 记录代币移动 | 区块浏览器、索引器、对账；`from=0` 表示铸造，`to=0` 表示销毁 |
| `Approval` | `owner`, `spender`, `value` | 记录授权额度 | DEX/借贷协议监听后知「Router 可代扣多少」 |

### 2.2 视图函数

| 函数 | 签名 | 干什么 | 为何这样设计 |
|------|------|--------|--------------|
| `totalSupply` | `() → uint256` | 全网代币总量 | 定价、通胀模型、审计 |
| `balanceOf` | `(account) → uint256` | 某地址余额 | 钱包展示；DeFi 计算抵押率 |
| `allowance` | `(owner, spender) → uint256` | `spender` 还能从 `owner` 转走多少 | **委托消费**模型：用户不必先转币给协议，只需授权 |

### 2.3 状态变更函数

| 函数 | 干什么 | 典型调用方 | 设计要点 |
|------|--------|------------|----------|
| `transfer(to, value)` | 调用者把自己的币转给 `to` | 用户钱包 | 最简单支付路径；**不检查** `to` 是否为合约，误转可能锁死 |
| `approve(spender, value)` | 授权 `spender` 额度 | 用户 → 首次用 DEX 前 | 解决「第三方代扣」；有 **approve 竞态**（先改非零额度时需注意） |
| `transferFrom(from, to, value)` | spender 在授权内代转 | Uniswap Router、金库 | 组合 `approve` 实现「用户不动、协议拉款」 |

**DemoERC20** 未重写上述函数，行为与 OZ `ERC20` 默认实现一致。

---

## 3. OZ 扩展（非 EIP-20 最简接口，但 Demo 实际具备）

| 接口/函数 | 来源 | 干什么 | 为何常见 |
|-----------|------|--------|----------|
| `name()` | `IERC20Metadata` | 代币全名 | 钱包、区块浏览器展示 |
| `symbol()` | 同上 | 简称如 `D20` | 交易对显示 |
| `decimals()` | 同上 | 小数位数（本合约为 **18**） | 仅 UI 换算；链上仍是整数最小单位 |

---

## 4. `Ownable` 相关（非 ERC-20，但本合约使用）

| 函数 | 干什么 | 与 `mint` 的关系 |
|------|--------|------------------|
| `owner()` | 当前管理员 | 谁可 `mint` |
| `transferOwnership(newOwner)` | 转移管理权 | 运维/多签升级 |
| `renounceOwnership()` | 放弃 owner（不可逆） | 若调用则无人能再 `mint` |

---

## 5. 调用关系简图

```text
用户/协议                    DemoERC20 (ERC20)
    |-- transfer -----------> 余额记账 + Transfer 事件
    |-- approve -----------> allowance 映射
    |-- transferFrom ------> 扣 allowance + 转账
    |
owner |-- mint ------------> _mint（非标准，自定义）
```

---

## 6. 与测试的对应

[`test/erc20/DemoERC20.t.sol`](../../../erc-demo/test/erc20/DemoERC20.t.sol) 验证：`INITIAL_SUPPLY` 余额、`transfer`、`approve` + `transferFrom`。

---

*下一篇：[ERC721-代码讲解.md](./ERC721-代码讲解.md)*
