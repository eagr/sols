// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library QueryInterface {
    bytes4 constant ERC165_ID = 0x01ffc9a7;
    bytes4 constant INVALID_ID = 0xffffffff;

    function _supportsInterface(
        address addr,
        bytes4 id
    ) private view returns (uint256 success, uint256 result) {
        assembly {
            let offset := mload(0x40)
            mstore(offset, ERC165_ID)       // function selector
            mstore(add(offset, 0x04), id)   // argument
            success := staticcall(30000, addr, offset, 0x24, offset, 0x20)
            result := mload(offset)
        }
    }

    function supportsERC165(address addr) public view returns (bool) {
        uint256 suc;
        uint256 res;

        (suc, res) = _supportsInterface(addr, ERC165_ID);
        if (suc == 0 || res == 0) return false;

        (suc, res) = _supportsInterface(addr, INVALID_ID);
        return suc == 1 && res == 0;
    }

    function batch(
        address addr,
        bytes4[] memory interfaceIds
    ) public view returns (bool[] memory) {
        bool[] memory supported = new bool[](interfaceIds.length);
        for (uint32 i = 0; i < interfaceIds.length; i++) {
            (, bytes memory res) = addr.staticcall{gas: 30000}(
                abi.encodeWithSelector(ERC165_ID, interfaceIds[i])
            );
            supported[i] = res.length == 0x20 && abi.decode(res, (bool));
        }
        return supported;
    }
}
