let chai = require("chai");
chai.use(require("chai-as-promised"));
const BN = require('bn.js');
chai.use(require('chai-bn')(BN));
chai.should();
const { expect } = chai;
const truffleAssert = require('truffle-assertions');

const VenusNFT = artifacts.require("VenusNFT");
const VenusNFTFactory = artifacts.require("VenusNFTFactory");
const VenusNFTAuction = artifacts.require("VenusNFTAuction");

contract("VenusNFTAuction", accounts => {

  const testTokenURI = "testURI";
  const oneEth = new BN("1000000000000000000");
  const oneDay = 86400;
  
  const factoryOwner = accounts[0];
  const nft0Owner = accounts[1];
  const bidder0 = accounts[2];
  const bidder1 = accounts[3];
  
  let venusNFTFactory;
  let venusNFT0;
  let venusAsset0ID;
  let venusAuction;

  it("should setup contracts", async () => {
    
    // deploy factory
    venusNFTFactory = await VenusNFTFactory.new({from: factoryOwner});

    // deploy a new NFT contract
    venusNFT0 = await VenusNFT.new("VenusNFT0", "venus0", {from: nft0Owner});

    // mint a new NFT item
    venusAsset0ID = await venusNFT0.mint.call(nft0Owner, testTokenURI, {from: nft0Owner});
    await venusNFT0.mint(nft0Owner, testTokenURI, {from: nft0Owner});

    // create auction with nft 0
    await venusNFT0.approve(venusNFTFactory.address, venusAsset0ID, {from: nft0Owner});
    let venusAuctionAddress = await venusNFTFactory.createAuction.call(venusNFT0.address, venusAsset0ID, oneEth, oneDay, {from: nft0Owner});
    await venusNFTFactory.createAuction(venusNFT0.address, venusAsset0ID, oneEth, oneDay, {from: nft0Owner});
    venusAuction = await VenusNFTAuction.at(venusAuctionAddress);
  })

  it("Auction should have a correct NFT address", async () => {
    (await venusAuction.nftAddr()).should.be.equal(venusNFT0.address);
  })

  it("Auction should have a correct token id", async () => {
    (await venusAuction.tokenId()).should.be.bignumber.equal(venusAsset0ID);
  })
  
  it("Auction should have a correct seller", async () => {
    (await venusAuction.seller()).should.be.equal(nft0Owner);
  })

  it("Auction should have a correct starting price", async () => {
    (await venusAuction.startingPrice()).should.be.bignumber.equal(oneEth);
  })

  it("can not bid with lower price than starting price", async () => {
    await truffleAssert.reverts(venusAuction.bid({from: bidder0, value: oneEth.mul(new BN(1))}));
  })

  it("should place a bid from bidder0", async () => {
    await venusAuction.bid({from: bidder0, value: oneEth.mul(new BN(2))});
  })

  it("can not bid with lower price than highest price", async () => {
    await truffleAssert.reverts(venusAuction.bid({from: bidder1, value: oneEth.mul(new BN(2))}));
  })

  it("should place higher bid from bidder1", async () => {
    await venusAuction.bid({from: bidder1, value: oneEth.mul(new BN(3))});
  })
  
  it("should be able to increase bid from bidder0", async () => {
    venusAuction.bid({from: bidder0, value: oneEth.mul(new BN(2))});  // total bid: 4 ETH
  })
  
  it("cannot withdraw highest bid from bidder0", async () => {
    await truffleAssert.reverts(venusAuction.withdraw({from: bidder0}));
  })

  it("should be able to withdraw bid from bidder1", async () => {
    let balanceBefore = await web3.eth.getBalance(bidder1);
    await venusAuction.withdraw({from: bidder1});
    let balanceAfter = await web3.eth.getBalance(bidder1);
    expect(balanceAfter).to.bignumber.greaterThan(balanceBefore);
  })

})
