
const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  await hre.run("compile");

  const MyToken = await hre.ethers.getContractFactory("ERC20Old");
  const myToken = await MyToken.deploy();

  await myToken.deployed();

  console.log("myToken deployed to:", myToken.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
