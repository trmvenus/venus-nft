// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../VenusNFT.sol";

/**
 * @notice - This is the interface of Venus NFT contract
 */
interface IVenusNFTMarketplace {
    
    struct Bid {
        address bidder;
        uint256 price;
        uint256 createdAt;
        uint256 expireAt;
        bool canceled;
        bool declined;
    }

    struct VenusAsset {
        uint256 tokenId;
        address owner;
        bool openToSell;
        uint256 basicPrice;
        Bid[] bids;
    }

    struct VenusCollection {
        VenusNFT venusNFT;
        mapping(uint256 => VenusAsset) _assets;
    }    
}