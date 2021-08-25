module.exports = async ({
    getNamedAccounts,
    deployments
  }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
  
    await deploy('StationHooks', {
      from: deployer,
      args: [],
    });
  };

  module.exports.tags = ['Core']