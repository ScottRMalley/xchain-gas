// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library FeedWhitelist {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Math for uint256;

    struct AddressSet {
        EnumerableSet.AddressSet _whitelist;
        mapping(address => address) _dataFeed;
        address wethPriceFeed;
    }

    function setWETHFeed(AddressSet storage self, address wethPriceFeed_) internal {
        self.wethPriceFeed = wethPriceFeed_;
    }

    function add(AddressSet storage self, address newAsset, address newDataFeed) internal {
        require(newAsset != address(0), "FeedWhitelist: asset cannot be zero address");
        require(newDataFeed != address(0), "FeedWhitelist: dataFeed cannot be zero address");
        require(!self._whitelist.contains(newAsset), "FeedWhitelist: asset already whitelisted");

        self._whitelist.add(newAsset);
        self._dataFeed[newAsset] = newDataFeed;
    }

    function remove(AddressSet storage self, address oldAsset) internal {
        require(self._whitelist.contains(oldAsset), "FeedWhitelist: asset not whitelisted");

        self._whitelist.remove(oldAsset);
        delete self._dataFeed[oldAsset];
    }

    function contains(AddressSet storage self, address maybeAsset) internal view returns (bool) {
        return self._whitelist.contains(maybeAsset);
    }

    function dataFeed(AddressSet storage self, address asset) internal view returns (address) {
        return self._dataFeed[asset];
    }

    function assets(AddressSet storage self) internal view returns (address[] memory) {
        return self._whitelist.values();
    }

    function datafeeds(AddressSet storage self) internal view returns (address[] memory) {
        address[] memory allDatafeeds = new address[](self._whitelist.length());
        for (uint256 i = 0; i < self._whitelist.length(); i++) {
            allDatafeeds[i] = self._dataFeed[self._whitelist.at(i)];
        }
        return allDatafeeds;
    }

    function estimateWETH(AddressSet storage self, address asset, uint256 amount) internal view returns (uint256) {
        require(self._whitelist.contains(asset), "FeedWhitelist: asset not whitelisted");
        require(self._dataFeed[asset] != address(0), "FeedWhitelist: dataFeed not set");

        uint8 assetDecimals = IERC20Metadata(asset).decimals();

        (uint256 quotePrice, uint8 quoteDecimals) = chainlinkPrice(self._dataFeed[asset]);
        (uint256 wethPrice, uint8 wethDecimals) = chainlinkPrice(self.wethPriceFeed);

        // a bit of funky math as we have to take into account different
        // decimal precisions for chainlink prices. Luckily, the native token
        // will always have 18.
        uint256 denominator = wethPrice * (10 ** quoteDecimals) * (10 ** assetDecimals);
        return (quotePrice * (10 ** wethDecimals)).mulDiv(amount * 10 ** 18, denominator);
    }

    function estimateERC20(AddressSet storage self, address asset, uint256 amountWETH) internal view returns (uint256){
        require(self._whitelist.contains(asset), "FeedWhitelist: asset not whitelisted");
        require(self._dataFeed[asset] != address(0), "FeedWhitelist: dataFeed not set");

        uint8 assetDecimals = IERC20Metadata(asset).decimals();

        (uint256 quotePrice, uint8 quoteDecimals) = chainlinkPrice(self._dataFeed[asset]);
        (uint256 wethPrice, uint8 wethDecimals) = chainlinkPrice(self.wethPriceFeed);

        // this should be the reverse estimate of the WETH estimate
        uint256 numerator = amountWETH * wethPrice * (10 ** quoteDecimals) * (10 ** assetDecimals);
        return numerator / (quotePrice * (10 ** wethDecimals) * (10 ** 18));
    }

    function chainlinkPrice(address assetDataFeed) internal view returns (uint256 price, uint8 decimal) {
        (, int256 quotePrice, , ,) = AggregatorV3Interface(assetDataFeed).latestRoundData();
        price = uint256(quotePrice);
        decimal = AggregatorV3Interface(assetDataFeed).decimals();
    }
}