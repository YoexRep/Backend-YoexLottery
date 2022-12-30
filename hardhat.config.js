require("@nomiclabs/hardhat-waffle")
require("@nomiclabs/hardhat-etherscan")
require("hardhat-deploy")
require("solidity-coverage")
require("hardhat-gas-reporter")
require("hardhat-contract-sizer")
require("dotenv").config()

const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL || "key"; //Estos pipes es para en caso de que no tenga el url
const PRIVATE_KEY = process.env.PRIVATE_KEY || "key";

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "key";

const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY || "key";



module.exports = {
    solidity: {
        compilers: [{ version: "0.8.8" }, { version: "0.6.6" }, {version: "0.8.17"}],
      },
    defaultNetwork: "hardhat",
    networks: { 
      hardhat: {
      chainId: 31337,
  },
  localhost: {
      chainId: 31337,
  },
      goerli: {
        url: GOERLI_RPC_URL,
        accounts: [PRIVATE_KEY], // Es la direccion de clave privada de mi wallet
        chainId: 5,
        blockConfirmation: 6, //Los bloques que tiene que esperar la red de goerli, indice nuestra transaccion. y podamos verla
      },
    },

    gasReporter: {
      enabled: false,
      outputFile: "gas-report.txt", // para exportarlo a un fichero
      noColors: true, // sin color para evitar problemas con el archivo txt
      currency: "USD", // y podemos ponerle en que unidad queremos ver el reporte del gas
      coinmarketcap: COINMARKETCAP_API_KEY, // Para obtener el precio necesito conectarme a coinmarketcap con una API
      token: "BNB",
    },
    namedAccounts: {
        deployer: {
          default: 0,
        },
        player: {
          default: 1,
        },
      },
      mocha:{
        timeout: 200000, //200 segundos como maximo para las promesas
      },

      etherscan: {
        // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
        apiKey: {
            goerli: ETHERSCAN_API_KEY,
           
      }},
}
