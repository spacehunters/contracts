// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../eip721/IERC721Upgradeable.sol";

contract NFTsTransferProxy {
    /**
     * Call ERC721Upgrdeable `transferFrom`
     *
     * @dev
     * @param nftAddress NFT Address
     * @param from From address
     * @param to To address
     * @param tokenId Transfer amount
     */
    function transferFrom(address nftAddress, address from, address to, uint tokenId)
        public
    {
        IERC721Upgradeable(nftAddress).transferFrom(from, to, tokenId);
    }
}