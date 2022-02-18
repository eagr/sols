// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../token/MultiToken.sol";
import "../permission/RoleBased.sol";
import "../lib/Uint.sol";

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @notice Opnionated ERC-1155 contract made compatible specifically to OpenSea
 *  Fungible token id starts from 0, while non-fungible starts from 1000000.
 */
abstract contract MultiTokenTradable is MultiToken, RoleBased {
    using Uint for uint256;

    bytes32 public constant GOD = keccak256("ROLE_GOD");
    bytes32 public constant CREATOR = keccak256("ROLE_CREATOR");
    bytes32 public constant MINTER = keccak256("ROLE_MINTER");

    string private _name;
    address proxyRegistryAddress;

    // reserve the first 1M for fungible token ids
    uint256 private _currentFungibleId = 0;
    uint256 private _currentNonFungibleId = 1000000;

    mapping(uint256 => address) private _creators;
    mapping(uint256 => uint256) private _supplies;

    constructor(
        string memory name_,
        string memory metadataURI,
        address proxyRegistryAddress_
    ) MultiToken(metadataURI) {
        _name = name_;
        proxyRegistryAddress = proxyRegistryAddress_;

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
        // Whitelist OpenSea proxy contract for easy trading
        ProxyRegistry registry = ProxyRegistry(proxyRegistryAddress);
        if (approvee == address(registry.proxies(owner))) {
            return true;
        }
        return super.isApprovedForAll(owner, approvee);
    }

    // ============ metadata ============

    function name() public view returns (string memory) {
        return _name;
    }

    function totalSupply(uint256 tokenId) public view virtual returns (uint256) {
        return _supplies[tokenId];
    }

    function exists(uint256 tokenId) public view virtual returns (bool) {
        return MultiTokenTradable.totalSupply(tokenId) > 0;
    }

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
    ) public virtual returns (uint256) {
        _safeMint(initOwner, tokenId, initSupply, data);
        _creators[tokenId] = initOwner;
        _supplies[tokenId] = initSupply;

        emit URI(uri(tokenId), tokenId);
        return tokenId;
    }

    function createFungible(
        uint256 initSupply,
        bytes memory data
    ) public virtual onlyRole(CREATOR) {
        _create(_msgSender(), _currentFungibleId++, initSupply, data);
    }

    function createNonFungible(
        address initOwner,
        bytes memory data
    ) public virtual onlyRole(CREATOR) {
        _create(initOwner, _currentNonFungibleId++, 1, data);
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual onlyRole(MINTER) {
        require(exists(tokenId), "MultiTokenTradable#mint: nonexistent token");
        _safeMint(to, tokenId, amount, data);
        _supplies[tokenId] += amount;
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
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _supplies[tokenIds[i]] += amounts[i];
        }
    }
}
