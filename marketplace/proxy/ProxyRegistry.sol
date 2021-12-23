// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./IProxyRegistry.sol";
import "./OwnedDelegateProxy.sol";

contract ProxyRegistry is IProxyRegistry {
    // Mapping of versions to implementations of different functions
    mapping (string => address) internal versions;

    /**
    * @dev Registers a new version with its implementation address
    * @param version representing the version name of the new implementation to be registered
    * @param implementation representing the address of the new implementation to be registered
    */
    function addVersion(string memory version, address implementation) public {
        require(versions[version] == address(0));
        versions[version] = implementation;
        emit VersionAdded(version, implementation);
    }

    /**
    * @dev Tells the address of the implementation for a given version
    * @param version to query the implementation of
    * @return address of the implementation registered for the given version
    */
    function getVersion(string memory version) public view returns (address) {
        return versions[version];
    }

    /**
    * @dev Creates an upgradeable proxy
    * @return address of the new proxy created
    */
    function createProxy() public payable returns (OwnedDelegateProxy) {
        OwnedDelegateProxy proxy = new OwnedDelegateProxy(msg.sender);
        emit ProxyCreated(address(proxy));
        return proxy;
    }
}