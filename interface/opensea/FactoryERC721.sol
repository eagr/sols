// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OpenSeaFactoryERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function numOptions() external view returns (uint256);

    function tokenURI(uint256 optionId) external view returns (string memory);

    function supportsFactoryInterface() external view returns (bool);

    function canMint(uint256 optionId) external view returns (bool);

    function mint(uint256 optionId, address to) external;
}
