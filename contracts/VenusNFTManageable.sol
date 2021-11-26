// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./VenusNFT.sol";

/**
 * @notice - This is the Venus NFT Manageable contract
 */
abstract contract VenusNFTManageable {
    modifier ensureTokenOwner(VenusNFT _venusNFT, uint256 _tokenId) {
        require(
            address(_venusNFT) != address(0),
            "VenusNFTManageable: collection is zero address"
        );
        require(
            _venusNFT.ownerOf(_tokenId) == msg.sender,
            "VenusNFTManageable: caller is not owner of token"
        );
        _;
    }

    modifier ensureNotTokenOwner(VenusNFT _venusNFT, uint256 _tokenId) {
        require(
            address(_venusNFT) != address(0),
            "VenusNFTManageable: collection is zero address"
        );
        require(
            _venusNFT.ownerOf(_tokenId) != msg.sender,
            "VenusNFTManageable: caller is the owner of token"
        );
        _;
    }
}
