const VenusNFT = artifacts.require("VenusNFT");
const BN = require('bn.js');
const fs = require("fs");

module.exports = async function (deployer) {
  await deployer.deploy(VenusNFT, "Venus", "VNS");
  const venusNFT = await VenusNFT.deployed();

  // const venusNFT = await VenusNFT.at("0x12b4B13128C991Bb44F5583C3582c9554d92A75D");

  console.log("VenusNFT is deployed at ", venusNFT.address);

  /*let text = fs.readFileSync("./migrations/whitelist.csv");
  let presaleAddresses = text.toString().replace(/\r\n/g,'\n').split("\n");

  let amounts = [];
  for (let i = 0; i < presaleAddresses.length; i ++) {
    amounts.push(new BN(3));
  }

  console.log("=========== presaleAddresses ===========");
  console.log(presaleAddresses);
  console.log("=========== amounts ===========");
  console.log(amounts);
  
  await venusNFT.editPresale(presaleAddresses, amounts);*/
};
