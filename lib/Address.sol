// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Address {
    function isContract(address addr) public view returns (bool) {
        return addr.code.length > 0;
    }
}
