// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See https://eips.ethereum.org/EIPS/eip-165
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
