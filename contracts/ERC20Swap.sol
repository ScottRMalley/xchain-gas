// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

import "./interfaces/IWETH.sol";
import "./libraries/FeedWhitelist.sol";

//*
// This contract is used to swap whitelisted ERC20 tokens to native WETH
//    - The swap is done against Uniswap ASSET/WETH pair
//    - Whitelisted assets require the Chainlink price feed for the ASSET
//*

abstract contract ERC20Swap {
    using FeedWhitelist for FeedWhitelist.AddressSet;
    using Address for address payable;
    using Math for uint256;
    using SafeERC20 for IERC20;

    // internal variables
    FeedWhitelist.AddressSet internal _whitelist;

    // immutable constants
    ISwapRouter public immutable router;
    IWETH public immutable weth;
    uint256 constant public DISCOUNT_DENOMINATOR = 10000;

    // payment variables
    uint24 public constant poolFee = 500; // 0.05% fee (can be configurable depending on how broad the whitelist is)
    uint public maxDiscount;

    constructor(
        ISwapRouter router_,
        IWETH weth_,
        address wethPriceFeed,
        uint256 maxDiscount_
    ) {
        router = router_;
        weth = weth_;
        _whitelist.setWETHFeed(wethPriceFeed);
        maxDiscount = maxDiscount_;
    }

    //*
    // Modifiers
    //*

    modifier onlyWhitelist(address asset) {
        require(_whitelist.contains(asset), "TradeNode: asset must be whitelisted");
        _;
    }

    //*
    // Internal functions
    //*

    /**
     * @dev Swaps ERC20 token to WETH
     * @param asset ERC20 token to swap
     * @param amountOut Amount of ERC20 token to swap
     */
    function _swapExactInToWETH(
        address asset,
        uint256 amountOut
    ) internal returns (uint256){
        // use Chainlink to estimate amountIn
        uint256 amountInMaximum = _maximumAmountIn(asset, amountOut);

        // transfer ERC20 token to this contract
        // note: this contract must be approved to spend ERC20 token
        TransferHelper.safeTransferFrom(asset, msg.sender, address(this), amountInMaximum);
        TransferHelper.safeApprove(asset, address(router), amountInMaximum);

        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: abi.encodePacked(asset, poolFee, weth),
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: amountOut,
            amountInMaximum: amountInMaximum
        });

        // perform swap
        uint256 amountIn = router.exactOutput(params);

        //if the swap did not require the full amountInMaximum, refund the difference
        if (amountIn < amountInMaximum) {
            TransferHelper.safeTransfer(asset, msg.sender, amountInMaximum - amountIn);
            TransferHelper.safeApprove(asset, address(router), 0);
        }

        // unwrap WETH
        weth.withdraw(amountOut);

        return amountIn;
    }

    function _maximumAmountIn(address asset, uint256 wethOut) internal view returns (uint256) {
        return _whitelist.estimateERC20(asset, wethOut) * (DISCOUNT_DENOMINATOR + maxDiscount) / DISCOUNT_DENOMINATOR;
    }

    //*
    // Whitelist functions
    //*

    function getWhitelist() external view returns (address[] memory) {
        return _whitelist.assets();
    }

    function getDatafeeds() external view returns (address[] memory) {
        return _whitelist.datafeeds();
    }

    function _addToWhitelist(address asset, address datafeed) internal {
        _whitelist.add(asset, datafeed);
    }

    function _removeFromWhitelist(address asset) internal {
        _whitelist.remove(asset);
    }

    function _setMaxDiscount(uint256 discount) internal {
        maxDiscount = discount;
    }

}