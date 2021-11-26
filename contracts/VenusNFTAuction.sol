// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./VenusNFT.sol";
import "./interfaces/IERC2981.sol";

/**
 * @title Venus Auction Contract
 * @dev NFT Auction
 */
contract VenusNFTAuction {
    /*
     *  Storage
     */
    // EIP 2981 supports
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // Venus address
    address public venus;
    // Venus NFT address
    ERC721 public nftAddr;
    uint256 public tokenId;

    address public seller;

    // Bid informations
    mapping(address => uint256) public bids;
    address public highestBidder;
    uint256 public highestBid;

    // Auction parameters
    uint256 public endTime;
    uint256 public startBlock;
    uint256 public claimTime;
    uint256 public startingPrice; // InWei
    uint256 public duration;
    bool public started;
    bool public ended;
    bool public royalty;

    /*
     *  Events
     */
    event HighestBidIncreased(
        address bidder,
        uint256 amount,
        uint256 endTime,
        uint256 claimTime
    );

    event BidWithdrawn(address bidder);

    event AuctionEnded(
        address winner,
        uint256 amount,
        uint256 venusPart,
        uint256 royaltyAmount
    );

    event NFTClaimed();
	
    event BidClaimed();

    constructor(
        address _venus,
        address _seller,
        address _nftAddr,
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _duration,
        bool _royalty
    ) {
        venus = _venus;
        // Seller address who wins the money at the end
        seller = _seller;

        // NFT informations
        nftAddr = ERC721(_nftAddr);
        tokenId = _tokenId;

        if (_royalty) {
            royalty = checkRoyalties(_nftAddr);
        } else {
            royalty = false;
        }

        startingPrice = _startingPrice;
        ended = false;
        duration = _duration;
        startBlock = block.number;
        endTime = block.timestamp + duration;
        claimTime = endTime + 259200; // 3 days
        started = true;
    }

    /*
     * Internal functions
     */
    /// @dev Internal function to check royalties
    function checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC165(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    /*
     * External functions
     */
    /// @dev New bid on Auction
    function bid() external payable {
        require(started && !ended, "Auction is not active");
        require(block.timestamp <= endTime, "Bidding is ended");
        require(
            msg.value > 0.01 * 1 ether,
            "Too small, it should be at least 0.01"
        );
        uint256 newBid = bids[msg.sender] + msg.value;
        require(newBid > highestBid, "There is already a higher bid");
        require(newBid > startingPrice, "Starting price is higher");
        require(msg.sender != seller, "Seller can't bid");

        bids[msg.sender] = newBid;
        highestBidder = msg.sender;
        highestBid = newBid;

        // Add 5 minutes to endtime if someone bids 5 minutes before endingtime
        if (endTime - block.timestamp < 300) {
            endTime += 300; // Will be more in real contract, just testing behavior
            claimTime += 300; // Update claim time too
        }

        emit HighestBidIncreased(msg.sender, newBid, endTime, claimTime);
    }

    /// @dev Withdraw bid from the Auction (Except Highest Bidder)
    function withdraw() external returns (bool) {
        require(msg.sender != highestBidder, "Highest bidder can't withdraw");

        uint256 amount = bids[msg.sender];
        if (amount > 0) {
            // Re-entrency protection
            bids[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                bids[msg.sender] = amount;
                return false;
            }
            emit BidWithdrawn(msg.sender);
        }
        return true;
    }

    /// @dev Close Auction
    function close() external {
        require(block.timestamp >= endTime, "Auction is not ended yet");
        require(block.timestamp < claimTime, "Close window ended");
        require(started && !ended, "Auction is not live");
        ended = true;

        uint256 royaltyAmount = 0;
        address royaltyBeneficiary;
        if (royalty) {
            (royaltyBeneficiary, royaltyAmount) = IERC2981(address(nftAddr))
                .royaltyInfo(tokenId, highestBid);
        }

        if (highestBid > 0 && bids[highestBidder] > 0) {
            // Protect against Re-entrency Attack
            bids[highestBidder] = 0;

            // Transfer auction fee to Venus
            uint256 venusPart = 5 * (highestBid / 200);
            payable(venus).transfer(venusPart);

            // Transfer Royalties
            if (royalty) {
                payable(royaltyBeneficiary).transfer(royaltyAmount);
            }

            // Transfer NFT to Winner(Highest Bidder)
            nftAddr.transferFrom(address(this), highestBidder, tokenId);
            // Transfer funds to Seller
            uint256 amount = highestBid - venusPart - royaltyAmount;
            payable(seller).transfer(amount);
            emit AuctionEnded(highestBidder, amount, venusPart, royaltyAmount);
        }
    }

    /// @dev Claim NFT back(Only Seller) after claim time
    function claimNFT() external {
        require(msg.sender == seller, "Only seller can claim token back");
        require(block.timestamp >= claimTime, "Claim time not started yet");
        require(
            nftAddr.getApproved(tokenId) == address(this),
            "Contract is not operator"
        );

        nftAddr.transferFrom(address(this), seller, tokenId);
        emit NFTClaimed();
    }

    /// @dev Claim funds back after claim time (Only Highest Bidder)
    function claimHighestBid() external {
        require(
            msg.sender == highestBidder,
            "Only highest bidder can claim funds back"
        );
        require(block.timestamp >= claimTime, "Claim time not started yet");

        uint256 amount = bids[highestBidder];
        if (amount > 0) {
            bids[highestBidder] = 0;
            payable(msg.sender).transfer(amount);
            emit BidClaimed();
        }
    }
}
