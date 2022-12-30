const { network, ethers } = require("hardhat");

//Export el networkConfig desde el archvio helper
const {
  networkConfig,
  developmentChains,
  VRF_SUB_AMOUNT
} = require("../helper-hardhat-config");

const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts(); //Para obetner el nombre de las cuentas con private key que creamos para la network
  
    const chainId = network.config.chainId;


    let vrfCoordinatorV2Address, subscriptionId;

    
  
    //Si es una red local de prueba uso un mock para conseguir el random
    if (developmentChains.includes(network.name)) {
      const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock");
  
      vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;

        //Obtener el suscripcion ID para chainlink keeper

        const transactionResponse = await vrfCoordinatorV2Mock.createSubscription()
        const transationReceipt = await transactionResponse.wait(1)
       
       //obtengo el id devuelto del evento tras llamar a createSubscription
        subscriptionId = transationReceipt.events[0].args.subId


        //luego necesitamos depostar links para que poder usar nuestro keeper

        //Para eso llamo al metodo fund, el cual recibe el id, y la cantidad que voy a despositar, como es una red local, lo puedo inventar.
        await vrfCoordinatorV2Mock.fundSubscription(subscriptionId, VRF_SUB_AMOUNT)


    } else {
      //de lo contrario solo busco el random con chainlink
      vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
      subscriptionId = networkConfig[chainId]["subscriptionId"];
    
    }
  


    //Este args es el contrato que recibe mi raffle, como implementa un VRfCoordinador necesito hacer un mock de eso, si estoy en una red de prueba local, y si no, solo uso el contrato real
    const entranceFee = networkConfig[chainId]["entranceFee"]
    const gasLane = networkConfig[chainId]["gasLane"]
    const callbackGasLimit = networkConfig[chainId]["callbackGasLimit"]
    const interval = networkConfig[chainId]["keepersUpdateInterval"]

    
    const args = [vrfCoordinatorV2Address, entranceFee, gasLane, subscriptionId, callbackGasLimit, interval];


      //Metodo para deploy el contrato raffle
  const Raffle = await deploy("Raffle", {
    from: deployer,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1, //Me espera el numero de bloques(definido en hardhat.config) o 1
  });

 // Ensure the Raffle contract is a valid consumer of the VRFCoordinatorV2Mock contract.
 if (developmentChains.includes(network.name)) {
  const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
  await vrfCoordinatorV2Mock.addConsumer(subscriptionId, Raffle.address)
}


   //verifico si es una localnetowrk no lo verifico, pero si es una red como goerli o rinkipi si lo hago
   if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(Raffle.address, args);
  }

  log("-------------------------------------------");

};

module.exports.tags = ["all", "raffle"];