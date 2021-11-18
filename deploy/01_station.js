module.exports = async ({
    getNamedAccounts,
    deployments
  }) => {
    const { deploy  } = deployments;
    const { deployer, stationLabs, signerAddress } = await getNamedAccounts();
  
    await deploy('Station', {
      from: deployer,
      args: ['Station: Callisto-6', 'CAL6', stationLabs, signerAddress]
    });
  };

  module.exports.tags = ['Core']