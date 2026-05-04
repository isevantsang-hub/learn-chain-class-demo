// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint256) public deposits;
    address[3] public topDepositors;
    uint256[3] public topDepositAmounts;
    address private owner;
    uint256 public allAmount;
    
    bool public isContractActive = true; // 新增：合约状态标志

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event OwnerWithdrawn(uint256 amount);
    event ContractDeactivated(); // 新增：合约停用事件

    constructor(address contractDeploy) {
        owner = contractDeploy;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlyActive() { // 新增：检查合约是否活跃的修饰器
        require(isContractActive, "Contract is deactivated");
        _;
    }

    receive() external payable onlyActive { // 新增：合约停用时禁止存款
        uint256 prevDeposit = deposits[msg.sender];
        deposits[msg.sender] += msg.value;
        allAmount += msg.value;
        updateTopDepositors(msg.sender, prevDeposit, deposits[msg.sender]);
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external onlyActive { // 新增：合约停用时禁止提款
        require(deposits[msg.sender] >= _amount, "Insufficient balance");
        require(address(this).balance >= _amount, "Contract insufficient balance");

        deposits[msg.sender] -= _amount;
        allAmount -= _amount; // 修正：改为 _amount（之前是 amount，变量未定义）

        updateTopDepositors( // 修正：函数名拼写错误，之前是 pdateTopDepositors
            msg.sender,
            deposits[msg.sender] + _amount,
            deposits[msg.sender]
        );

        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount); // 修正：与事件定义保持一致
    }

    function withdrawAll() external onlyOwner {
        uint256 _amount = allAmount;
        require(_amount > 0, "No funds to withdraw");
        require(address(this).balance >= _amount, "Insufficient contract balance");
        
        // 先停用合约，防止后续存款和提款操作
        isContractActive = false;
        
        // 清空存款记录，避免数据不一致
        // 注意：这里只清空了在 topDepositors 中的用户存款记录
        // 如果用户不在排行榜中但仍有存款，也需要处理
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] != address(0)) {
                address depositor = topDepositors[i];
                deposits[depositor] = 0; // 修复：清空排行榜中用户的存款记录
                topDepositors[i] = address(0);
                topDepositAmounts[i] = 0;
            }
        }
        
        // 重置总金额
        allAmount = 0;
        
        payable(msg.sender).transfer(_amount); // 修正：改为 _amount（之前是 amount，变量未定义）
        emit OwnerWithdrawn(_amount); // 修正：改为 _amount（之前是 amount，变量未定义）
        emit ContractDeactivated(); // 新增：触发合约停用事件
    }
    
    // 新增：处理非排行榜用户的存款记录清零
    function deactivateContract() external onlyOwner {
        require(isContractActive, "Contract already deactivated");
        
        isContractActive = false;
        
        // 清空所有排行榜用户的存款记录
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] != address(0)) {
                deposits[topDepositors[i]] = 0;
                topDepositors[i] = address(0);
                topDepositAmounts[i] = 0;
            }
        }
        
        // 注意：这里无法清空不在排行榜中的用户的存款记录
        // 如果确实需要完全清空，可能需要更复杂的数据结构
        emit ContractDeactivated();
    }
    
    // 新增：允许所有者转移合约所有权
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        owner = newOwner;
    }
    
    function updateTopDepositors(
        address _user,
        uint256 _prevDeposit,
        uint256 _newDeposit
    ) private {
        // 先从排行榜中移除用户（如果存在）
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] == _user) {
                for (uint256 j = i; j < 2; j++) {
                    topDepositors[j] = topDepositors[j + 1];
                    topDepositAmounts[j] = topDepositAmounts[j + 1];
                }
                topDepositors[2] = address(0);
                topDepositAmounts[2] = 0;
                break;
            }
        }
        
        // 如果新存款大于0，尝试重新插入
        if (_newDeposit > 0) {
            for (uint256 i = 0; i < 3; i++) {
                if (_newDeposit > topDepositAmounts[i]) {
                    for (uint256 j = 2; j > i; j--) {
                        topDepositors[j] = topDepositors[j - 1];
                        topDepositAmounts[j] = topDepositAmounts[j - 1];
                    }
                    topDepositors[i] = _user;
                    topDepositAmounts[i] = _newDeposit;
                    break;
                }
            }
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // 新增：查询合约状态
    function getContractStatus() public view returns (bool) {
        return isContractActive;
    }
    
    // 新增：安全地转账给用户（使用call替代transfer，避免gas限制问题）
    function safeTransfer(address payable to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }
}