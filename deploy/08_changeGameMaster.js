module.exports = async ({
    getNamedAccounts,
    deployments
  }) => {
    const { execute, get } = deployments;
    const { deployer, gameMaster } = await getNamedAccounts();
  
    await execute('Registry', {
        from: deployer,
    },
        "changeGameMaster",
        gameMaster
    )
  };

  module.exports.tags = ['Core']