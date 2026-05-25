# Foundry `vm` 作弊码：学习与测试攻略（小白向）

在 Foundry 测试里，`vm` 是 **`forge-std` 提供的「作弊器」**：只在本地测试执行时生效，**不会**出现在主网真实部署里。  
用好它们，你可以**假装自己是别的地址、改时间、改余额、断言会失败**，从而把复杂链上场景缩成几行测试。

使用前提：测试合约继承 `forge-std/Test.sol`，即可直接使用 `vm.xxx()`。

---

## 一、先建立心智模型

| 想法 | 对应思路 |
|------|----------|
| 「下一句调用要是 Alice 发的」 | `vm.prank(alice)` |
| 「接下来好几句都当是 Bob」 | `vm.startPrank(bob)` … `vm.stopPrank()` |
| 「这个地址要有 100 ETH」 | `vm.deal(addr, 100 ether)` |
| 「现在要是明天」 | `vm.warp(block.timestamp + 1 days)` |
| 「我断言下一句会 revert」 | `vm.expectRevert(...)` |

作弊码让你**控制测试宇宙**，专注验证合约逻辑对不对。

---

## 二、身份与调用者（最常用）

### `vm.prank(address who)`

**下一条**外部调用里的 `msg.sender` 变成 `who`，**只生效一次**。

```solidity
vm.prank(alice);
token.transfer(bob, 1 ether); // 相当于 alice 在调 transfer
```

本仓库示例：`test/Token10000WithCallbacks.t.sol` 里 `vm.prank(alice)` 后由 alice 操作。

### `vm.startPrank` / `vm.stopPrank`

从 `startPrank(who)` 到 `stopPrank()` 之间的**多次**调用，`msg.sender` 都是 `who`。

```solidity
vm.startPrank(alice);
token.approve(bob, 100);
token.transfer(carol, 10);
vm.stopPrank();
```

### `vm.addr(uint256 privateKey)`

用私钥推出地址（测试里造账号很方便）。**勿在主网脚本里硬编码真私钥。**

```solidity
uint256 pk = 0xA11CE; // 仅测试用假私钥
address alice = vm.addr(pk);
```

---

## 三、余额与资产

### `vm.deal(address who, uint256 newBalance)`

把 `who` 的 **ETH 余额**设为 `newBalance`（ wei ）。

```solidity
vm.deal(alice, 50 ether);
```

### `deal(IERC20 token, address to, uint256 balance)`（Test 合约上的辅助函数）

`Test` 里还有 `deal` 重载，可给**任意 ERC20** 刷余额（内部用 `vm.store` 改存储），写集成测试很省事。

```solidity
deal(address(token), alice, 1_000e18);
```

---

## 四、时间与区块

### `vm.warp(uint256 timestamp)`

把 **当前区块时间戳**设为 `timestamp`（用于解锁、倒计时、冷却等测试）。

```solidity
vm.warp(block.timestamp + 7 days);
```

### `vm.roll(uint256 blockNumber)`

把 **当前区块号**设为 `blockNumber`。

```solidity
vm.roll(block.number + 100);
```

---

## 五、断言「应该失败 / 应该发事件」（写测试必会）

### `vm.expectRevert`

**紧接着的下一次调用**必须 `revert`，否则测试失败。

```solidity
vm.expectRevert(bytes("ERC1363: transfer to non-contract"));
token.transferAndCall(eoa, 1 ether, "");
```

也可传自定义错误、abi.encodeWithSelector(Error.selector, ...) 等，与合约里 `revert` 形式对齐即可。

### `vm.expectEmit`

断言**下一条**会触发的事件是否与 `emit` 的期望一致；参数四个 `bool` 分别控制是否检查 topic1、topic2、topic3、data。

本仓库示例：

```solidity
vm.expectEmit(true, true, false, true);
emit TransferCallback(holder, holder, amount, hex"01");
token.transferAndCall(address(recv), amount, hex"01");
```

初学可先抄项目里写法，再对照 [Foundry Book - expectEmit](https://book.getfoundry.sh/cheatcodes/expect-emit) 调四个布尔。

### `vm.expectCall` / `vm.mockCall`

进阶：断言「某地址会被以某 calldata 调用」，或**伪造**某次调用的返回值（测与你合约对接的外部依赖）。做 Mock 时常用。

---

## 六、Fuzz 与假设

### `vm.assume(bool condition)`

在**属性测试（fuzz）**里，不满足 `condition` 的随机输入会被丢弃、重新生成。避免无意义输入（例如要求 EOA 却随机到合约地址）。

本仓库示例：

```solidity
vm.assume(eoa.code.length == 0);
```

### `bound(value, min, max)`（`Test` 里）

把 fuzz 出来的 `value` 限制在 `[min, max]`，减少极端值导致用例无意义。

---

## 七、存储与标签（调试与学习）

### `vm.load` / `vm.store`

直接读、写某合约某 **slot** 的 32 字节字。威力大，需清楚布局（或用 `stdStorage` 找 slot）。

```solidity
bytes32 slot = vm.load(address(token), bytes32(uint256(0)));
```

初学可暂缓，先会用 `deal` 等高层辅助。

### `vm.label(address, string)`

在 trace 里给地址起**人类可读名字**，看失败日志更舒服。

```solidity
vm.label(alice, "Alice");
```

---

## 八、环境与文件（和「部署脚本」重叠）

### `vm.envUint` / `vm.envString` / `vm.envOr` 等

读环境变量（脚本与测试都可用）。你课内 `DeployCounter` 里用 `vm.envString("KEYSTORE_PATH")` 即此类。

### `vm.readFile` / `vm.writeFile`

读本地文件（需在 `foundry.toml` 配置 `fs_permissions`）。**仅测试/本地**，勿依赖主网链上可读文件。

---

## 九、分叉与 RPC（进阶但常用）

### `vm.createSelectFork(string url)` / `vm.createFork`

从某 RPC **拉真实链状态**到本地，测与 Uniswap 等真实合约的交互。需网络与 RPC URL。

```solidity
vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
```

学习中期再开这条线即可。

---

## 十、小抄表（速查）

| 作弊码 | 一句话 |
|--------|--------|
| `prank` | 下一句调用换 `msg.sender` |
| `startPrank` / `stopPrank` | 一段调用内持续换身份 |
| `deal`（vm） | 改 ETH 余额 |
| `deal`（Test） | 改某 ERC20 某地址余额 |
| `warp` | 改 `block.timestamp` |
| `roll` | 改 `block.number` |
| `expectRevert` | 断言下一句必失败 |
| `expectEmit` | 断言下一句事件 |
| `assume` | Fuzz 时过滤输入 |
| `label` | 调试时给地址起名 |
| `load` / `store` | 直接读写存储槽 |
| `createSelectFork` | 分叉真实链做集成测试 |

官方完整列表与参数说明以文档为准：  
[Foundry Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)

---

## 十一、学习建议（怎么用这篇最划算）

1. **先抄后改**：打开 `test/Token10000WithCallbacks.t.sol`，对照本文找 `vm.prank`、`vm.expectRevert`、`vm.expectEmit`、`vm.assume`。  
2. **每次只学 1～2 个**：写一个小测试专门试 `warp` + 你的时间锁逻辑。  
3. **作弊码只用于测试**：业务合约里**不要**依赖 `vm`（编译也不会通过）；脚本里可用部分 `vm`（如 `readFile`），与测试场景区分清楚。

把「会写断言 + 会换 `msg.sender` + 会改时间」练熟，你已经能覆盖大部分课内与初级项目测试需求。

---

*文档路径：`md/draf/Foundry-vm作弊码-学习与测试攻略.md`*
