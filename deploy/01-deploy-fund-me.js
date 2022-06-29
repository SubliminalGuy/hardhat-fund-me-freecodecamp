// const { getNamedAccounts } = require("hardhat")

// module.exports.default = deployFunc
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { network } = require("hardhat")
require("dotenv").config()
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccount, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    // if chainId is X use address Y
    //const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    // when using localhost or hardhat we have to use a mock
    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["priceFeed"]
    }
    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer,
        args: args, // put price feed address
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        console.log(
            `Waiting ${network.config.blockConfirmations} block confirmations`
        )
        await verify(fundMe.address, args)
    }

    log("----------------------------------------------------")
}

module.exports.tags = ["all", "fundme"]
