//Este archivo me  ayudara a selecionar el pricefeed dependiendo en la red que este

const { ethers } = require("hardhat");

const networkConfig = {
   
  default: {
    name: "hardhat",
    keepersUpdateInterval: "30",
},31337:{
     
  name: "localhost",
  //Para vrfCoordinatorv2  //En hardhat para el coordinator corremos un mock
  entranceFee: ethers.utils.parseEther("0.01"),
  gasLane: "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",   
  //Para suscripcionId en hardhat usaremos los metodos create y fund del mock
  callbackGasLimit: "50000", // 500,000 gas
  keepersUpdateInterval: "30",
  raffleEntranceFee: ethers.utils.parseEther("0.01"), // 0.01 ETH
  subscriptionId: "7778",


},
  5: {
      name: "goerli",
      vrfCoordinatorV2: "0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D",
      entranceFee: ethers.utils.parseEther("0.01"),
      gasLane: "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
      subscriptionId: "7778", // para la redes de prueba creremos la suscripcion desde la web
      callbackGasLimit: "50000", // 500,000 gas
      keepersUpdateInterval: "30",
    },}
    


  const BASE_FEE = ethers.utils.parseEther("0.25"); // Este es costo premium por obtener un numero random
  const GAS_PRICE_LINK = 1e9 // 1000000000 -- La cantidad de link por gas que se pagara basa en el precio de la moneda de la blockchain


////
const VRF_SUB_AMOUNT = ethers.utils.parseEther("2");

  
  const developmentChains = ["hardhat", "localhost"];


  
  module.exports = {
    networkConfig,
    developmentChains,
    BASE_FEE,
    GAS_PRICE_LINK,
    VRF_SUB_AMOUNT
  
  };