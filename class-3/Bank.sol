// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // 指定合约使用MIT许可证和Solidity编译器版本>=0.8.0

// 定义合约Bank
contract Bank {
    mapping(address => uint256) public deposits; // 记录用户存款的映射，key为地址，value为金额
    address[3] public topDepositors; // 记录前三名存款者的地址数组
    uint256[3] public topDepositAmounts; // 记录前三名存款金额的数组
    address private owner;
    uint256 public allAmount;

    event Deposited(address indexed from, uint256 amount); // 存款事件，记录存款地址和金额
    event Withdrawn(address indexed to, uint256 amount); // 提取时间，记录提取地址和金额
    event OwnerWithdrawn(uint256 amount);

    constructor(address contractDeploy) {
        owner = contractDeploy;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    receive() external payable {
        // 接收以太币的回调函数
        uint256 prevDeposit = deposits[msg.sender]; // 记录用户之前的存款金额
        deposits[msg.sender] += msg.value; // 更新用户存款金额
        allAmount += msg.value;
        updateTopDepositors(msg.sender, prevDeposit, deposits[msg.sender]); // 更新前三名存款者
        emit Deposited(msg.sender, msg.value); // 触发存款事件
    }

    function withdraw(uint256 _amount) external {
        // 提款函数
        require(deposits[msg.sender] >= _amount, "Insufficient balance"); // 检查余额是否足够
        require(
            address(this).balance >= _amount,
            "Contract insufficient balance"
        );

        deposits[msg.sender] -= _amount; // 更新用户存款金额
        allAmount -= _amount;

        updateTopDepositors(
            msg.sender,
            deposits[msg.sender] + _amount,
            deposits[msg.sender]
        ); // 更新前三名存款者

        payable(msg.sender).transfer(_amount); // 转账给用户
        emit Withdrawn(msg.sender, _amount);
    }

    function withdrawAll() external onlyOwner {
        uint256 _amount = allAmount;
        require(_amount > 0, "No funds to withdraw");
        require(
            address(this).balance >= _amount,
            "Insufficient contract balance"
        );
        allAmount = 0;
        // 清除所有存款记录
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] != address(0)) {
                topDepositors[i] = address(0);
                topDepositAmounts[i] = 0;
            }
        }
        payable(msg.sender).transfer(_amount);
        emit OwnerWithdrawn(_amount);
    }
    
    function updateTopDepositors(
        address _user,  
        uint256 _prevDeposit,
        uint256 _newDeposit
    ) private {
        
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


    // 辅助函数：获取合约实际余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
