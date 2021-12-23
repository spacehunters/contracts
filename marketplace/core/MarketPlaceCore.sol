// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "../utils/ReentrancyGuarded.sol";
import "../utils/SafeMath.sol";
import "../utils/EnumerableSet.sol";
import "../utils/Initializable.sol";
import "../utils/AccessControlUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../eip721/IERC721ReceiverUpgradeable.sol";
import "../proxy/OwnedUpgradeabilityStorage.sol";
import "./TokenTransferProxy.sol";
import "./NFTsTransferProxy.sol";
import "../bep20/IBEP20.sol";

contract MarketPlaceCore is 
    OwnedUpgradeabilityStorage,
    ReentrancyGuarded, 
    Initializable, 
    AccessControlUpgradeable, 
    IERC721ReceiverUpgradeable 
{
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;
    using AddressUpgradeable for address;

    struct Listing {
        address seller;
        address paymentToken;
        address listingNft;
        uint256 price;
        uint256 listingTime;
    }

    uint256 public sellerFee;
    uint256 public buyerFee;
    uint256 public minimumPrice;
    address public feeRecipient;
    bool public maintenanceMode;

    TokenTransferProxy public tokenTransferProxy;
    NFTsTransferProxy public nftsTransferProxy;
    EnumerableSet.UintSet private listedTokenIDs;

    mapping(uint256 => Listing) private listings;

    event NewListing(address seller, address paymentToken, address listingNft, uint256 price, uint256 listingTime);
    event ListingPriceChange(address seller, uint256 tokenId, uint256 price);
    event CancelledListing(address seller, uint256 tokenId);
    event PurchaseListing(address buyer, address seller, address listingNft, address paymentToken, uint256 tokenId, uint256 price);

    modifier isListed(address nft, uint256 id) {
        require(listedTokenIDs.contains(uint256(uint160(nft)).add(id)),
            "Token ID not listed"
        );
        _;
    }

    modifier isNotListed(address nft, uint256 id) {
        require(!listedTokenIDs.contains(uint256(uint160(nft)).add(id)),
            "Token ID must not be listed"
        );
        _;
    }

    modifier isSeller(address nft, uint256 id) {
        require(
            listings[uint256(uint160(nft)).add(id)].seller == _msgSender(),
            "Access denied"
        );
        _;
    }

    modifier onlyOwner() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Not admin");
        _;
    }

    function setBuyerFee(uint256 fee) public virtual onlyOwner {
        buyerFee = fee;
    }

    function setSellerFee(uint256 fee) public virtual onlyOwner {
        sellerFee = fee;
    }

    function setFeeRecipient(address recipient) public virtual onlyOwner {
        feeRecipient = recipient;
    }

    function setMinimumPrice(uint256 amount) public virtual onlyOwner {
        minimumPrice = amount;
    }

    function setmaintenanceMode(bool mode) public virtual onlyOwner {
        maintenanceMode = mode;
    }

    function getSellerOfNftID(address nft, uint256 tokenId) public virtual view returns (address) {
        uint256 identifier = uint256(uint160(nft)).add(tokenId);

        if(!listedTokenIDs.contains(identifier)) {
            return address(0);
        }

        return listings[identifier].seller;
    }

    function addListing(
        uint256 id,
        uint256 price,
        address paymentToken,
        address listingNft
    )
        public
        virtual
        payable
        isNotListed(listingNft, id)
    {
        require (maintenanceMode == false, "Market is in maintenance mode");
        //require(price >= minimumPrice, "The price should be over than minimum price");

        uint256 transferAmount = executeFundsTransfer(paymentToken, address(0), _msgSender(), price);
        
        transferNft(listingNft, _msgSender(), address(this), id);

        uint256 identifier = uint256(uint160(listingNft)).add(id);
        listings[identifier] = Listing(_msgSender(), paymentToken, listingNft, price, block.timestamp);
        listedTokenIDs.add(identifier);

        emit NewListing(_msgSender(), paymentToken, listingNft, transferAmount, block.timestamp);
    }

    function cancelListing(address nft, uint256 id)
        public
        virtual
        isListed(nft, id)
        isSeller(nft, id)
    {
        require (maintenanceMode == false, "Market is in maintenance mode");

        uint256 identifier = uint256(uint160(nft)).add(id);
        Listing memory listing = listings[identifier];  

        IERC721Upgradeable(listing.listingNft).approve(address(nftsTransferProxy), id);      
        transferNft(listing.listingNft, address(this), _msgSender(), id);

        delete listings[identifier];
        listedTokenIDs.remove(identifier);

        emit CancelledListing(_msgSender(), id);
    }

    function purchaseListing(address nft, uint256 id) 
        public
        payable
        virtual
        isListed(nft, id) 
    {
        require (maintenanceMode == false, "Market is in maintenance mode");

        uint256 identifier = uint256(uint160(nft)).add(id);
        Listing memory listing = listings[identifier];

        uint256 transferAmount = executeFundsTransfer(listing.paymentToken, _msgSender(), listing.seller, listing.price);

        IERC721Upgradeable(listing.listingNft).approve(address(nftsTransferProxy), id);
        transferNft(listing.listingNft, address(this), _msgSender(), id);
       
        delete listings[identifier];
        listedTokenIDs.remove(identifier);

        emit PurchaseListing(_msgSender(), listing.seller, listing.listingNft, listing.paymentToken, id, transferAmount);
    }

    /**
     * @dev Execute all token / native coin transfers associated with an order match (fees and buyer => seller transfer)
     */
    function executeFundsTransfer(
        address paymentToken, 
        address buyer, 
        address seller, 
        uint price
    )
        internal
        virtual
        returns (uint)
    {
        /* Only payable in the special case of unwrapped Native coin. */
        if (paymentToken != address(0)) {
            require(msg.value == 0, "No need to transfer native coin");
        }

        require(price > 0, "Price must be greater than 0");

        uint256 requireAmount;

        if(buyer == address(0)){ // Listing NFT to marketplace
            requireAmount = price.mul(sellerFee).div(100);

            if (paymentToken != address(0)) {
                transferTokens(paymentToken, seller, feeRecipient, requireAmount); 
            } else {
                require(msg.value >= requireAmount, "Not enought coin");
                payable(feeRecipient).transfer(requireAmount);
            }
        } else { // Buyer make an order
            requireAmount = price.mul(buyerFee.add(100)).div(100);

            if (paymentToken != address(0)) {
                uint256 balance = IBEP20(paymentToken).balanceOf(buyer);
                require(balance >= requireAmount, "Not enought coin");
                transferTokens(paymentToken, buyer, feeRecipient, requireAmount.sub(price));
                transferTokens(paymentToken, buyer, seller, price);
            } else {
                require(msg.value >= requireAmount, "Not enought coin");
                payable(feeRecipient).transfer(requireAmount.sub(price));
                payable(seller).transfer(price);
            }
        }

        return requireAmount;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(address token, address from, address to, uint amount)
        internal
        virtual
    {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }

    /**
     * @dev Transfer NFT
     * @param nft NFT to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param tokenId TokenID
     */
    function transferNft(address nft, address from, address to, uint tokenId)
        internal
        virtual
    {
        nftsTransferProxy.transferFrom(nft, from, to, tokenId);
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override view returns (bytes4) {
        require(listedTokenIDs.contains(tokenId) == false,
            "Token ID should be not listed"
        ); 
        return this.onERC721Received.selector;
    }
}