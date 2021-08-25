module.exports = async ({
    getNamedAccounts,
    deployments
  }) => {
    const { deploy, get } = deployments;
    const { deployer, manufacturerOperator, saleToken, stationLabs } = await getNamedAccounts();
  
    await deploy('ManufacturerV1', {
      from: deployer,
      args: [
        manufacturerOperator,
        saleToken,
        (await get('Station')).address,
        stationLabs
      ],
    });
  };

  module.exports.tags = ['Core']