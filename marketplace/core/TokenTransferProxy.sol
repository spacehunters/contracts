// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../bep20/IBEP20.sol";

contract TokenTransferProxy {
    /**
     * Call BEP20 `transferFrom`
     *
     * @dev
     * @param token BEP20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
        public
        returns (bool)
    {
        return IBEP20(token).transferFrom(from, to, amount);
    }
}