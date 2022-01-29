// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approvee, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed approvee, bool approved);

    function balanceOf(address account) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address approvee, bool approved) external;

    function isApprovedForAll(address owner, address approvee) external view returns (bool);

    function approve(address approvee, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;
}
