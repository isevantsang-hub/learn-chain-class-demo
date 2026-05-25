// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankFuzzTest is Test {
    Bank bank;

    function setUp() public {
        bank = new Bank();
    }

    // 模糊测试：随机金额存款并取款
    function testFuzzDepositWithdraw(uint96 depositAmount, uint96 withdrawAmount) public {
        // 假设调用者不是合约地址（避免call问题），实际测试中可用makeAddr
        address user = address(0x1234);

        // 排除零存款的情况
        vm.assume(depositAmount > 0);
        vm.deal(user, depositAmount);
        vm.prank(user);

        bank.deposit{value: depositAmount}();

        if (withdrawAmount > depositAmount) {
            // 应回退
            vm.prank(user);
            vm.expectRevert("Insufficient balance");
            bank.withdraw(withdrawAmount);
        } else if (withdrawAmount > 0) {
            uint256 balanceBefore = user.balance;
            vm.prank(user);
            bank.withdraw(withdrawAmount);
            assertEq(bank.balances(user), depositAmount - withdrawAmount);
            assertEq(user.balance, balanceBefore + withdrawAmount);
        }
    }

    // 模糊测试：多次存款，最终取款总额不能超过存款
    function testFuzzMultipleDeposits(uint64 first, uint64 second, uint64 withdrawTotal) public {

        // 确保至少有一笔存款大于0
        vm.assume(first > 0 && second > 0);

        address user = address(0x5678);
        vm.deal(user, uint256(first) + uint256(second));
        vm.startPrank(user);

        bank.deposit{value: first}();
        bank.deposit{value: second}();
        uint256 total = uint256(first) + uint256(second);
        if (withdrawTotal > total) {
            vm.expectRevert("Insufficient balance");
            bank.withdraw(withdrawTotal);
        } else {
            bank.withdraw(withdrawTotal);
            assertEq(bank.balances(user), total - withdrawTotal);
        }
        vm.stopPrank();
    }
}