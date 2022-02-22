// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OpenSeaERC1155Factory {
    function supportsFactoryInterface() external view returns (bool);

    function factorySchemaName() external view returns (string memory);

    function numOptions() external view returns (uint256);

    function canMint(uint256 optionId, uint256 amount) external view returns (bool);

    function mint(uint256 optionId, address to, uint256 amount, bytes calldata data) external;
}
