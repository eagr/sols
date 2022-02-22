// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OpenSeaERC721Factory {
    function supportsFactoryInterface() external view returns (bool);

    function numOptions() external view returns (uint256);

    function canMint(uint256 optionId) external view returns (bool);

    function mint(uint256 optionId, address to) external;
}
