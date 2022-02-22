// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Factory.sol";

abstract contract OpenSeaMultiTokenFactory is OpenSeaERC721Factory {
    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    function factorySchemaName() public pure returns (string memory) {
        return "ERC721";
    }
}
