// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ERC165.sol";
import "../interface/ERC1155.sol";
import "../interface/ERC1155MetadataURI.sol";
import "../interface/ERC1155TokenReceiver.sol";
import "../meta/GSNAware.sol";
import "../lib/Address.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-1155
 */
abstract contract MultiToken is ERC165, ERC1155, ERC1155MetadataURI, GSNAware {
    using Address for address;

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _approvals;

    string private _uri;

    constructor(string memory uri_) {
        _setURI(uri_);
    }

    // ============ ERC165 ============

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == type(ERC165).interfaceId
            || interfaceId == type(ERC1155).interfaceId
            || interfaceId == type(ERC1155MetadataURI).interfaceId;
    }

    // ============ ERC1155 ============

    function balanceOf(address account, uint256 tokenType) public view virtual returns (uint256) {
        require(account != address(0), "MultiToken: query balance of null addr");
        return _balances[tokenType][account];
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory tokenTypes
    ) external view returns (uint256[] memory) {
        require(accounts.length == tokenTypes.length, "MultiToken: accounts-tokenTypes length mismatch");

        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            balances[i] = _balances[tokenTypes[i]][accounts[i]];
        }
        return balances;
    }

    function setApprovalForAll(address approvee, bool approved) public virtual {
        address approver = _msgSender();
        require(approver != approvee, "MultiToken: try to approve self");
        _approvals[approver][approvee] = approved;
        emit ApprovalForAll(approver, approvee, approved);
    }

    function isApprovedForAll(address owner, address approvee) public view virtual returns (bool) {
        return _approvals[owner][approvee];
    }

    function _detectOnERC1155Received(
        address operator,
        address from,
        address to,
        uint256 tokenType,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try ERC1155TokenReceiver(to).onERC1155Received(
                operator, from, tokenType, amount, data
            ) returns (bytes4 ret) {
                require(
                    ret == ERC1155TokenReceiver.onERC1155Received.selector,
                    "MultiToken: transfer rejected"
                );
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("MultiToken: transfer to incompatible account");
            }
        }
    }

    function _detectOnERC1155BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory tokenTypes,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try ERC1155TokenReceiver(to).onERC1155BatchReceived(
                operator, from, tokenTypes, amounts, data
            ) returns (bytes4 ret) {
                require(
                    ret == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
                    "MultiToken: transfer rejected"
                );
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("MultiToken: transfer to incompatible account");
            }
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenType,
        uint256 amount,
        bytes memory data
    ) public virtual {
        address operator = _msgSender();

        require(
            from == operator || isApprovedForAll(from, operator),
            "MultiToken: unauthroized transfer"
        );
        require(to != address(0), "MultiToken: transfer to null addr");
        require(balanceOf(from, tokenType) >= amount, "MultiToken: insufficient balance");

        _balances[tokenType][from] -= amount;
        _balances[tokenType][to] += amount;
        emit TransferSingle(operator, from, to, tokenType, amount);

        _detectOnERC1155Received(operator, from, to, tokenType, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenTypes,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        address operator = _msgSender();

        require(
            from == operator || isApprovedForAll(from, operator),
            "MultiToken: unauthroized transfer"
        );
        require(to != address(0), "MultiToken: transfer to nulll addr");
        require(tokenTypes.length == amounts.length, "MultiToken: tokenTypes-amounts length mismatch");

        for (uint256 i = 0; i < tokenTypes.length; i++) {
            uint256 tokenType = tokenTypes[i];
            uint256 amount = amounts[i];

            require(balanceOf(from, tokenType) >= amount, "MultiToken: insufficient balance");

            _balances[tokenType][from] -= amount;
            _balances[tokenType][to] += amount;
        }
        emit TransferBatch(operator, from, to, tokenTypes, amounts);

        _detectOnERC1155BatchReceived(operator, from, to, tokenTypes, amounts, data);
    }

    // ============ ERC1155MetadataURI ============

    function _setURI(string memory uri_) internal virtual {
        _uri = uri_;
    }

    function uri(uint256) public view virtual returns (string memory) {
        return _uri;
    }

    // ============ Minting & Buring ============

    function _safeMint(
        address to,
        uint256 tokenType,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "MultiToken: mint to null addr");

        _balances[tokenType][to] += amount;
        emit TransferSingle(_msgSender(), address(0), to, tokenType, amount);
        _detectOnERC1155Received(_msgSender(), address(0), to, tokenType, amount, data);
    }

    function _safeBatchMint(
        address to,
        uint256[] memory tokenTypes,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "MultiToken: mint to null addr");
        require(tokenTypes.length == amounts.length, "MultiToken: tokenTypes-amounts length mismatch");

        for (uint256 i = 0; i < tokenTypes.length; i++) {
            _balances[tokenTypes[i]][to] += amounts[i];
        }
        emit TransferBatch(_msgSender(), address(0), to, tokenTypes, amounts);
        _detectOnERC1155BatchReceived(_msgSender(), address(0), to, tokenTypes, amounts, data);
    }

    function _burn(
        address from,
        uint256 tokenType,
        uint256 amount
    ) internal virtual {
        address operator = _msgSender();
        require(from != address(0), "MultiToken: burn from null addr");
        require(
            from == operator || isApprovedForAll(from, operator),
            "MultiToken: unauthroized burn"
        );
        require(balanceOf(from, tokenType) >= amount, "MultiToken: burn amount exceeds balance");

        _balances[tokenType][from] -= amount;
        emit TransferSingle(operator, from, address(0), tokenType, amount);
    }

    function _batchBurn(
        address from,
        uint256[] memory tokenTypes,
        uint256[] memory amounts
    ) internal virtual {
        address operator = _msgSender();
        require(from != address(0), "MultiToken: burn from null addr");
        require(
            from == operator || isApprovedForAll(from, operator),
            "MultiToken: unauthroized burn"
        );
        require(tokenTypes.length == amounts.length, "MultiToken: tokenTypes-amounts length mismatch");

        for (uint256 i = 0; i < tokenTypes.length; i++) {
            require(
                balanceOf(from, tokenTypes[i]) >= amounts[i],
                "MultiToken: burn amount exceeds balance"
            );
            _balances[tokenTypes[i]][from] -= amounts[i];
        }
        emit TransferBatch(operator, from, address(0), tokenTypes, amounts);
    }
}