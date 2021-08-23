module.exports = async ({
    getNamedAccounts,
    deployments
  }) => {
    const { execute, get } = deployments;
    const { deployer } = await getNamedAccounts();
  
    await execute('Registry', {
        from: deployer,
    },
        "setAddressOf",
        "manufacturerV1",
        (await get('ManufacturerV1')).address
    )
    return true
  };