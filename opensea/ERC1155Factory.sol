// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract OpenSeaERC1155Factory {
    function supportsFactoryInterface() public pure returns (bool) {
        return true;
    }

    function factorySchemaName() public pure returns (string memory) {
        return "ERC1155";
    }

    function numOptions() external view virtual returns (uint256);

    function canMint(uint256 optionId, uint256 amount) external view virtual returns (bool);

    function mint(uint256 optionId, address to, uint256 amount, bytes calldata data) external virtual;

    // function uri(uint256 _optionId) external view virtual returns (string memory);

    // function balanceOf(address _owner, uint256 _optionId) external view virtual returns (uint256);
}
