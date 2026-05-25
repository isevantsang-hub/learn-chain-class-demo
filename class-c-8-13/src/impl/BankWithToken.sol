// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC1363} from "./IERC1363.sol";
import {IERC1363Receiver} from "./IERC1363Receiver.sol";
import {IERC1363Spender} from "./IERC1363Spender.sol";

contract BankWithToken is IERC1363Receiver, IERC1363Spender {
    IERC1363 public immutable token;
    address public owner;
    mapping(address => uint256) public deposits;
    uint256 public totalDeposits;

    event TokenDeposited(address indexed user, uint256 amount);
    event TokenWithdrawn(address indexed user, uint256 amount);
    event OwnerRecovered(uint256 amount);

    constructor(IERC1363 tokenAddress) {
        token = tokenAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Bank: not owner");
        _;
    }

    function onTransferReceived(address, address from, uint256 value, bytes calldata)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(token), "Bank: only token");
        deposits[from] += value;
        totalDeposits += value;
        emit TokenDeposited(from, value);
        return IERC1363Receiver.onTransferReceived.selector;
    }

    function onApprovalReceived(address owner_, uint256 value, bytes calldata)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(token), "Bank: only token");
        require(token.transferFrom(owner_, address(this), value), "Bank: transferFrom failed");
        deposits[owner_] += value;
        totalDeposits += value;
        emit TokenDeposited(owner_, value);
        return IERC1363Spender.onApprovalReceived.selector;
    }

    function withdrawToken(uint256 amount) external {
        uint256 balance = deposits[msg.sender];
        require(balance >= amount, "Bank: insufficient deposit");
        deposits[msg.sender] = balance - amount;
        totalDeposits -= amount;
        require(token.transfer(msg.sender, amount), "Bank: transfer failed");
        emit TokenWithdrawn(msg.sender, amount);
    }

    function recoverTokens(uint256 amount) external onlyOwner {
        uint256 available = token.balanceOf(address(this)) - totalDeposits;
        require(amount <= available, "Bank: no excess tokens");
        require(token.transfer(owner, amount), "Bank: recover failed");
        emit OwnerRecovered(amount);
    }
}
