const axios = require('axios');
const hre = require("hardhat");
const { expect } = require("chai");
const { string } = require('hardhat/internal/core/params/argumentTypes');
const ethers = hre.ethers;
require('dotenv').config();

describe("Arbitrage", function () {
  let optimal_address_path = []
  let optimal_token_path = []
  // let balance_in_wallet = 0;

  it("Reset Network and Initialize Account", async function() {
    await network.provider.request({
      method: "hardhat_reset",
      params: [{
        forking: {
          jsonRpcUrl: process.env.API_KEY,
          blockNumber: 12489619,
        }
      }]
    });
  })

  it("Get Arbitrage Path from Flask API", async function () {
    const url = 'http://localhost:5000/arbitrage-opportunities'; // Replace with your Flask API URL
    try {
        const response = await axios.get(url);
        console.log('Optimal Arbitrage Path:', response.data.optimal_path);
        console.log('Exchange Ratio:', response.data.exchange_ratio);

        for(const node of response.data.optimal_path) {
          optimal_address_path.push(node[1]);
          optimal_token_path.push(node[0]);
        }
    } catch (error) {
        console.error('Error fetching data:', error);
    }
  })

  it("Simulate Arbitrage Without Spending Real ETH", async function () {
    console.log(optimal_address_path);
    console.log(optimal_token_path);

    // Deploy Arbitrage contract
    const ArbitrageOperator = await ethers.getContractFactory("ArbitrageOperator");
    const arbitrageOperator = await ArbitrageOperator.deploy();
    await arbitrageOperator.deployed();

    // Simulate the arbitrage trade
    await arbitrageOperator.wrapEther({ gasPrice:0, value: ethers.utils.parseEther("0.0001") });
    await arbitrageOperator.operate(optimal_address_path, optimal_token_path, {gasPrice: 0, value: ethers.utils.parseEther("0.0001")});
    // Add assertions to validate the outcome of the arbitrage simulation
    // Example: expect(...).to.equal(...);
  });

})