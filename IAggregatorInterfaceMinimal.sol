// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAggregatorInterfaceMinimal {
    /// @notice Latest USD price with 8 decimals
    function latestAnswer() external view returns (int256);

    /// @notice Decimals in price
    function decimals() external view returns (uint8);
}