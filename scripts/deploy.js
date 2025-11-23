const { ethers } = require("hardhat");

async function main() {
  const FlowMintPool = await ethers.getContractFactory("FlowMintPool");
  const flowMintPool = await FlowMintPool.deploy();

  await flowMintPool.deployed();

  console.log("FlowMintPool contract deployed to:", flowMintPool.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
