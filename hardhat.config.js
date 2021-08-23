require("@nomiclabs/hardhat-waffle");
require('hardhat-deploy');
require('dotenv').config()

module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks:{
    hardhat: {},
    mumbai:{
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [process.env.MUMBAI_PRIVKEY]
    },
    polygon:{
      url: `https://polygon-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts: [process.env.POLYGON_PRIVKEY]
    },
  },
  namedAccounts: {
    deployer: {
      default:0
    },
    gameMaster: {
      80001: '0xC4D37babfE60b208dD695155Cc80C981E6d38E4a',
      137: ''
    }, 
    manufacturerOperator: {
      80001: '0xC4D37babfE60b208dD695155Cc80C981E6d38E4a',
      137: ''
    },
    saleToken: {
      80001: '0x2d7882beDcbfDDce29Ba99965dd3cdF7fcB10A1e',
      137: ''
    },
    stationLabs: {
      80001: '0xC4D37babfE60b208dD695155Cc80C981E6d38E4a',
      137: ''
    }
  }
};
