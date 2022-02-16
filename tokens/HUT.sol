// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./Token.sol";

contract HUT is TokenBase {
    constructor(
        address[] memory proposers,
        address[] memory executors,
        uint256 minDelay,
        uint256 totalVestingType
    ) TokenBase(proposers, executors, minDelay, totalVestingType, "HUT", "HUT") {}
}