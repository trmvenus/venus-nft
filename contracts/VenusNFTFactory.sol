// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./VenusNFT.sol";
import "./VenusNFTAuction.sol";
import "./VenusNFTManageable.sol";

/**
 * @notice - This is the Venus NFT contract
 */
contract VenusNFTFactory is VenusNFTManageable {
    VenusNFT[] public venusNFTs;
    VenusNFTAuction[] public venusAuctions;

    event NewCollectionCreated(
        string _name,
        string _symbol,
        VenusNFT _venusNFT,
        address _to
    );

    event NewAssetCreated(
        VenusNFT _collection,
        uint256 _tokenId,
        address _to
    );

    constructor() {}

    function createNewCollection(
        string memory _name,
        string memory _symbol,
        address _to
    ) public returns (VenusNFT) {
        require(_to != address(0), "VenusNFTFactory: owner is zero address");

        VenusNFT _newVenusNFT = new VenusNFT(_name, _symbol);
        _newVenusNFT.transferOwnership(_to);
        venusNFTs.push(_newVenusNFT);

        emit NewCollectionCreated(_name, _symbol, _newVenusNFT, _to);
        return _newVenusNFT;
    }

    function createNewAsset(
        VenusNFT _collection,
        address _to
    ) public returns (uint256) {
        require(
            address(_collection) != address(0),
            "VenusNFTFactory: collection is zero address"
        );
        require(_to != address(0), "VenusNFTFactory: owner is zero address");

        // uint256 newTokenId = _collection.mint(_to, "");

        // emit NewAssetCreated(_collection, newTokenId, _to);
        // return newTokenId;
        return 0;
    }

    function createAuction(
        VenusNFT _venusNFT,
        uint256 _tokenId,
        uint256 _startPrice,
        uint256 _duration
    ) public ensureTokenOwner(_venusNFT, _tokenId) returns (VenusNFTAuction) {
        VenusNFTAuction _venusAuction = new VenusNFTAuction(
            address(this),
            msg.sender,
            address(_venusNFT),
            _tokenId,
            _startPrice,
            _duration,
            false
        );
        _venusNFT.transferFrom(msg.sender, address(_venusAuction), _tokenId);
        venusAuctions.push(_venusAuction);

        return _venusAuction;
    }
}
