// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract OpenSeaERC721Factory {
    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    function factorySchemaName() public pure returns (string memory) {
        return "ERC721";
    }

    function numOptions() external view virtual returns (uint256);

    function canMint(uint256 optionId) external view virtual returns (bool);

    function mint(uint256 optionId, address to) external virtual;

    // function tokenURI(uint256 _optionId) external view virtual returns (string memory);
}
