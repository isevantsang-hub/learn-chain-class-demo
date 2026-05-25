// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice EIP-777 核心接口子集（教学用，非完整规范拷贝）
interface IERC777 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function granularity() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function send(address recipient, uint256 amount, bytes calldata data) external;
  function operatorSend(address sender, address recipient, uint256 amount, bytes calldata data, bytes calldata operatorData)
    external;
  function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
  function authorizeOperator(address operator) external;
  function revokeOperator(address operator) external;
  function defaultOperators() external view returns (address[] memory);
}

interface IERC777Recipient {
  function tokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
  ) external;
}

interface IERC777Sender {
  function tokensToSend(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes calldata userData,
    bytes calldata operatorData
  ) external;
}
