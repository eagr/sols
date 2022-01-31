// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";
import "../interface/ERC721Enumerable.sol";

abstract contract NFTEnumerable is NFT, ERC721Enumerable {
    mapping(uint256 => uint256) private _tokenIndices;
    uint256[] private _tokens;

    mapping(uint256 => uint256) private _tokenIndicesOfOwner;
    mapping(address => uint256[]) private _tokensOfOwner;

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(ERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function mint(address to, uint256 tokenId) public virtual override {
        super.mint(to, tokenId);

        _tokenIndices[tokenId] = _tokens.length;
        _tokens.push(tokenId);

        _tokenIndicesOfOwner[tokenId] = _tokensOfOwner[to].length;
        _tokensOfOwner[to].push(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721, NFT) {
        super.transferFrom(from, to, tokenId);

        uint256[] storage tokens = _tokensOfOwner[from];
        tokens[_tokenIndicesOfOwner[tokenId]] = tokens[tokens.length - 1];
        tokens.pop();

        _tokenIndicesOfOwner[tokenId] = _tokensOfOwner[to].length;
        _tokensOfOwner[to].push(tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        _tokens[_tokenIndices[tokenId]] = _tokens[_tokens.length - 1];
        _tokens.pop();
        delete _tokenIndices[tokenId];

        uint256[] storage tokens = _tokensOfOwner[ownerOf(tokenId)];
        tokens[_tokenIndicesOfOwner[tokenId]] = tokens[tokens.length - 1];
        tokens.pop();
        delete _tokenIndicesOfOwner[tokenId];
    }

    function totalSupply() public view virtual returns (uint256) {
        return _tokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply(), "NFTEnumerable: index out of range");
        return _tokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < _tokensOfOwner[owner].length, "NFTEnumerable: index out of range");
        return _tokensOfOwner[owner][index];
    }
}
