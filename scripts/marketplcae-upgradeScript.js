const { ethers, upgrades } = require("hardhat");

async function main() {
  const MarketPlace = await ethers.getContractFactory("MarketPlaceup");
  const marketPlace = await upgrades.deployProxy(MarketPlace,[55,10000, ethers.constants.AddressZero]);
  await marketPlace.deployed();
  console.log("mytoken deployed to:", marketPlace.address);

  const MarketPlaceV2 = await ethers.getContractFactory("MarketPlaceup2");
  const marketPlaceV2 = await upgrades.upgradeProxy(marketPlace.address, MarketPlaceV2,[550,10000, ethers.constants.AddressZero,"jay"]);
  console.log("mytoken upgraded");
}

main();