require("@nomiclabs/hardhat-waffle");
require('hardhat-deploy');

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
  namedAccounts: {
    deployer:{
      default:0
    },
    gameMaster: {
      4: ''
    }, 
    manufacturerOperator: {
      4: ''
    },
    saleToken: {
      4: ''
    },
    stationLabs: {
      4: ''
    }
  }
};
