const { exec } = require("child_process");

exec(`hardhat --network ${process.argv[2]} etherscan-verify --api-key ${process.env.POLYGONSCAN_API_KEY} --verbose`, (error, stdout, stderr) => {
    if (error) {
        console.log(`error: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    console.log(`stdout: ${stdout}`);
});