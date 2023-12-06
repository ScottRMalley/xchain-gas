import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { LZ_ENDPOINTS } from "../constants/endpoints";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const {deployments, getNamedAccounts, network} = hre;
  const {deploy} = deployments;
  const {deployer} = await getNamedAccounts();

  // Constructor arguments
  const PROTOCOL_FEE_DEFAULT: bigint = 50_000_000n;
  const endpoint = LZ_ENDPOINTS[network.name];
  if (!endpoint) {
    throw new Error(`Unknown network ${network.name}`);
  }
  await deploy("GasRelayer", {
    from: deployer,
    args: [endpoint, PROTOCOL_FEE_DEFAULT],
    log: true,
    autoMine: true,
  });
}

func.tags = ["GasRelayer"];
export default func;