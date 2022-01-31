// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ERC165.sol";
import "../interface/ERC721.sol";
import "../interface/ERC721Metadata.sol";
import "../interface/ERC721TokenReceiver.sol";
import "../lib/Address.sol";
import "../lib/Uint.sol";

/**
 * @notice minimal NFT contract served as the foundation to build upon
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract NFT is ERC165, ERC721, ERC721Metadata {
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _ownerOf;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;

    string private _name;
    string private _symbol;
    string private _baseURI;

    constructor(string memory name_, string memory symbol_, string memory baseURI_) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
    }

    // ============ ERC165 ============

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(ERC165).interfaceId
            || interfaceId == type(ERC721).interfaceId
            || interfaceId == type(ERC721Metadata).interfaceId;
    }

    // ============ ERC721 ============

    function balanceOf(address account) public view virtual returns (uint256) {
        require(account != address(0), "NFT: query balance for 0 addr");
        return _balanceOf[account];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "NFT: query owner for nonexistent token");
        return owner;
    }

    function setApprovalForAll(address approvee, bool approved) public virtual {
        require(approvee != address(0), "NFT: approve 0 addr");
        require(approvee != msg.sender, "NFT: approve self");
        _operatorApprovals[msg.sender][approvee] = approved;
        emit ApprovalForAll(msg.sender, approvee, approved);
    }

    function isApprovedForAll(address owner, address approvee) public view virtual returns (bool) {
        return _operatorApprovals[owner][approvee];
    }

    /// @dev zero address is allowed as `approvee` for burning
    function approve(address approvee, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        require(approvee != owner, "NFT: approve owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "NFT: unauthroized approval"
        );

        _tokenApprovals[tokenId] = approvee;
        emit Approval(owner, approvee, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        require(ownerOf(tokenId) != address(0), "NFT: query approvee for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function _isOwnerOrApprovee(address account, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ownerOf(tokenId);
        return account == owner || isApprovedForAll(owner, account) || account == getApproved(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(from == ownerOf(tokenId), "NFT: transfer from wrong account");
        require(from != to, "NFT: transfer to self");
        require(to != address(0), "NFT: transfer to 0 addr");
        require(_isOwnerOrApprovee(msg.sender, tokenId), "NFT: unauthroized transfer");

        _ownerOf[tokenId] = to;
        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;

        _tokenApprovals[tokenId] = address(0);
        emit Approval(to, address(0), tokenId);
        emit Transfer(from, to, tokenId);
    }

    function _detectOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 ret) {
            require(
                ret == type(ERC721TokenReceiver).interfaceId,
                "NFT: transfer to non-ERC721TokenReceiver addr"
            );
        } catch (bytes memory err) {
            if (err.length == 0) {
                revert("NFT: transfer to non-ERC721TokenReceiver addr");
            } else {
                assembly {
                    revert(add(0x20, err), mload(err))
                }
            }
        }
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, tokenId);
        if (Address.isContract(to)) _detectOnERC721Received(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    // ============ ERC721Metadata ============

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(ownerOf(tokenId) != address(0), "NFT: query URI for nonexistent token");
        if (bytes(_baseURI).length == 0) return "";
        return string(abi.encodePacked(_baseURI, Uint.toString(tokenId)));
    }

    // ============ Minting ============

    function mint(address to, uint256 tokenId) public virtual {
        require(to != address(0), "NFT: mint to 0 addr");
        require(ownerOf(tokenId) == address(0), "NFT: mint existing token");

        _balanceOf[to] += 1;
        _ownerOf[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function safeMint(address to, uint256 tokenId, bytes memory data) public virtual {
        mint(to, tokenId);
        if (Address.isContract(to)) _detectOnERC721Received(address(0), to, tokenId, data);
    }

    function safeMint(address to, uint256 tokenId) public virtual {
        safeMint(to, tokenId, "");
    }
}
