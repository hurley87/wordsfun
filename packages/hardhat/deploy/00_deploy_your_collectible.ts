import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const deployContracts: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployer } = await hre.getNamedAccounts();
  const { deploy } = hre.deployments;

  // Deploy LibraryColors
  const libraryColors = await deploy("LibraryColors", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  // Deploy WordsFun (YourCollectible)
  await deploy("WordsFun", {
    from: deployer,
    args: [
      '63339909148955487393229205506298531731913104576314227659860317574871770575403',
      libraryColors.address, // Pass the address of the deployed LibraryColors contract
    ],
    log: true,
    autoMine: true,
  });
};

export default deployContracts;

deployContracts.tags = ["LibraryColors", "WordsFun"];