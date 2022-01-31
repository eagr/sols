// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";

abstract contract NFTBurnable is NFT {
    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }
}
