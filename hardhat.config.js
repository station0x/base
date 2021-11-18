require("@nomiclabs/hardhat-waffle");
require('hardhat-deploy');
require('dotenv').config()

module.exports = {
  solidity: {
    compilers: [
      {
      version: "0.8.7",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
          }
        },
      }
    ]
  },
  networks:{
    hardhat: {},
    ropsten: {
      url: 'https://eth-ropsten.alchemyapi.io/v2/_6ViI78tHoOAW45KhGO_DrgW6kep4A6f',
      accounts: [process.env.ROPSTEN_PRIVKEY]
    },
    mainnet: {
      url: 'https://eth-mainnet.alchemyapi.io/v2/kPuyZWcXZM4UFH0viuQjaiIq4h61pj-6',
      accounts: [process.env.MAINNET_PRIVKEY]
    },
    ftmOpera: {
      url: 'https://rpc.ftm.tools', 
      accounts: [process.env.MAINNET_PRIVKEY]
    },
    ftmTestnet: {
      url: 'https://rpc.testnet.fantom.network/',
      accounts: [process.env.MAINNET_PRIVKEY]
    }
  },
  namedAccounts: {
    deployer: {
      default:0
    },
    stationLabs: {
      3: '0x91f06A77F5664cfc17cfC022f03DfE24Bd0Ceb3b',
      1: '0x91f06A77F5664cfc17cfC022f03DfE24Bd0Ceb3b',
      4002: '0x6BDD6Bb68Ec6927F56749b46746F0AFA7CdA9F3c',
      250: '0x6BDD6Bb68Ec6927F56749b46746F0AFA7CdA9F3c'
    },
    signerAddress: {
      3: '0x9dBfB700505854c2ab7d545482cec74D4771A091',
      1: '0x9dBfB700505854c2ab7d545482cec74D4771A091',
      4002: '0x9dBfB700505854c2ab7d545482cec74D4771A091',
      250: '0x9dBfB700505854c2ab7d545482cec74D4771A091'
    }
  }
};
