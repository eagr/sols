// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReentrancyGuard {
    uint256 private constant _UNLOCKED = 1;
    uint256 private constant _LOCKED = 2;
    uint256 private _state;

    constructor() {
        _state = _UNLOCKED;
    }

    modifier guarded() {
        require(_state != _LOCKED, "ReentrancyGuard: reentrant call");

        _state = _LOCKED;
        _;
        _state = _UNLOCKED;
    }
}
