// SPDX-License-Identifier:UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.

pragma solidity ^0.8.24;

import { IAutopool } from "src/interfaces/vault/IAutopool.sol";
import { IAggregatorInterfaceMinimal } from "src/interfaces/oracles/IAggregatorInterfaceMinimal.sol";
import { IERC20Metadata as IERC20 } from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract AutopoolChainlinkOracle is IAggregatorInterfaceMinimal {
    /// @notice Returns the Autopool priced by this feed
    IAutopool public immutable autopool;

    /// @notice Returns the address of the Asset/USD Chainlink-compatible oracle feed
    IAggregatorInterfaceMinimal public immutable baseAssetUsdFeed;

    /// @dev Decimals of the asset/usd feed
    uint8 private immutable _baseAssetUsdFeedDecimals;

    /// @dev One unit of the Autopools base asset
    int256 private immutable _autopoolBaseAssetOne;

    constructor(address autopool_, address baseAssetUsdFeed_) {
        autopool = IAutopool(autopool_);
        baseAssetUsdFeed = IAggregatorInterfaceMinimal(baseAssetUsdFeed_);

        _baseAssetUsdFeedDecimals = IAggregatorInterfaceMinimal(baseAssetUsdFeed_).decimals();
        _autopoolBaseAssetOne = int256(10 ** IERC20(IAutopool(autopool_).asset()).decimals());
    }

    /// @notice Latest USD price
    function latestAnswer() external view returns (int256) {
        uint256 assetsPerShare = autopool.convertToAssets(1e18);
        int256 assetUsdPrice = baseAssetUsdFeed.latestAnswer();

        return int256(assetsPerShare) * assetUsdPrice / _autopoolBaseAssetOne;
    }

    /// @notice Decimals in price. Matches decimals of `baseAssetUsdFeed`
    function decimals() external view returns (uint8) {
        return _baseAssetUsdFeedDecimals;
    }
}