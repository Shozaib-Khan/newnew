// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2025 Tokemak Foundation. All rights reserved.
pragma solidity ^0.8.24;

import { AutopoolDebt } from "src/vault/libs/AutopoolDebt.sol";
import { ProcessRebalanceParams } from "src/vault/libs/AutopoolState.sol";

// @dev Do not change the order of these, we rely on the index
enum HookFunctionIndex {
    onRebalanceStart,
    onRebalanceOutAssetsReady,
    onRebalanceInAssetsReturned,
    onRebalanceDestinationVaultUpdated,
    onRebalanceFeeProfitHandlingComplete,
    onRebalanceComplete,
    onDestinationDebtReport,
    onNavUpdate
}

interface IStrategyHook {
    /// @notice Returns the flags that represent the functions to call on this hook
    function getFnFlags() external view returns (uint8);

    /// @notice Fires when the hook has been registered with an Autopool
    /// @param registrationData Any data needed during registration such as initial configuration
    function onRegistered(
        bytes memory registrationData
    ) external;

    /// @notice Fires when the hook as been unregistered with an Autopool
    /// @param cleanupData Any information needed to run cleanup operations
    function onUnregistered(
        bytes memory cleanupData
    ) external;

    /// =====================================================
    /// Rebalance Flow
    /// - Functions are defined in the order that they fire
    /// - Any function may revert to stop a rebalance
    /// - OnNavUpdate interjects at the end
    /// =====================================================

    /// Flag 1
    /// @notice Fires at the start of a rebalance before any assets are moved
    /// @dev No LP/Idle changes have occurred yet
    /// @param params Rebalance parameters
    /// @param solverCaller Solver who initiated the rebalance
    function onRebalanceStart(ProcessRebalanceParams calldata params, address solverCaller) external;

    /// Flag 2
    /// @notice Fires when LP has been removed from a DestinationVault but before solver has control
    /// @param params Rebalance parameters
    /// @param solverCaller Solver who initiated the rebalance
    /// @dev When this is an idle-out, the state of assets between here and Start() is the same
    function onRebalanceOutAssetsReady(ProcessRebalanceParams calldata params, address solverCaller) external;

    /// Flag 4
    /// @notice Fires when LP/Idle has been returned from the Solver
    /// @param params Rebalance parameters
    /// @param solverCaller Solver who initiated the rebalance
    /// @dev Solver has performed all market operations at this point
    function onRebalanceInAssetsReturned(ProcessRebalanceParams calldata params, address solverCaller) external;

    /// Flag 8
    /// @notice Fires after assets have been deposited into DestinationVault
    /// @param params Rebalance parameters
    /// @param solverCaller Solver who initiated the rebalance
    /// @dev When this is an idle-in, the state of assets doesn't change between InAssetsReturned() and here
    function onRebalanceDestinationVaultUpdated(
        ProcessRebalanceParams calldata params,
        address solverCaller
    ) external;

    /// Flag 16
    /// @notice Fires after any fee and profit handling has occurred
    /// @param params Rebalance parameters
    /// @param solverCaller Solver who initiated the rebalance
    /// @dev Autopool totalSupply() should be steady at this point
    function onRebalanceFeeProfitHandlingComplete(
        ProcessRebalanceParams calldata params,
        address solverCaller
    ) external;

    /// Flag 32
    /// @notice Fires at the end of the rebalance
    /// @param params Rebalance parameters
    /// @param solverCaller Solver who initiated the rebalance
    function onRebalanceComplete(ProcessRebalanceParams calldata params, address solverCaller) external;

    /// =====================================================
    /// Debt Reporting
    /// - Functions should not revert
    /// =====================================================

    /// Flag 64
    /// @notice Fires for any custom tracking of debt valuations
    /// @dev Autopool has possession of auto-compounded rewards
    /// @param destination Target DestinationVault address
    /// @param debtResult Change in values due to debt reporting
    function onDestinationDebtReport(address destination, AutopoolDebt.IdleDebtUpdates memory debtResult) external;

    /// =====================================================
    /// Nav Updates
    /// - Functions should not revert
    /// =====================================================

    /// Flag 128
    /// @notice Fires after any nav update
    /// @param assetChanges New and old assets and totalSupply
    /// @dev Also fires immediately before onRebalanceFeeProfitHandlingComplete()
    function onNavUpdate(
        AutopoolDebt.AssetChanges memory assetChanges
    ) external;
}