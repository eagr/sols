// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";
import "../interface/ERC2981.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-2981
 */
abstract contract NFTRoyalty is NFT, ERC2981 {
    struct RoyaltyInfo {
        address receiver;
        uint8 percentage;
    }

    uint8 private _maxPercentage = 10;

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _royaltyOf;

    function _setMaxPercentage(uint8 max) internal virtual {
        require(max <= 100, "NFTRoyalty: set max royalty fee to over 100%");
        _maxPercentage = max;
    }

    function _setDefault(address receiver, uint8 percentage) internal virtual {
        require(receiver != address(0), "NFTRoyalty: set default receiver to null addr");
        require(percentage <= _maxPercentage, "NFTRoyalty: default royalty fee exceeds maximum");
        _defaultRoyaltyInfo = RoyaltyInfo(receiver, percentage);
    }

    function _clearDeault() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    function _setRoyaltyOf(
        uint256 tokenId,
        address receiver,
        uint8 percentage
    ) internal virtual {
        require(receiver != address(0), "NFTRoyalty: set receiver to null addr");
        require(percentage <= _maxPercentage, "NFTRoyalty: royalty fee exceeds maximum");
        _royaltyOf[tokenId] = RoyaltyInfo(receiver, percentage);
    }

    function _clearRoyaltyOf(uint256 tokenId) internal virtual {
        delete _royaltyOf[tokenId];
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        RoyaltyInfo memory royalty = _royaltyOf[tokenId];

        // royalty was not set for token
        if (royalty.receiver == address(0)) royalty = _defaultRoyaltyInfo;

        return (
            royalty.receiver,
            salePrice * royalty.percentage / 100
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, NFT) returns (bool) {
        return interfaceId == type(ERC2981).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
