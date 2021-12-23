// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    function _fallback() internal {
        address _impl = implementation();
        require(_impl != address(0), "Implementation is invalid");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    /**
     * @dev Receive function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    receive() external payable {
        _fallback();
    }

    /**
     * @dev Receive function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        _fallback();
    }
}
