// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.

pragma solidity ^0.8.24;

// solhint-disable no-inline-assembly

import { IAutopool } from "src/interfaces/vault/IAutopool.sol";
import { EnumerableSet } from "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import { AutopoolDebt } from "src/vault/libs/AutopoolDebt.sol";
import { StructuredLinkedList } from "src/strategy/StructuredLinkedList.sol";
import { AutopoolToken } from "src/vault/libs/AutopoolToken.sol";
import { IMainRewarder } from "src/interfaces/rewarders/IMainRewarder.sol";
import { IERC20Metadata } from "openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC3156FlashBorrower } from "openzeppelin-contracts/interfaces/IERC3156FlashBorrower.sol";
import { IStrategy } from "src/interfaces/strategy/IStrategy.sol";

struct AutopoolState {
    /// @notice Balances, allowances, and supply for the pool
    /// @dev Want to keep this var in this position
    AutopoolToken.TokenData token;
    /// @notice Full list of possible destinations that could be deployed to
    /// @dev Exposed via `getDestinations()`
    EnumerableSet.AddressSet destinations;
    /// @notice Destinations that are queued for removal
    /// @dev Exposed via `getRemovalQueue`
    EnumerableSet.AddressSet removalQueue;
    /// @notice Whether or not the vault has been shutdown
    /// @dev Exposed via `isShutdown()`
    bool shutdown;
    /// @notice Reason for shutdown (or `Active` if not shutdown)
    /// @dev Exposed via `shutdownStatus()`
    IAutopool.VaultShutdownStatus shutdownStatus;
    /// @notice Lookup of destinationVaultAddress -> Info .. Debt reporting snapshot info
    /// @dev Exposed via `getDestinationInfo`
    mapping(address => AutopoolDebt.DestinationInfo) destinationInfo;
    /// @notice Ordered list of destinations to withdraw from
    /// @dev Exposed via `getWithdrawalQueue()`
    StructuredLinkedList.List withdrawalQueue;
    /// @notice Ordered list of destinations to debt report on. Ordered from oldest to newest
    /// @dev Exposed via `getDebtReportingQueue()`
    StructuredLinkedList.List debtReportQueue;
    /// @notice State and settings related to gradual profit unlock
    /// @dev Exposed via `getProfitUnlockSettings()`
    IAutopool.ProfitUnlockSettings profitUnlockSettings;
    /// @notice State and settings related to periodic and streaming fees
    /// @dev Exposed via `getFeeSettings()`
    IAutopool.AutopoolFeeSettings feeSettings;
    /// @notice Rewarders that have been replaced.
    /// @dev Exposed via `isPastRewarder()`
    EnumerableSet.AddressSet pastRewarders;
    /// @notice Main rewarder for this contract
    IMainRewarder rewarder;
    /// @notice Pool/token name
    string name;
    /// @notice Pool/token symbol
    string symbol;
    /// @notice Storage address of hook configurations
    address hookStore;
    /// @notice Factory contract that created this vault
    address factory;
    /// @notice Asset tracking for idle and debt values
    /// @dev Exposed via `getAssetBreakdown()`
    IAutopool.AssetBreakdown assetBreakdown;
}

struct ProcessRebalanceParams {
    IERC20Metadata baseAsset;
    IERC3156FlashBorrower receiver;
    IStrategy.RebalanceParams rebalanceParams;
}

library AutopoolStorage {
    // keccak256(abi.encode(uint256(keccak256("autopilot.storage.AutopoolState")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SLOT = 0x17264fbcd79a365fd3ccff89407ad487986f8b37b9035d6bc8b51cacd5832200;

    function load() internal pure returns (AutopoolState storage $) {
        assembly {
            $.slot := SLOT
        }
    }
}