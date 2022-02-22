// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OpenSeaFactoryERC1155 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function numOptions() external view returns (uint256);

    function uri(uint256 optionId) external view returns (string memory);

    function factorySchemaName() external view returns (string memory);

    function supportsFactoryInterface() external view returns (bool);

    function canMint(uint256 optionId, uint256 amount) external view returns (bool);

    function mint(uint256 optionId, address to, uint256 amount, bytes calldata data) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 optionId, uint256 amount, bytes calldata data) external;

    function balanceOf(address account, uint256 optionId) external view returns (uint256);
}
