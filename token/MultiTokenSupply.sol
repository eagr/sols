// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiToken.sol";

abstract contract MultiTokenSupply is MultiToken {
    mapping(uint256 => uint256) private _totalSupplies;

    function totalSupply(uint256 tokenId) public view virtual returns (uint256) {
        return _totalSupplies[tokenId];
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return MultiTokenSupply.totalSupply(tokenId) > 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                _totalSupplies[tokenIds[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < tokenIds.length; ++i) {
                uint256 supply = _totalSupplies[tokenIds[i]];
                require(supply >= amounts[i], "MultiTokenSupply: burn amount exceeds totalSupply");
                _totalSupplies[tokenIds[i]] = supply - amounts[i];
            }
        }
    }
}
