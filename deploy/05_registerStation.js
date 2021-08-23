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
        "station:callisto-6",
        (await get('Station')).address
    )
  };