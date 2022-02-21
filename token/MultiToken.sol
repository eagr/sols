// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ERC1155.sol";
import "../interface/ERC1155MetadataURI.sol";
import "../interface/ERC1155TokenReceiver.sol";
import "../meta/Queryable.sol";
import "../meta/GSNAware.sol";
import "../lib/Address.sol";

/**
 * @notice Implementation of ERC-1155
 */
abstract contract MultiToken is ERC1155, ERC1155MetadataURI, Queryable, GSNAware {
    using Address for address;

    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _approvals;

    string private _uri;

    constructor(string memory uri_) {
        _setURI(uri_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ERC1155).interfaceId
            || interfaceId == type(ERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    // ============ ERC1155 ============

    function balanceOf(address account, uint256 tokenId) public view virtual returns (uint256) {
        require(account != address(0), "MultiToken: query balance of null addr");
        return _balances[tokenId][account];
    }

    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory tokenIds
    ) external view returns (uint256[] memory) {
        require(accounts.length == tokenIds.length, "MultiToken: accounts-tokenIds length mismatch");

        uint256[] memory balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            balances[i] = _balances[tokenIds[i]][accounts[i]];
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

    function _toArray(uint256 elem) private pure returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](1);
        arr[0] = elem;
        return arr;
    }

    /**
     * @dev A hook to make writing transaction-related extensions easier
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual { }

    function _detectOnERC1155Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try ERC1155TokenReceiver(to).onERC1155Received(
                operator, from, tokenId, amount, data
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
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try ERC1155TokenReceiver(to).onERC1155BatchReceived(
                operator, from, tokenIds, amounts, data
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

    function _safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "MultiToken: transfer to null addr");
        require(balanceOf(from, tokenId) >= amount, "MultiToken: insufficient balance");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _toArray(tokenId), _toArray(amount), data);
        _balances[tokenId][from] -= amount;
        _balances[tokenId][to] += amount;
        emit TransferSingle(operator, from, to, tokenId, amount);
        _detectOnERC1155Received(operator, from, to, tokenId, amount, data);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "MultiToken: unauthroized transfer"
        );
        _safeTransferFrom(from, to, tokenId, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(to != address(0), "MultiToken: transfer to nulll addr");
        require(tokenIds.length == amounts.length, "MultiToken: tokenIds-amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, tokenIds, amounts, data);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 amount = amounts[i];

            require(balanceOf(from, tokenId) >= amount, "MultiToken: insufficient balance");

            _balances[tokenId][from] -= amount;
            _balances[tokenId][to] += amount;
        }
        emit TransferBatch(operator, from, to, tokenIds, amounts);
        _detectOnERC1155BatchReceived(operator, from, to, tokenIds, amounts, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "MultiToken: unauthroized transfer"
        );
        _safeBatchTransferFrom(from, to, tokenIds, amounts, data);
    }

    // ============ ERC1155MetadataURI ============

    function _setURI(string memory uri_) internal virtual {
        _uri = uri_;
    }

    function uri() public view virtual returns (string memory) {
        return _uri;
    }

    // ============ Minting & Buring ============

    function _safeMint(
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "MultiToken: mint to null addr");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _toArray(tokenId), _toArray(amount), data);
        _balances[tokenId][to] += amount;
        emit TransferSingle(operator, address(0), to, tokenId, amount);
        _detectOnERC1155Received(operator, address(0), to, tokenId, amount, data);
    }

    function _safeBatchMint(
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "MultiToken: mint to null addr");
        require(tokenIds.length == amounts.length, "MultiToken: tokenIds-amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, tokenIds, amounts, data);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _balances[tokenIds[i]][to] += amounts[i];
        }
        emit TransferBatch(operator, address(0), to, tokenIds, amounts);
        _detectOnERC1155BatchReceived(operator, address(0), to, tokenIds, amounts, data);
    }

    function _burn(
        address from,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "MultiToken: burn from null addr");
        require(balanceOf(from, tokenId) >= amount, "MultiToken: burn amount exceeds balance");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _toArray(tokenId), _toArray(amount), "");
        _balances[tokenId][from] -= amount;
        emit TransferSingle(operator, from, address(0), tokenId, amount);
    }

    function _batchBurn(
        address from,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "MultiToken: burn from null addr");
        require(tokenIds.length == amounts.length, "MultiToken: tokenIds-amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), tokenIds, amounts, "");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                balanceOf(from, tokenIds[i]) >= amounts[i],
                "MultiToken: burn amount exceeds balance"
            );
            _balances[tokenIds[i]][from] -= amounts[i];
        }
        emit TransferBatch(operator, from, address(0), tokenIds, amounts);
    }
}
