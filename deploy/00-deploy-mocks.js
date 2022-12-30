const { network } = require("hardhat");

const {
  developmentChains,
  BASE_FEE, 
  GAS_PRICE_LINK
} = require("../helper-hardhat-config");


  

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  //uint96 _baseFee, uint96 _gasPriceLink
  if (developmentChains.includes(network.name)) {
    log("Local network detectada, desplegando mocks...");
    await deploy("VRFCoordinatorV2Mock", {
      from: deployer,
      log: true,
      args: [BASE_FEE, GAS_PRICE_LINK],
    });

    log("Mock desplegandose");
    log("-------------------------------------------------");
  }
};

module.exports.tags = ["all", "mocks"];