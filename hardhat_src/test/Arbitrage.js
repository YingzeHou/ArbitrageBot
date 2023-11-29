const axios = require('axios');
const hre = require("hardhat");
const { expect } = require("chai");
const { string } = require('hardhat/internal/core/params/argumentTypes');
const ethers = hre.ethers;
require('dotenv').config();

describe("Arbitrage", function () {
  let optimal_address_path = []
  let optimal_token_path = []
  let optimal_path_protocols = []
  // let balance_in_wallet = 0;

  it("Reset Network and Initialize Account", async function() {
    await network.provider.request({
      method: "hardhat_reset",
      params: [{
        forking: {
          jsonRpcUrl: process.env.API_KEY,
          // blockNumber: 12489619,
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
        optimal_path_protocols = response.data.path_protocols;
    } catch (error) {
        console.error('Error fetching data:', error);
    }
  })

  it("Simulate Arbitrage Without Spending Real ETH", async function () {
    // const amount = ethers.utils.parseEther("1.0"); // Example amount
    console.log(optimal_address_path);
    console.log(optimal_token_path);
    // console.log(balance_in_wallet)
    // const start_amount = ethers.utils.parseEther(balance_in_wallet);

    // Deploy Arbitrage contract
    const ArbitrageOperator = await ethers.getContractFactory("ArbitrageOperator");
    const arbitrageOperator = await ArbitrageOperator.deploy();
    await arbitrageOperator.deployed();

    // Simulate the arbitrage trade
    await arbitrageOperator.wrapEther({ value: ethers.utils.parseEther("100") });
    await arbitrageOperator.operate(optimal_address_path, optimal_token_path, optimal_path_protocols, {gasPrice: 0, value: ethers.utils.parseEther("100")});

    // Add assertions to validate the outcome of the arbitrage simulation
    // Example: expect(...).to.equal(...);
  });

})



// const {
//   time,
//   loadFixture,
// } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
// const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
// const { expect } = require("chai");

// describe("Lock", function () {
//   // We define a fixture to reuse the same setup in every test.
//   // We use loadFixture to run this setup once, snapshot that state,
//   // and reset Hardhat Network to that snapshot in every test.
//   async function deployOneYearLockFixture() {
//     const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
//     const ONE_GWEI = 1_000_000_000;

//     const lockedAmount = ONE_GWEI;
//     const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

//     // Contracts are deployed using the first signer/account by default
//     const [owner, otherAccount] = await ethers.getSigners();

//     const Lock = await ethers.getContractFactory("Lock");
//     const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

//     return { lock, unlockTime, lockedAmount, owner, otherAccount };
//   }

//   describe("Deployment", function () {
//     it("Should set the right unlockTime", async function () {
//       const { lock, unlockTime } = await loadFixture(deployOneYearLockFixture);

//       expect(await lock.unlockTime()).to.equal(unlockTime);
//     });

//     it("Should set the right owner", async function () {
//       const { lock, owner } = await loadFixture(deployOneYearLockFixture);

//       expect(await lock.owner()).to.equal(owner.address);
//     });

//     it("Should receive and store the funds to lock", async function () {
//       const { lock, lockedAmount } = await loadFixture(
//         deployOneYearLockFixture
//       );

//       expect(await ethers.provider.getBalance(lock.target)).to.equal(
//         lockedAmount
//       );
//     });

//     it("Should fail if the unlockTime is not in the future", async function () {
//       // We don't use the fixture here because we want a different deployment
//       const latestTime = await time.latest();
//       const Lock = await ethers.getContractFactory("Lock");
//       await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
//         "Unlock time should be in the future"
//       );
//     });
//   });

//   describe("Withdrawals", function () {
//     describe("Validations", function () {
//       it("Should revert with the right error if called too soon", async function () {
//         const { lock } = await loadFixture(deployOneYearLockFixture);

//         await expect(lock.withdraw()).to.be.revertedWith(
//           "You can't withdraw yet"
//         );
//       });

//       it("Should revert with the right error if called from another account", async function () {
//         const { lock, unlockTime, otherAccount } = await loadFixture(
//           deployOneYearLockFixture
//         );

//         // We can increase the time in Hardhat Network
//         await time.increaseTo(unlockTime);

//         // We use lock.connect() to send a transaction from another account
//         await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
//           "You aren't the owner"
//         );
//       });

//       it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
//         const { lock, unlockTime } = await loadFixture(
//           deployOneYearLockFixture
//         );

//         // Transactions are sent using the first signer by default
//         await time.increaseTo(unlockTime);

//         await expect(lock.withdraw()).not.to.be.reverted;
//       });
//     });

//     describe("Events", function () {
//       it("Should emit an event on withdrawals", async function () {
//         const { lock, unlockTime, lockedAmount } = await loadFixture(
//           deployOneYearLockFixture
//         );

//         await time.increaseTo(unlockTime);

//         await expect(lock.withdraw())
//           .to.emit(lock, "Withdrawal")
//           .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
//       });
//     });

//     describe("Transfers", function () {
//       it("Should transfer the funds to the owner", async function () {
//         const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
//           deployOneYearLockFixture
//         );

//         await time.increaseTo(unlockTime);

//         await expect(lock.withdraw()).to.changeEtherBalances(
//           [owner, lock],
//           [lockedAmount, -lockedAmount]
//         );
//       });
//     });
//   });
// });
