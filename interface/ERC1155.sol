// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface ERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 amount);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] amounts);

    event ApprovalForAll(address indexed owner, address indexed approvee, bool approved);

    event URI(string url, uint256 indexed id);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    function setApprovalForAll(address approvee, bool approved) external;

    function isApprovedForAll(address owner, address approvee) external view returns (bool);
}