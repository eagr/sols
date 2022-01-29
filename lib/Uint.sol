// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Uint {
    function toString(uint256 i) public pure returns (string memory) {
        if (i == 0) return "0";

        uint256 tmp = i;
        uint256 len = 0;
        while (tmp > 0) {
            ++len;
            tmp /= 10;
        }

        bytes memory buf = new bytes(len);
        while (i > 0) {
            buf[--len] = bytes1(uint8(0x30 + i % 10));
            i /= 10;
        }
        return string(buf);
    }
}
