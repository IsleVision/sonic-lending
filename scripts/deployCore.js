const {ethers, network} = require("hardhat");

const main = async () => {
    let sonicAssetAddress;
    let ethAssetAddress;
    let sonicAggregatorAddress;
    let ethAggregatorAddress;


    const contract_owner = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.provider);
    console.log('Contract Owner:'+contract_owner.address);

    if (network.name === "localhost") {
        const MockETH = await ethers.getContractFactory("MockETH");
        let ethAsset = await MockETH.connect(contract_owner).deploy();
        ethAssetAddress = ethAsset.address;
        const MockSonic = await ethers.getContractFactory("MockSonic");
        let sonicAsset = await MockSonic.connect(contract_owner).deploy();
        sonicAssetAddress = sonicAsset.address;
        sonicAggregatorAddress = "0xC13a2Af6076E1dc5673eA9f3476a60299eADf7AE";
        ethAggregatorAddress = "0x5cfF644dDcd40C2165e2C58d146F852f23fe1b0C";
    } else if (network.name === "sonic") {
        ethAssetAddress = "0x309C92261178fA0CF748A855e90Ae73FDb79EBc7";
        sonicAssetAddress = "0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38";
        sonicAggregatorAddress = "0xC13a2Af6076E1dc5673eA9f3476a60299eADf7AE";
        ethAggregatorAddress = "0x5cfF644dDcd40C2165e2C58d146F852f23fe1b0C";
    }

    console.log(`Sonic asset address: ${sonicAssetAddress}`);
    console.log(`ETH asset address: ${ethAssetAddress}`);
    console.log(`Chainlink aggregator address Sonic: ${sonicAggregatorAddress} ETH: ${ethAggregatorAddress}`);

    const SonkToken = await ethers.getContractFactory("SonkToken");
    const sonkToken = await SonkToken.connect(contract_owner).deploy();
    console.log(
        `Sonk Token  address: ${sonkToken.address}, deployer: ${sonkToken.signer.address}`
    );

    const ProtocolCore = await ethers.getContractFactory("ProtocolCore");
    const protocolCore = await ProtocolCore.connect(contract_owner).deploy(
        sonicAssetAddress,
        ethAssetAddress,
        sonkToken.address,
        ethAggregatorAddress,
        sonicAggregatorAddress
    );
    console.log(
        `Protocol Core address: ${protocolCore.address}, deployer: ${protocolCore.signer.address}`
    );

    await sonkToken.transferOwnership(protocolCore.address);
    console.log(
        `Sonk Token ownership transferred from ${sonkToken.signer.address} to ${protocolCore.address}`
    );
};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.log(error);
        process.exit(1);
    });
