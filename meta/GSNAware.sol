// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev
 *  https://docs.polygon.technology/docs/develop/metatransactions/metatransactions-gsn/#recipient-contract
 *  https://docs.opensea.io/docs/polygon-basic-integration
 */
abstract contract GSNAware {
    function _msgSender() internal view virtual returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory payload = msg.data;
            uint256 len = msg.data.length;
            assembly {
                // load 32 bytes right after payload, and mask lower 20 byes
                let afterPayload := add(payload, len)
                sender := and(
                    mload(afterPayload),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}
