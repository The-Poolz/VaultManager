import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@truffle/dashboard-hardhat-plugin";
import 'solidity-coverage'

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
          version: "0.8.19",
          settings: {
            evmVersion: "istanbul",
            optimizer: {
              enabled: true,
              runs: 200,
            },
          },
      },
    ],
  },
};

export default config;
