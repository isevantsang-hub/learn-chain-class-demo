# ERC 代码讲解 · 阅读指南

本目录逐份对照 **`erc-demo/`** 中的教学合约与 **EIP 标准接口**，说明每个函数在标准里的定义、在本仓库中的实现位置，以及**为何这样设计**。

| 文档 | 源码目录 | 主要标准 |
|------|----------|----------|
| [ERC20-代码讲解.md](./ERC20-代码讲解.md) | `erc-demo/erc20/` | [EIP-20](https://eips.ethereum.org/EIPS/eip-20) |
| [ERC721-代码讲解.md](./ERC721-代码讲解.md) | `erc-demo/erc721/` | [EIP-721](https://eips.ethereum.org/EIPS/eip-721) |
| [ERC2612-代码讲解.md](./ERC2612-代码讲解.md) | `erc-demo/erc2612/` | [EIP-2612](https://eips.ethereum.org/EIPS/eip-2612)（扩展 EIP-20） |
| [ERC777-代码讲解.md](./ERC777-代码讲解.md) | `erc-demo/erc777/` | [EIP-777](https://eips.ethereum.org/EIPS/eip-777) |
| [ERC1155-代码讲解.md](./ERC1155-代码讲解.md) | `erc-demo/erc1155/` | [EIP-1155](https://eips.ethereum.org/EIPS/eip-1155) |
| [Integration-代码讲解.md](./Integration-代码讲解.md) | `erc-demo/integration/` | 多标准组合 |

实现库：**OpenZeppelin Contracts 5.6**（Soldeer）。标准接口以 OZ 的 `IERC*` 与 [EIP 正文](https://eips.ethereum.org/) 为准。

商业背景见：`../ERC20-商业案例讲解.md` 等；技术总览见：`../ERC标准体系教程-串联实战.md`。
