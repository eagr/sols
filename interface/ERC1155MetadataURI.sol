// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Note: The ERC-165 identifier for this interface is 0x0e89341c.
interface ERC1155MetadataURI {
    function uri(uint256 id) external view returns (string memory);
}
