// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Factory.sol";

abstract contract OpenSeaMultiTokenFactory is OpenSeaERC1155Factory {
    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    function factorySchemaName() public pure returns (string memory) {
        return "ERC1155";
    }
}
