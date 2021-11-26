let chai = require("chai");
chai.use(require("chai-as-promised"));
const BN = require('bn.js');
chai.use(require('chai-bn')(BN));
chai.should();
const { expect } = chai;
const truffleAssert = require('truffle-assertions');

const VenusNFT = artifacts.require("VenusNFT");
const VenusNFTFactory = artifacts.require("VenusNFTFactory");
const VenusNFTMarketplace = artifacts.require("VenusNFTMarketplace");

contract("VenusNFTMarketplace", accounts => {

  const testTokenURI = "testURI";
  const oneEth = new BN("1000000000000000000");
  const oneDay = 86400;
  
  const factoryOwner = accounts[0];
  const nft0Owner = accounts[1];
  const buyer0 = accounts[2];
  const buyer1 = accounts[3];
  
  let venusNFT0;
  let venusAsset0ID;
  let venusMarketplace;

  it("should setup contracts", async () => {
    
    // deploy factory
    venusNFTFactory = await VenusNFTFactory.new({from: factoryOwner});

    // deploy a new NFT contract
    venusNFT0 = await VenusNFT.new("VenusNFT0", "venus0", {from: nft0Owner});

    // mint a new NFT item
    venusAsset0ID = await venusNFT0.mint.call(nft0Owner, testTokenURI, {from: nft0Owner});
    await venusNFT0.mint(nft0Owner, testTokenURI, {from: nft0Owner});

    // deploy marketplace
    venusMarketplace = await VenusNFTMarketplace.new();
  })

  it("can not make an offer for unlisted NFT", async () => {
    await truffleAssert.reverts(venusMarketplace.makeOffer(venusNFT0.address, venusAsset0ID, oneDay, {from: buyer0, value: oneEth}));
  })

  it("should be able to list a NFT asset on marketplace", async () => {
    await venusMarketplace.listAsset(venusNFT0.address, venusAsset0ID, oneEth, {from: nft0Owner});
  })

  it("should be able to make an offer for listed NFT", async () => {
    let balanceBefore = await web3.eth.getBalance(buyer0);
    await venusMarketplace.makeOffer(venusNFT0.address, venusAsset0ID, oneDay, {from: buyer0, value: oneEth});
    let balanceAfter = await web3.eth.getBalance(buyer0);
    expect(balanceAfter).to.bignumber.lessThan(balanceBefore);
  })

  it("should be able to cancel an offer", async () => {
    let balanceBefore = await web3.eth.getBalance(buyer0);
    await venusMarketplace.cancelOffer(venusNFT0.address, venusAsset0ID, {from: buyer0});
    let balanceAfter = await web3.eth.getBalance(buyer0);
    expect(balanceAfter).to.bignumber.greaterThan(balanceBefore);
  })

  it("owner can not make an offer himself", async () => {
    await truffleAssert.reverts(venusMarketplace.makeOffer(venusNFT0.address, venusAsset0ID, oneDay, {from: nft0Owner, value: oneEth}));
  })

  it("should be able to make an offer from another buyer", async () => {
    let balanceBefore = await web3.eth.getBalance(buyer1);
    await venusMarketplace.makeOffer(venusNFT0.address, venusAsset0ID, oneDay, {from: buyer1, value: oneEth});
    let balanceAfter = await web3.eth.getBalance(buyer1);
    expect(balanceAfter).to.bignumber.lessThan(balanceBefore);
  })

  it("can not make an offer when another offer exists", async () => {
    await truffleAssert.reverts(venusMarketplace.makeOffer(venusNFT0.address, venusAsset0ID, oneDay, {from: buyer1, value: oneEth}));    
  })

  it("only owner can accept or decline offers", async () => {
    await truffleAssert.reverts(venusMarketplace.acceptOffer(venusNFT0.address, venusAsset0ID, buyer1, {from: buyer1}));
    await truffleAssert.reverts(venusMarketplace.declineOffer(venusNFT0.address, venusAsset0ID, buyer1, {from: buyer1}));
  })

  it("should be able to decline an offer", async () => {
    let balanceBefore = await web3.eth.getBalance(buyer1);
    await venusMarketplace.declineOffer(venusNFT0.address, venusAsset0ID, buyer1, {from: nft0Owner});
    let balanceAfter = await web3.eth.getBalance(buyer1);
    expect(balanceAfter).to.bignumber.greaterThan(balanceBefore);
  })

  it("should be able to make another offer once canceled or declined", async () => {
    let balanceBefore = await web3.eth.getBalance(buyer1);
    await venusMarketplace.makeOffer(venusNFT0.address, venusAsset0ID, oneDay, {from: buyer1, value: oneEth});
    let balanceAfter = await web3.eth.getBalance(buyer1);
    expect(balanceAfter).to.bignumber.lessThan(balanceBefore);
  })

  it("should be able to accept an offer", async () => {
    await venusNFT0.approve(venusMarketplace.address, venusAsset0ID, {from: nft0Owner});
    let balanceBefore = await web3.eth.getBalance(nft0Owner);
    await venusMarketplace.acceptOffer(venusNFT0.address, venusAsset0ID, buyer1, {from: nft0Owner});
    let balanceAfter = await web3.eth.getBalance(nft0Owner);
    expect(balanceAfter).to.bignumber.greaterThan(balanceBefore);
  })

  it("ownership should be changed after sales", async () => {
    let newOwner = await venusNFT0.ownerOf(venusAsset0ID);
    expect(newOwner).to.equal(buyer1);
  })

})
