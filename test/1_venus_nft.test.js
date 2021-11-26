let chai = require("chai");
chai.use(require("chai-as-promised"));
const BN = require('bn.js');
chai.use(require('chai-bn')(BN));
chai.should();
const { expect } = chai;

const VenusNFT = artifacts.require("VenusNFT");

contract("VenusNFT", accounts => {

  let venusNFT;
  let tokenId;
  const testTokenURI = "rune://style-nft/QUJDRA==";

  it("should deploy a new NFT contract (collection)", async () => {
    venusNFT = await VenusNFT.new("VenusNFT", "VNS");
    expect(venusNFT.address).to.not.equal("");
  })
  
  it("should have correct name and symbol", async () => {
    expect(venusNFT.name()).to.eventually.equal("VenusNFT");
    expect(venusNFT.symbol()).to.eventually.equal("VNS");
  })
  
  it("should mint a new token with id of zero", async () => {
    tokenId = await venusNFT.mint.call(accounts[0], testTokenURI);
    await venusNFT.mint(accounts[0], testTokenURI);
    
    tokenId.should.be.bignumber.equals('0');
  })

  it("New token should have a correct URI", async () => {
    let tokenURI = await venusNFT.tokenURI(tokenId);
    tokenURI.should.to.equal("_" + testTokenURI);
  })
})
