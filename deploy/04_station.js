module.exports = async ({
    getNamedAccounts,
    deployments
  }) => {
    const { deploy, get } = deployments;
    const { deployer } = await getNamedAccounts();
  
    await deploy('Station', {
      from: deployer,
      args: ['Callisto-6', 'CAL6', (await get('Registry')).address],
    });
  };

  module.exports.tags = ['Core']