require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1,
      mining: {
        auto: true,
      },
      gasPrice: 0,
      initialBaseFeePerGas: 0,
      accounts: {
        mnemonic: "swap swap swap swap swap swap swap swap swap swap swap swap"
      },
    },
  },
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  mocha: {
    timeout: 600000
  },
};
