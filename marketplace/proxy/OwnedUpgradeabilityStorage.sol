// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IProxyRegistry.sol";

contract OwnedUpgradeabilityStorage {
    // Current implementation
    address internal _implementation;

    // Owner of the contract
    address private _upgradeabilityOwner;

    // Versions registry
    IProxyRegistry internal registry;

    function proxyRegistry() public view returns (address) {
        return address(registry);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }
}
