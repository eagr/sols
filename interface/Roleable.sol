// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev See https://docs.openzeppelin.com/contracts/4.x/api/access#IAccessControl
interface Roleable {
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousRoleAdmin, bytes32 indexed newRoleAdmin);

    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}
