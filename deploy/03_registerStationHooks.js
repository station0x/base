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
        "stationHooks",
        (await get('StationHooks')).address
    )
    return true
  };