//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "hardhat/console.sol";

// ----------------------INTERFACE------------------------------

// UniswapV2

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

interface IUniswapV2Router {
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

// // https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
// // https://docs.uniswap.org/protocol/V2/reference/smart-contracts/factory
// interface IUniswapV2Factory {
//     // Returns the address of the pair for tokenA and tokenB, if it has been created, else address(0).
//     function getPair(address tokenA, address tokenB)
//         external
//         view
//         returns (address pair);
// }

// // https://github.com/Uniswap/v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
// // https://docs.uniswap.org/protocol/V2/reference/smart-contracts/pair
// interface IUniswapV2Pair {
//     /**
//      * Swaps tokens. For regular swaps, data.length must be 0.
//      * Also see [Flash Swaps](https://docs.uniswap.org/protocol/V2/concepts/core-concepts/flash-swaps).
//      **/
//     function swap(
//         uint256 amount0Out,
//         uint256 amount1Out,
//         address to,
//         bytes calldata data
//     ) external;

//     /**
//      * Returns the reserves of token0 and token1 used to price trades and distribute liquidity.
//      * See Pricing[https://docs.uniswap.org/protocol/V2/concepts/advanced-topics/pricing].
//      * Also returns the block.timestamp (mod 2**32) of the last block during which an interaction occured for the pair.
//      **/
//     function getReserves()
//         external
//         view
//         returns (
//             uint112 reserve0,
//             uint112 reserve1,
//             uint32 blockTimestampLast
//         );
// }

// ----------------------IMPLEMENTATION------------------------------

contract ArbitrageOperator{
    uint8 public constant health_factor_decimals = 18;

    // TODO: define constants used in the contract including ERC-20 tokens, Uniswap Pairs, Aave lending pools, etc. */
    // address public constant aave_lending_pool_address = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    // address public constant uniswap_factory_address = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    // address public constant usdt_address = 0xdAC17F958D2ee523a2206206994597C13D831ec7; 
    // address public constant wbtc_address = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599; 
    // address public constant weth_address = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    // address public constant target_user = 0x59CE4a2AC5bC3f5F225439B2993b86B42f6d3e9F;
    // address public constant uniswap_router_address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    IWETH public weth;
    IUniswapV2Router uniswapRouter;
    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; 
    address public constant UNISWAPROUTER_ADDR = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

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
        uniswapRouter = IUniswapV2Router(UNISWAPROUTER_ADDR);
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
        console.log("ETH: ", ETHAmount);
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
    function uniswap_txn(address[] calldata path, string[] calldata tokens, uint index, uint256 amountIn) public payable{
        address[] memory address_path = new address[](2);
        address_path[0] = address(path[index]);
        address_path[1] = address(path[index+1]);

        IERC20(address_path[0]).approve(address(uniswapRouter), (2**256)-1);
        uint[] memory amounts;
        if(address_path[0] == WETH_ADDR) {
            amounts = uniswapRouter.swapExactETHForTokens{value: amountIn}(0, address_path, address(this), block.timestamp+300);
        }
        // if(address_path[1] == WETH_ADDR) {
        //     address TKN = 0xaAAf91D9b90dF800Df4F55c205fd6989c977E73a;
        //     address_path[0] = TKN;
        //     amounts = uniswapRouter.swapExactTokensForETH(IERC20(address_path[0]).balanceOf(address(this)), 0, address_path,  address(this), block.timestamp+300);
        // }

        // console.log(IERC20(address_path[0]).balanceOf(address(this)));
        // console.log(IERC20(address_path[1]).balanceOf(address(this)));
        console.log(tokens[index], "->", tokens[index+1]);
        console.log(IERC20(address_path[0]).balanceOf(address(this)), "->", IERC20(address_path[1]).balanceOf(address(this)));
        // console.log(amounts[0]);

        // console.log(tokens[index+1]);
        // console.log(amounts[1]);
    }
    // required by the testing script, entry for your liquidation call
    function operate(address[] calldata path, string[] calldata tokens, string[] calldata protocols) external payable {

        console.log("Arb Path: ", path[0]);
        console.log("Protocol: ", protocols[0]);
        console.log("My address: ", msg.sender);
        console.log("My balance: ", weth.balanceOf(address(this)));

        uint256 amountIn = weth.balanceOf(address(this));
        // console.log(IWETH(weth_address).balanceOf(my_wallet));
        // uint256 amount = startAmount;

        // IERC20 weth = IERC20(WETH_ADDR);
        // weth.approve(address(uniswapRouter), amountIn);
        // path = path[0:path.length-1];
        // console.log(path[path.length-1]);
        console.log("MSG VALUE", msg.value);
        console.log("Block", block.timestamp);

        for (uint i = 0; i<protocols.length; i++) {
            if(keccak256(abi.encodePacked(protocols[i])) == keccak256(abi.encodePacked("UNISWAP_V2"))) {
                console.log("UNISWAP TRADE");
                uniswap_txn(path, tokens, i, amountIn);
            }
            else{
                console.log("BANCOR TRADE");
            }
        }
        address TKN = 0xaAAf91D9b90dF800Df4F55c205fd6989c977E73a;
        address[] memory address_path = new address[](2);
        address_path[0] = TKN;
        address_path[1] = WETH_ADDR;

        IERC20(address_path[0]).approve(address(uniswapRouter), (2**256)-1);
        uint[] memory amounts = uniswapRouter.swapExactTokensForETH(IERC20(address_path[0]).balanceOf(address(this)), 0, address_path,  address(this), block.timestamp+300);
        console.log("TKN -> WETH");
        console.log(amounts[0], "->", amounts[1]);
    }
}