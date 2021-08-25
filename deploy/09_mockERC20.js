module.exports = async ({
    getNamedAccounts,
    deployments
  }) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();
  
    await deploy('MockToken', {
      from: deployer,
      args: [],
    });
  };

  module.exports.tags = ['MockToken']