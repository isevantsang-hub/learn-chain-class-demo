# Foundry + Keystore 攻略重组版（`md/new`）阅读指南

本目录将原散落在 **`my-foundry-project/md/`** 与项目根目录的部分说明，按**学习顺序**拆成多章，便于按需查阅。  
**不包含 Solidity 源码修改**，仅为文档重组与提炼。

---

## 推荐阅读顺序

| 顺序 | 文件 | 内容概要 |
|------|------|----------|
| 1 | **`01-Foundry基础-项目结构合约与测试.md`** | `forge init`、目录、`Counter` 示例、`forge build` / `forge test` |
| 2 | **`02-Keystore与私钥-部署方式与MetaMask.md`** | 能否只用 Keystore、MetaMask → `cast wallet import`、基础部署命令 |
| 3 | **`03-部署脚本原理-readFile与编译陷阱.md`** | 为何没有 `vm.getAddressFromKeystore`、`readFile`、`fs_permissions` |
| 4 | **`04-环境变量与KEYSTORE_PATH陷阱.md`** | `envOr` 重载、`--keystore` ≠ `vm.env`、无 `.address`、`.env` 里勿写 `$(...)`、`DEPLOYER_ADDRESS` |
| 5 | **`05-forge-script模拟与broadcast钱包解锁.md`** | 模拟 vs 广播、`Unlocked wallets: []`、须带 `--keystore` |
| 6 | **`06-Sepolia部署流程与Unlocked排查.md`** | export → `cast wallet address` → 先模拟再 `--broadcast --verify` |
| 7 | **`07-测试网验证警告与排查.md`** | `Could not detect deployment`、索引延迟、验证失败怎么办 |
| 8 | **`08-Counter链上交互命令-本地与Sepolia.md`** | `cast call` / `cast send`、命令格式注意 |
| 9 | **`09-附录-历史笔记与其它文档索引.md`** | 脚本曾出现的「无 deployer」说明、根目录 `编译警告` 等索引 |

---

## 与旧文档的对应关系（便于搜索）

- 原 **`md/Foundry入门教程-*.md`** → 拆入第 1～2 章。  
- 原 **`部署攻略-Keystore与私钥如何选择.md`**、**`部署脚本-keystore-方案.md`**、**`KEYSTORE_PATH-envOr*.md`**、**`Keystore无address*.md`** → 第 3～4 章。  
- 原 **`forge-script-broadcast*.md`**、**`forge-script-运行失败*.md`**、**`Sepolia广播-Unlocked*.md`** → 第 5～6 章。  
- 原 **`测试网警告排查.md`** → 第 7 章。  
- 原 **`Counter已部署-*.md`**、**`Sepolia测试网-Counter*.md`** → 第 8 章。

项目根目录下的 **`部署合约代码错误说明.md`**（`getAddressFromKeystore` 编译错误）已融入 **第 3 章**。
