// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev 本地测试用 ERC-1820 注册表子集；主网 canonical 地址为 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24
interface IERC1820RegistryMinimal {
  function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;
  function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);
}

contract ERC1820RegistryMinimal is IERC1820RegistryMinimal {
  mapping(address => mapping(bytes32 => address)) private _implementers;

  function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external override {
    _implementers[account][interfaceHash] = implementer;
  }

  function getInterfaceImplementer(address account, bytes32 interfaceHash) external view override returns (address) {
    return _implementers[account][interfaceHash];
  }
}
