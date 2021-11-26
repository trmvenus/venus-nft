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

contract("VenusNFTFactory", accounts => {

  const testTokenURI = "testURI";
  const oneEth = "1000000000000000000";
  const oneDay = 86400;
  
  const factoryOwner = accounts[0];
  const nft0Owner = accounts[1];
  
  let venusNFTFactory;
  let venusNFT0;
  let venusAsset0ID;
  let venusAuction;

  it("should deploy a Venus NFT Factory contract", async () => {
    venusNFTFactory = await VenusNFTFactory.new({from: factoryOwner});
  })
  
  it("should create a new NFT collection", async () => {
    let venusNFT0Address = await venusNFTFactory.createNewCollection.call("VenusNFT0", "venus0", nft0Owner);
    let tx = await venusNFTFactory.createNewCollection("VenusNFT0", "venus0", nft0Owner);

    expect(venusNFT0Address).to.not.equal("");

    truffleAssert.eventEmitted(tx, 'NewCollectionCreated', (ev) => {
      return ev._name === "VenusNFT0" &&
            ev._symbol === "venus0" &&
            ev._venusNFT === venusNFT0Address &&
            ev._to === nft0Owner;
    }, "NewCollectionCreated should be emitted with correct parameters");

    venusNFT0 = await VenusNFT.at(venusNFT0Address);
  })

  it("should mint a new NFT", async () => {
    venusAsset0ID = await venusNFT0.mint.call(nft0Owner, testTokenURI, {from: nft0Owner});
    await venusNFT0.mint(nft0Owner, testTokenURI, {from: nft0Owner});

    venusAsset0ID.should.be.bignumber.equals('0');
  })

  it("should create a new auction", async () => {

    await venusNFT0.approve(venusNFTFactory.address, venusAsset0ID, {from: nft0Owner});
    let approved = await venusNFT0.getApproved(venusAsset0ID);

    expect(approved).to.equal(venusNFTFactory.address);

    let venusAuctionAddress = await venusNFTFactory.createAuction.call(venusNFT0.address, venusAsset0ID, oneEth, oneDay, {from: nft0Owner});
    await venusNFTFactory.createAuction(venusNFT0.address, venusAsset0ID, oneEth, oneDay, {from: nft0Owner});

    venusAuction = await VenusNFTAuction.at(venusAuctionAddress);

    expect(venusAuctionAddress).to.not.equal("");
  })

})
