// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ERC165.sol";
import "../interface/ERC721.sol";
import "../interface/ERC721Metadata.sol";
import "../interface/ERC721TokenReceiver.sol";
import "../lib/Address.sol";

abstract contract NFT is ERC165, ERC721, ERC721Metadata {
    mapping(address => uint256) private _balanceOf;
    mapping(uint256 => address) private _ownerOf;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    // ============ ERC165 ============

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(ERC165).interfaceId
            || interfaceId == type(ERC721).interfaceId
            || interfaceId == type(ERC721Metadata).interfaceId;
    }

    // ============ ERC721 ============

    function balanceOf(address account) public view virtual returns (uint256) {
        require(account != address(0), "Queried balance for zero address");
        return _balanceOf[account];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _ownerOf[tokenId];
        require(owner != address(0), "Queried owner for nonexistent token");
        return owner;
    }

    function setApprovalForAll(address approvee, bool approved) public virtual {
        require(approvee != address(0), "Attempted to approve zero address");
        require(approvee != msg.sender, "Attempted to approve self");
        _operatorApprovals[msg.sender][approvee] = approved;
        emit ApprovalForAll(msg.sender, approvee, approved);
    }

    function isApprovedForAll(address owner, address approvee) public view virtual returns (bool) {
        return _operatorApprovals[owner][approvee];
    }

    function approve(address approvee, uint256 tokenId) public virtual {
        require(approvee != address(0), "Attempted to approve zero address");

        address owner = ownerOf(tokenId);
        require(approvee != owner, "Attempted to approve current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Approval from unauthroized caller"
        );

        _tokenApprovals[tokenId] = approvee;
        emit Approval(owner, approvee, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        require(ownerOf(tokenId) != address(0), "Queried approvee for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function _isOwnerOrApprovee(address account, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return account == owner || isApprovedForAll(owner, account) || account == getApproved(tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(from == ownerOf(tokenId), "Attempted to transfer token from the wrong account");
        require(to != address(0), "Attempted to transfer to zero address");

        _ownerOf[tokenId] = to;
        _balanceOf[from] -= 1;
        _balanceOf[to] += 1;
        _tokenApprovals[tokenId] = address(0);

        emit Transfer(from, to, tokenId);
    }

    function _detectOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private {
        try ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 ret) {
            require(
                ret == type(ERC721TokenReceiver).interfaceId,
                "Attempted to transfer to non-ERC721TokenReceiver address"
            );
        } catch (bytes memory err) {
            if (err.length == 0) {
                revert("Attempted to transfer to non-ERC721TokenReceiver address");
            } else {
                assembly {
                    revert(add(0x20, err), mload(err))
                }
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        require(_isOwnerOrApprovee(msg.sender, tokenId), "Transfer initiated by unauthroized account");
        _transfer(from, to, tokenId);
        if (Address.isContract(to)) _detectOnERC721Received(from, to, tokenId, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        require(_isOwnerOrApprovee(msg.sender, tokenId), "Transfer initiated by unauthroized account");
        _transfer(from, to, tokenId);
    }

    // ============ ERC721Metadata ============

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Queried URI for nonexistent token");
        return "";
    }
}
