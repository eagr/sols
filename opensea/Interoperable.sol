// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// HACK for RPC typing
contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @notice Baseline OpenSea interop
 * @dev Every OpenSea user has a "proxy account" of their own through which
 *  OpenSea makes transactions on their behalf. OperSea also provides a registry
 *  for proxy lookup.
 *
 *  https://docs.opensea.io/docs/1-structuring-your-smart-contract#opensea-whitelisting-optional
 *  https://docs.opensea.io/docs/contract-level-metadata
 */
abstract contract OpenSeaInteroperable {
    string public name;
    string public symbol;
    string public contractURI;
    address private _proxyRegistry;

    mapping(uint256 => address) public creators;

    // ============ metadata ============

    function _setName(string memory name_) internal {
        if (bytes(name_).length > 0) name = name_;
    }

    function _setSymbol(string memory symbol_) internal {
        if (bytes(symbol_).length > 0) symbol = symbol_;
    }

    function _setContractURI(string memory uri) internal {
        if (bytes(uri).length > 0) contractURI = uri;
    }

    // ============ proxy contract ============

    function _setProxyRegistry(address registryAddr) internal {
        if (registryAddr != address(0)) _proxyRegistry = registryAddr;
    }

    function _isOpenSeaProxy(address owner, address operator) internal view returns (bool) {
        if (_proxyRegistry == address(0)) return false;

        // https://docs.opensea.io/docs/polygon-basic-integration
        if (block.chainid == 137 || block.chainid == 80001) {
            return operator == _proxyRegistry;
        } else {
            return operator == address(ProxyRegistry(_proxyRegistry).proxies(owner));
        }
    }

    // ============ creator ============

    function _createToken(address initOwner, uint256 tokenId) internal virtual {
        creators[tokenId] = initOwner;
    }
}
