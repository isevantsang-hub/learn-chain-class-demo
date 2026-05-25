// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC777, IERC777Recipient, IERC777Sender} from "./IERC777.sol";
import {IERC1820RegistryMinimal} from "./IERC1820RegistryMinimal.sol";

/// @title DemoERC777 — EIP-777 精简教学实现
/// @dev 生产环境不推荐新上 777；本合约仅演示 send / operator / hooks。
contract DemoERC777 is IERC777 {
  IERC1820RegistryMinimal private immutable ERC1820;

  bytes32 private constant TOKENS_RECIPIENT_INTERFACE_HASH =
    keccak256("ERC777TokensRecipient");
  bytes32 private constant TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");

  string private _name;
  string private _symbol;
  uint256 private _granularity;
  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => bool)) private _operators;
  mapping(address => bool) private _defaultOperator;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupply,
    address[] memory defaultOps,
    address erc1820Registry
  ) {
    ERC1820 = IERC1820RegistryMinimal(
      erc1820Registry == address(0) ? 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24 : erc1820Registry
    );
    _name = name_;
    _symbol = symbol_;
    _granularity = 1;
    for (uint256 i = 0; i < defaultOps.length; i++) {
      _defaultOperator[defaultOps[i]] = true;
    }
    _mint(msg.sender, initialSupply, "", "");
  }

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function granularity() external view returns (uint256) {
    return _granularity;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function defaultOperators() external pure returns (address[] memory) {
    return new address[](0);
  }

  function isOperatorFor(address operator, address tokenHolder) public view returns (bool) {
    return _operators[operator][tokenHolder] || _defaultOperator[operator];
  }

  function authorizeOperator(address operator) external {
    _operators[operator][msg.sender] = true;
  }

  function revokeOperator(address operator) external {
    _operators[operator][msg.sender] = false;
  }

  function send(address recipient, uint256 amount, bytes calldata data) external {
    _send(msg.sender, msg.sender, recipient, amount, data, "", true);
  }

  function operatorSend(
    address sender,
    address recipient,
    uint256 amount,
    bytes calldata data,
    bytes calldata operatorData
  ) external {
    require(isOperatorFor(msg.sender, sender), "not operator");
    _send(msg.sender, sender, recipient, amount, data, operatorData, false);
  }

  function _send(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData,
    bool requireRecipient
  ) internal {
    require(to != address(0), "zero to");
    _balances[from] -= amount;
    _callTokensToSend(operator, from, to, amount, userData, operatorData);
    _balances[to] += amount;
    _callTokensReceived(operator, from, to, amount, userData, operatorData, requireRecipient);
    emit Sent(operator, from, to, amount, userData, operatorData);
  }

  function _mint(address account, uint256 amount, bytes memory userData, bytes memory operatorData) internal {
    _totalSupply += amount;
    _balances[account] += amount;
    emit Minted(msg.sender, account, amount, userData, operatorData);
  }

  function _callTokensToSend(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) internal {
    address implementer = ERC1820.getInterfaceImplementer(from, TOKENS_SENDER_INTERFACE_HASH);
    if (implementer != address(0)) {
      IERC777Sender(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
    }
  }

  function _callTokensReceived(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData,
    bool requireRecipient
  ) internal {
    address implementer = ERC1820.getInterfaceImplementer(to, TOKENS_RECIPIENT_INTERFACE_HASH);
    if (implementer != address(0)) {
      IERC777Recipient(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
    } else if (requireRecipient) {
      require(to.code.length == 0, "must implement ERC777TokensRecipient");
    }
  }

  event Sent(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 amount,
    bytes data,
    bytes operatorData
  );
  event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
}
