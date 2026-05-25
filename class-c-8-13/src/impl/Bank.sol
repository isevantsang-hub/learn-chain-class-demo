// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // 指定合约使用MIT许可证和Solidity编译器版本>=0.8.0

contract Bank {

    mapping(address => uint256) public balances;
    address[3] public topDepositors;
    uint256[3] public topDepositAmounts;
    address private owner;
    uint256 public allAmount;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event OwnerWithdrawn(uint256 amount);

    constructor(address contractDeploy) {
        owner = contractDeploy;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    receive() external payable {
        // 接受ETH的回调函数
        uint256 preDeposit = balances[msg.sender];
        balances[msg.sender] += msg.value;
        allAmount += msg.value;
        updateTopDepositors(msg.sender, preDeposit, balances[msg.sender]);
        emit Deposited(msg.sender, msg.value);
    }


    function withdraw(uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(address(this).balance >= _amount, "Contract insufficient balance");

        balances[msg.sender] -= _amount;
        allAmount -= _amount;
        updateTopDepositors(msg.sender, balances[msg.sender] + _amount, balances[msg.sender]);
        payable(msg.sender).transfer(_amount);
        emit Withdrawn(msg.sender, _amount);
    }

    function withdrawAll() external onlyOwner {
        uint256 _amount = allAmount;
        require(_amount > 0, "No funds to withdraw");
        require(address(this).balance >= _amount, "Insufficient contract balance");

        allAmount = 0;
         // 清除所有存款记录
        for (uint256 i = 0; i < 3; i++) {
            if (topDepositors[i] != address(0)) {
                topDepositors[i] = address(0);
                topDepositAmounts[i] = 0;
            }
        }
        payable(owner).transfer(_amount);
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