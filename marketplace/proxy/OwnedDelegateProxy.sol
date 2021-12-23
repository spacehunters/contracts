// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./IProxyRegistry.sol";
import "./OwnedUpgradeabilityProxy.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract represents a proxy where the implementation address to which it will delegate can be upgraded
 */
contract OwnedDelegateProxy is OwnedUpgradeabilityProxy {

  /**
  * @dev Constructor function
  */
  constructor(address owner) {
    setUpgradeabilityOwner(owner);
    registry = IProxyRegistry(msg.sender);
  }
}