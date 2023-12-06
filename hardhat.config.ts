import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  namedAccounts: {
    deployer: 0,
  },
  networks: {
    mumbai: {
      url: `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_TOKEN}`,
      chainId: 80001,
      accounts: [process.env.TESTNET_DEPLOY_KEY || ""],
      tags: ["bsc-testnet"]
    },
    fuji: {
      url: `https://avalanche-fuji.infura.io/v3/${process.env.INFURA_TOKEN}`,
      chainId: 43113,
      accounts: [process.env.TESTNET_DEPLOY_KEY || ""],
      tags: ["bsc-testnet"]
    },
  }
};

export default config;
