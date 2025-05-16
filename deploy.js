const hre = require("hardhat");

async function main() {
  const Auction = await hre.ethers.getContractFactory("auction");
  const auction = await Auction.deploy();

  console.log(`Contract deployed to: ${auction.target}`);
}

main().catch((error) => {
  console.error("Error in deployment:", error);
  process.exitCode = 1;
});
