
const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  await hre.run("compile");

  const Marketplace = await hre.ethers.getContractFactory("MarketPlace");
  const marketplace = await Marketplace.deploy(55,10000, ethers.constants.AddressZero);

  await marketplace.deployed();

  console.log("marketplace deployed to:", marketplace.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
