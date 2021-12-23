// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "./core/MarketPlaceCore.sol";
import "./proxy/ProxyRegistry.sol";
import "./core/TokenTransferProxy.sol";
import "./core/NFTsTransferProxy.sol";

contract AngelCreedMarketPlace is MarketPlaceCore {

    function initialize(
        address _tokenTransferProxy,
        address _nftTransferProxy,
        address _feeRecipient,
        uint256 _sellerFee,
        uint256 _buyerFee,
        uint256 _minimumPrice

    ) public payable initializer {
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        tokenTransferProxy = TokenTransferProxy(_tokenTransferProxy);
        nftsTransferProxy = NFTsTransferProxy(_nftTransferProxy);
        feeRecipient = _feeRecipient;
        sellerFee = _sellerFee;
        buyerFee = _buyerFee;
        _minimumPrice = minimumPrice;
    }
}