// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../meta/GSNAware.sol";

/**
 * @notice Extension allowing admins to halt transactions in an emergency
 */
abstract contract Pausable is GSNAware {
    event Paused(address byWho);
    event Unpaused(address byWho);

    bool private _paused;

    /**
     * @notice Prefer `isPaused()` over `_paused` for extensibility
     */
    function isPaused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!isPaused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused(), "Pausable: not paused");
        _;
    }

    constructor() {
        _paused = false;
    }

    /**
     * @notice To be called in a permissioned API
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @notice To be called in a permissioned API
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}
