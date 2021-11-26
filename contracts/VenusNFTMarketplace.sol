// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces/IVenusNFTMarketplace.sol";
import "./VenusNFTManageable.sol";
import "./VenusNFT.sol";

/**
 * @notice - This is the Venus NFT contract
 */
contract VenusNFTMarketplace is IVenusNFTMarketplace, VenusNFTManageable {
    // Listed Data
    mapping(address => VenusCollection) public _collections;

    modifier ensureListed(VenusNFT _venusNFT, uint256 _tokenId) {
        require(
            _collections[address(_venusNFT)]._assets[_tokenId].openToSell ==
                true,
            "VenusNFTManageable: asset not listed"
        );
        _;
    }

    constructor() {}

    function listAsset(
        VenusNFT _venusNFT,
        uint256 _tokenId,
        uint256 basicPrice
    ) public ensureTokenOwner(_venusNFT, _tokenId) {
        _collections[address(_venusNFT)]._assets[_tokenId].openToSell = true;
        _collections[address(_venusNFT)]
            ._assets[_tokenId]
            .basicPrice = basicPrice;
    }

    function delistAsset(VenusNFT _venusNFT, uint256 _tokenId)
        public
        ensureTokenOwner(_venusNFT, _tokenId)
        ensureListed(_venusNFT, _tokenId)
    {
        Bid[] memory bids = _collections[address(_venusNFT)]
            ._assets[_tokenId]
            .bids;
        for (uint256 i = 0; i < bids.length; i++) {
            if (
                bids[i].canceled == false &&
                bids[i].declined == false &&
                block.timestamp < bids[i].expireAt
            ) {
                require(false, "VenusNFTMarketplace: active offers exist");
            }
        }

        delete _collections[address(_venusNFT)]._assets[_tokenId];
    }

    function makeOffer(
        VenusNFT _venusNFT,
        uint256 _tokenId,
        uint256 _expireTime
    )
        public
        payable
        ensureListed(_venusNFT, _tokenId)
        ensureNotTokenOwner(_venusNFT, _tokenId)
    {
        uint256 _price = msg.value;
        require(_price > 0, "VenusNFTMarketplace: price can not be zero");

        (bool exist, ) = searchActiveOffer(_venusNFT, _tokenId, msg.sender);
        require(
            exist == false,
            "VenusNFTMarketplace: offer already exists for this address"
        );

        _collections[address(_venusNFT)]._assets[_tokenId].bids.push(
            Bid(
                msg.sender,
                _price,
                block.timestamp,
                block.timestamp + _expireTime,
                false,
                false
            )
        );
    }

    function cancelOffer(VenusNFT _venusNFT, uint256 _tokenId) public {
        (bool exist, uint256 index) = searchActiveOffer(
            _venusNFT,
            _tokenId,
            msg.sender
        );
        require(exist == true, "VenusNFTMarketplace: offer not exist");

        uint256 refundAmount = _collections[address(_venusNFT)]
            ._assets[_tokenId]
            .bids[index]
            .price;
        payable(msg.sender).transfer(refundAmount);

        _collections[address(_venusNFT)]
            ._assets[_tokenId]
            .bids[index]
            .canceled = true;
    }

    function searchActiveOffer(
        VenusNFT _venusNFT,
        uint256 _tokenId,
        address _bidder
    )
        public
        view
        ensureListed(_venusNFT, _tokenId)
        returns (bool exist, uint256 index)
    {
        Bid[] memory bids = _collections[address(_venusNFT)]
            ._assets[_tokenId]
            .bids;
        uint256 i;
        for (i = 0; i < bids.length; i++) {
            if (
                bids[i].bidder == _bidder &&
                bids[i].canceled == false &&
                bids[i].declined == false &&
                block.timestamp < bids[i].expireAt
            ) return (true, i);
        }
        return (false, 0);
    }

    function acceptOffer(
        VenusNFT _venusNFT,
        uint256 _tokenId,
        address _to
    ) public ensureTokenOwner(_venusNFT, _tokenId) {
        (bool exist, uint256 index) = searchActiveOffer(
            _venusNFT,
            _tokenId,
            _to
        );
        require(
            exist == true,
            "VenusNFTMarketplace: recipient's offer not exist"
        );

        Bid memory _bid = _collections[address(_venusNFT)]
            ._assets[_tokenId]
            .bids[index];
        require(
            _bid.canceled == false,
            "VenusNFTMarketplace: offer canceled by bidder"
        );
        require(
            _bid.declined == false,
            "VenusNFTMarketplace: offer declined by owner"
        );
        require(
            block.timestamp < _bid.expireAt,
            "VenusNFTMarketplace: offer already expired"
        );

        _venusNFT.transferFrom(msg.sender, _to, _tokenId);
        payable(msg.sender).transfer(_bid.price);

        // Delist token since the ownership is transferred
        delete _collections[address(_venusNFT)]._assets[_tokenId];
    }

    function declineOffer(
        VenusNFT _venusNFT,
        uint256 _tokenId,
        address _to
    ) public ensureTokenOwner(_venusNFT, _tokenId) {
        (bool exist, uint256 index) = searchActiveOffer(
            _venusNFT,
            _tokenId,
            _to
        );
        require(
            exist == true,
            "VenusNFTMarketplace: recipient's offer not exist"
        );

        Bid memory _bid = _collections[address(_venusNFT)]
            ._assets[_tokenId]
            .bids[index];
        require(
            _bid.canceled == false,
            "VenusNFTMarketplace: offer canceled by bidder"
        );
        require(
            _bid.declined == false,
            "VenusNFTMarketplace: offer declined by owner"
        );
        require(
            block.timestamp < _bid.expireAt,
            "VenusNFTMarketplace: offer already expired"
        );

        payable(_to).transfer(_bid.price);
        _collections[address(_venusNFT)]
            ._assets[_tokenId]
            .bids[index]
            .declined = true;
    }
}
