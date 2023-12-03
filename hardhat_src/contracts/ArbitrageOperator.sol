//SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.9;

import "hardhat/console.sol";
// ----------------------INTERFACE------------------------------

// ----------------------UNISWAPV2------------------------------

// https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IERC20.sol
// https://docs.uniswap.org/protocol/V2/reference/smart-contracts/Pair-ERC-20
interface IERC20 {
    // Returns the account balance of another account with address _owner.
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Allows _spender to withdraw from your account multiple times, up to the _value amount.
     * If this function is called again it overwrites the current allowance with _value.
     * Lets msg.sender set their allowance for a spender.
     **/
    function approve(address spender, uint256 value) external; // return type is deleted to be compatible with USDT

    /**
     * Transfers _value amount of tokens to address _to, and MUST fire the Transfer event.
     * The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
     * Lets msg.sender send pool tokens to an address.
     **/
    function transfer(address to, uint256 value) external returns (bool);
}

// https://github.com/Uniswap/v2-periphery/blob/master/contracts/interfaces/IWETH.sol
interface IWETH is IERC20 {
    // Convert the wrapped token back to Ether.
    function withdraw(uint256) external;
    function deposit() external payable;
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
  external
  returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    // Returns the address of the pair for tokenA and tokenB, if it has been created, else address(0).
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Pair {
    /**
     * Swaps tokens. For regular swaps, data.length must be 0.
     * Also see [Flash Swaps](https://docs.uniswap.org/protocol/V2/concepts/core-concepts/flash-swaps).
     **/
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    /**
     * Returns the reserves of token0 and token1 used to price trades and distribute liquidity.
     * See Pricing[https://docs.uniswap.org/protocol/V2/concepts/advanced-topics/pricing].
     * Also returns the block.timestamp (mod 2**32) of the last block during which an interaction occured for the pair.
     **/
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// ----------------------BANCOR------------------------------
// interface Token {
//     function approve(address spender, uint256 value) external; // return type is deleted to be compatible with USDT
//     function balanceOf(address owner) external view returns (uint256);
//     function transfer(address to, uint256 value) external returns (bool);
// }

// https://docs.bancor.network/developer-quick-start/trading-with-bancor#trading-from-your-smart-contract
// https://app.bancor.network/eth/swap?from=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE&to=0xF35cCfbcE1228014F66809EDaFCDB836BFE388f5
// https://ropsten.etherscan.io/tx/0x21b95960b1a7c832c91e705390420edf3faa35b18469a8bc517056d88af9634e
// interface IPoolCollection{
//      /**
//      * @dev returns whether depositing is enabled
//      */
//     function depositingEnabled(Token pool) external view returns (bool);
// }
// interface IBancorNetwork {
//     function tradeBySourceAmount(
//         Token sourceToken,
//         Token targetToken,
//         uint256 sourceAmount,
//         uint256 minReturnAmount,
//         uint256 deadline,
//         address beneficiary
//     ) external payable returns (uint256);

//     /**
//      * @dev returns the respective pool collection for the provided pool
//      */
//     function collectionByPool(Token pool) external view returns (IPoolCollection);

//     // function collectionByPool(Token pool) external view returns (IPoolCollection);
//     // function convert2(
//     //     IERC20[] calldata _path,
//     //     uint256 _amount,
//     //     uint256 _minReturn,
//     //     address _affiliateAccount,
//     //     uint256 _affiliateFee
//     // ) external payable returns (uint256);
// }
// interface IVersioned {
//     function version() external view returns (uint16);
// }

// interface IAccessControlUpgradeable {

// }
// interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {

// }
// interface IUpgradeable is IAccessControlEnumerableUpgradeable, IVersioned {

// }

// interface IBancorNetworkInfo is IUpgradeable {
//     function tradeOutputBySourceAmount(
//         Token sourceToken,
//         Token targetToken,
//         uint256 sourceAmount
//     ) external view returns (uint256);

//     function tradingEnabled(Token pool) external view returns (bool);
//     function network() external view returns (IBancorNetwork);
// }

// ----------------------IMPLEMENTATION------------------------------

contract ArbitrageOperator{

    IWETH public weth;
    // Token public bnt;
    IUniswapV2Router02 uniswapRouter;
    IUniswapV2Factory uniswapFactory;
    // IBancorNetwork bancorNetwork;
    // IBancorNetworkInfo bancorNetworkInfo;
    address my_account;
    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address public constant BNT_ADDR = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C; 
    address public constant UNISWAPROUTER_ADDR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant BANCOR_ADDR = 0xE0CB1BEb84b3289B946Ac7Fa067f4c44AdFFA4Fb;
    address public constant BANCOR_NETINFO_ADDR = 0xFD47C74A8030520BACd364FB8e08ACB28766aE7b;
    address public constant UNISWAPFACTORY_ADDR = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    // END TODO

    // some helper function, it is totally fine if you can finish the lab without using these function
    // https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // safe mul is not necessary since https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }


    // some helper function, it is totally fine if you can finish the lab without using these function
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // safe mul is not necessary since https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    constructor() {
        // TODO: (optional) initialize your contract
        my_account = msg.sender;
        uniswapRouter = IUniswapV2Router02(UNISWAPROUTER_ADDR);
        uniswapFactory = IUniswapV2Factory(UNISWAPFACTORY_ADDR);
        weth = IWETH(WETH_ADDR);
        // END TODO
    }

    // TODO: add a `receive` function so that you can withdraw your WETH
    receive() external payable {
    } 
    // END TODO

    function wrapEther() external payable {
        uint256 balanceBefore = weth.balanceOf(address(this));
        uint256 ETHAmount = msg.value;
        // console.log("ETH: ", ETHAmount);

        //create WETH from ETH
        if (ETHAmount != 0) {
            weth.deposit{ value: ETHAmount }();
            weth.transfer(address(this), ETHAmount);
        }
        require(
            weth.balanceOf(address(this)) - balanceBefore == ETHAmount,
            "Ethereum not deposited"
        );
    }

    function isStringSmaller(string memory str1, string memory str2) public pure returns (bool) {
        bytes memory str1Bytes = bytes(str1);
        bytes memory str2Bytes = bytes(str2);

        uint minLength = str1Bytes.length;
        if (str2Bytes.length < minLength) {
            minLength = str2Bytes.length;
        }

        for (uint i = 0; i < minLength; i++) {
            if (str1Bytes[i] < str2Bytes[i]) {
                return true;
            } else if (str1Bytes[i] > str2Bytes[i]) {
                return false;
            }
        }

        return str1Bytes.length < str2Bytes.length;
    }

    function uniswap_txn(address[] calldata path, string[] calldata tokens, uint index) public payable{
        address[] memory address_path = new address[](2);
        address_path[0] = path[index];
        address_path[1] = path[index+1];

        uint256 srcBalance = IERC20(address_path[0]).balanceOf(address(this));
        IERC20(address_path[0]).approve(address(uniswapRouter), (2**256)-1);

        address token0;
        address token1;

        string memory token0_symbol;
        string memory token1_symbol;

        IUniswapV2Pair currPair = IUniswapV2Pair(uniswapFactory.getPair(path[index], path[index+1]));
        IERC20(path[index]).approve(address(currPair), (2**256)-1);

        (uint112 reserve0,uint112 reserve1,) = currPair.getReserves();

        if(isStringSmaller(tokens[index], tokens[index+1])) {
            token0 = path[index];
            token1 = path[index+1];

            token0_symbol = tokens[index];
            token1_symbol = tokens[index+1];

            uint256 calcOut = getAmountOut(srcBalance, reserve0, reserve1);

            console.log("Exchange between", token0_symbol, "->", token1_symbol);

            IERC20(token0).transfer(address(currPair), srcBalance);
            currPair.swap(0, calcOut, address(this), "");

            uint256 currBalance = IERC20(token1).balanceOf(address(this));
            console.log(srcBalance, "of", token0_symbol);
            console.log("Exchange To");
            console.log(currBalance, "of", token1_symbol, "\n");
        }   
        else {
            token0 = path[index+1];
            token1 = path[index];

            token0_symbol = tokens[index+1];
            token1_symbol = tokens[index];

            uint256 calcOut = getAmountOut(srcBalance, reserve1, reserve0);
            console.log("Exchange between", token1_symbol, "->", token0_symbol);

            IERC20(token1).transfer(address(currPair), srcBalance);
            currPair.swap(calcOut, 0, address(this), "");

            uint256 currBalance = IERC20(token0).balanceOf(address(this));
            console.log(srcBalance, "of", token1_symbol);
            console.log("Exchange To");
            console.log(currBalance, "of", token0_symbol, "\n");
        }
    }

    // required by the testing script, entry for your liquidation call
    function operate(address[] calldata path, string[] calldata tokens) external payable {

        uint256 amountIn = weth.balanceOf(address(this));
        // console.log("MSG VALUE", msg.value);
        console.log("Block", block.timestamp, "\n");
        console.log("========================================================================================");
        console.log("Start Arbitrage: \n");
        for (uint i = 0; i<path.length-1; i++) {
            console.log("UNISWAP_TRADE STEP: ", i+1);
            uniswap_txn(path, tokens, i);
        }
        console.log("End of Arbitrage");
        console.log("========================================================================================");
        uint256 profit = weth.balanceOf(address(this)) - amountIn;
        console.log("Profit: ", profit, "WETH");
    }
}