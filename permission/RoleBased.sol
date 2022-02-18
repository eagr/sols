// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/Roleable.sol";
import "../meta/Queryable.sol";
import "../meta/GSNAware.sol";
import "../lib/Uint.sol";

abstract contract RoleBased is Roleable, Queryable, GSNAware {
    using Uint for uint256;

    struct Role {
        bytes32 admin;
        mapping(address => bool) members;
    }

    mapping(bytes32 => Role) private _roleData;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function _checkRole(bytes32 role, address account) internal view virtual {
        require(hasRole(role, account), "RoleBased: unauthorized account");
    }

    function _setRoleAdmin(bytes32 role, bytes32 admin) internal virtual {
        bytes32 prevAdmin = getRoleAdmin(role);
        _roleData[role].admin = admin;
        emit RoleAdminChanged(role, prevAdmin, admin);
    }

    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roleData[role].members[account];
    }

    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roleData[role].admin;
    }

    function _grant(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roleData[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revoke(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roleData[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function grantRole(
        bytes32 role,
        address account
    ) public virtual onlyRole(getRoleAdmin(role)) {
        _grant(role, account);
    }

    function revokeRole(
        bytes32 role,
        address account
    ) public virtual onlyRole(getRoleAdmin(role)) {
        _revoke(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "RoleBased: renounce role for another account");
        _revoke(role, account);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(Roleable).interfaceId
            || super.supportsInterface(interfaceId);
    }
}
