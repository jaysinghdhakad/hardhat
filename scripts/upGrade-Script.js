const { ethers, upgrades } = require("hardhat");

async function main() {
  const Mytoken = await ethers.getContractFactory("ERC20");
  const mytoken = await upgrades.deployProxy(Mytoken);
  await mytoken.deployed();
  console.log("mytoken deployed to:", mytoken.address);

  const MytokenV2 = await ethers.getContractFactory("ERC20V2");
  const mytokenV2 = await upgrades.upgradeProxy(mytoken.address, MytokenV2);
  console.log("mytoken upgraded");
}

main();