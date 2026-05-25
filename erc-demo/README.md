# ERC 标准演示工程（Foundry + Soldeer）

各标准独立目录收纳合约；根目录统一编译与测试。

| 目录 | 标准 | 说明 |
|------|------|------|
| [erc20/](erc20/) | [EIP-20](https://eips.ethereum.org/EIPS/eip-20) | 同质化代币 |
| [erc721/](erc721/) | [EIP-721](https://eips.ethereum.org/EIPS/eip-721) | 非同质化代币（NFT） |
| [erc2612/](erc2612/) | [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612) | 代币 Permit（链下签名授权） |
| [erc777/](erc777/) | [EIP-777](https://eips.ethereum.org/EIPS/eip-777) | 带 Hook 的代币（教学向，生产慎用） |
| [erc1155/](erc1155/) | [EIP-1155](https://eips.ethereum.org/EIPS/eip-1155) | 多类型余额（半同质化） |
| [integration/](integration/) | — | 多标准串联：金库 + 徽章 + 会员 |

教程全文：[note/draf/ERC标准体系教程-串联实战.md](../note/draf/ERC标准体系教程-串联实战.md)

合约按章节放在 `erc20/`、`erc721/` 等目录；**测试**在 `test/<章节>/`（Foundry 约定）。

```bash
cd erc-demo
forge soldeer install
forge test
```
