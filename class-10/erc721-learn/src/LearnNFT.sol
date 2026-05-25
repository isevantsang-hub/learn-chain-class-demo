// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin-contracts-5.6.0/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin-contracts-5.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin-contracts-5.6.0/access/Ownable.sol";

/// @title LearnNFT — 教学用 ERC-721（每枚 token 独立 metadata URI，仅 owner 可 mint）
contract LearnNFT is ERC721, ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;

    constructor(address initialOwner) ERC721("Learn Chain Class NFT", "LCDNFT") Ownable(initialOwner) {}

    function totalMinted() external view returns (uint256) {
        return _nextTokenId;
    }

    function mint(address to, string memory uri) public onlyOwner returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
