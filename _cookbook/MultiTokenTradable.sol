// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/MultiTokenSupply.sol";
import "../permission/RoleBased.sol";
import "../security/Pausable.sol";
import "../opensea/Interoperable.sol";
import "../lib/Uint.sol";

/**
 * @notice Cutromized ERC-1155 contract made compatible specifically to OpenSea
 *  Fungible token id starts from 0, while non-fungible starts from 1000000.
 */
abstract contract MultiTokenTradable is MultiTokenSupply, RoleBased, Pausable, OpenSeaInteroperable {
    using Uint for uint256;

    bytes32 public constant GOD = keccak256("ROLE_GOD");
    bytes32 public constant CREATOR = keccak256("ROLE_CREATOR");
    bytes32 public constant MINTER = keccak256("ROLE_MINTER");

    string private _name;

    uint256 private _currentFungibleId = 0;
    uint256 private _currentNonFungibleId = 1000000;

    constructor(
        string memory name_,
        string memory contractURI_,
        string memory metadataURI,
        address proxyRegistry_
    ) MultiToken(metadataURI) {
        _setName(name_);
        _setContractURI(contractURI_);
        _setProxyRegistry(proxyRegistry_);

        address sender = _msgSender();
        _grantRole(GOD, sender);
        _grantRole(CREATOR, sender);
        _grantRole(MINTER, sender);
        _setRoleAdmin(GOD, GOD);
        _setRoleAdmin(CREATOR, GOD);
        _setRoleAdmin(MINTER, GOD);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(RoleBased, MultiToken) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function isApprovedForAll(
        address owner,
        address approvee
    ) public view virtual override returns (bool) {
        return _isOpenSeaProxy(owner, approvee)
            || super.isApprovedForAll(owner, approvee);
    }

    // ============ metadata ============

    function setMetadataURI(string memory uri_) public virtual onlyRole(GOD) {
        _setURI(uri_);
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(super.uri(), tokenId.toString()));
    }

    // ============ create & mint ============

    function _create(
        address initOwner,
        uint256 tokenId,
        uint256 initSupply,
        bytes memory data
    ) internal virtual returns (uint256) {
        _safeMint(initOwner, tokenId, initSupply, data);
        _createToken(initOwner, tokenId);
        emit URI(uri(tokenId), tokenId);
        return tokenId;
    }

    function createFungible(
        uint256 initSupply,
        bytes memory data
    ) public virtual onlyRole(CREATOR) returns (uint256) {
        return _create(_msgSender(), _currentFungibleId++, initSupply, data);
    }

    function createNonFungible(
        address initOwner,
        bytes memory data
    ) public virtual onlyRole(CREATOR) returns (uint256) {
        return _create(initOwner, _currentNonFungibleId++, 1, data);
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual onlyRole(MINTER) {
        require(exists(tokenId), "MultiTokenTradable#mint: nonexistent token");
        _safeMint(to, tokenId, amount, data);
    }

    function batchMint(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual onlyRole(MINTER) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(exists(tokenIds[i]), "MultiTokenTradable#mint: nonexistent token");
        }
        _safeBatchMint(to, tokenIds, amounts, data);
    }

    // ============ emergency ============

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);
    }

    function pause() public virtual onlyRole(GOD) {
        _pause();
    }

    function unpause() public virtual onlyRole(GOD) {
        _unpause();
    }
}
