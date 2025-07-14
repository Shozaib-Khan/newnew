// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity ^0.8.24;

import { AutopoolDebt } from "src/vault/libs/AutopoolDebt.sol";
import { IERC4626 } from "src/interfaces/vault/IERC4626.sol";
import { Math } from "openzeppelin-contracts/utils/math/Math.sol";
import { IAutopoolStrategy } from "src/interfaces/strategy/IAutopoolStrategy.sol";
import { IMainRewarder } from "src/interfaces/rewarders/IMainRewarder.sol";
import { IERC20Permit } from "openzeppelin-contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import { IStrategy } from "src/interfaces/strategy/IStrategy.sol";

interface IAutopool is IERC4626, IERC20Permit {
    enum VaultShutdownStatus {
        Active,
        Deprecated,
        Exploit
    }

    /// @param unlockPeriodInSeconds Time it takes for profit to unlock in seconds
    /// @param fullProfitUnlockTime Time at which all profit will have been unlocked
    /// @param lastProfitUnlockTime Last time profits were unlocked
    /// @param profitUnlockRate Per second rate at which profit shares unlocks. Rate when calculated is denominated in
    /// MAX_BPS_PROFIT. TODO: Get into uint112
    struct ProfitUnlockSettings {
        uint48 unlockPeriodInSeconds;
        uint48 fullProfitUnlockTime;
        uint48 lastProfitUnlockTime;
        uint256 profitUnlockRate;
    }

    /// @param feeSink Where claimed fees are sent
    /// @param totalAssetsHighMark The last totalAssets amount we took fees at
    /// @param totalAssetsHighMarkTimestamp The last timestamp we updated the high water mark
    /// @param lastPeriodicFeeTake Timestamp of when the last periodic fee was taken.
    /// @param periodicFeeSink Address that receives periodic fee.
    /// @param periodicFeeBps Current periodic fee.  100% == 10000.
    /// @param streamingFeeBps Current streaming fee taken on profit. 100% == 10000
    /// @param navPerShareLastFeeMark The last nav/share height we took fees at
    /// @param navPerShareLastFeeMarkTimestamp The last timestamp we took fees at
    /// @param rebalanceFeeHighWaterMarkEnabled Returns whether the nav/share high water mark is enabled for the
    /// rebalance fee
    struct AutopoolFeeSettings {
        address feeSink;
        uint256 totalAssetsHighMark;
        uint256 totalAssetsHighMarkTimestamp;
        uint256 lastPeriodicFeeTake;
        address periodicFeeSink;
        uint256 periodicFeeBps;
        uint256 streamingFeeBps;
        uint256 navPerShareLastFeeMark;
        uint256 navPerShareLastFeeMarkTimestamp;
        bool rebalanceFeeHighWaterMarkEnabled;
    }

    /// @param totalIdle The amount of baseAsset deposited into the contract pending deployment
    /// @param totalDebt The current (though cached) value of assets we've deployed
    /// @param totalDebtMin The current (though cached) value of assets we use for valuing during deposits
    /// @param totalDebtMax The current (though cached) value of assets we use for valuing during withdrawals
    struct AssetBreakdown {
        uint256 totalIdle;
        uint256 totalDebt;
        uint256 totalDebtMin;
        uint256 totalDebtMax;
    }

    enum TotalAssetPurpose {
        Global,
        Deposit,
        Withdraw
    }

    /* ******************************** */
    /*      Events                      */
    /* ******************************** */

    event RebalanceStarted(address receiver, IStrategy.RebalanceParams rebalanceParams);
    event RebalanceCompleted(AutopoolDebt.AssetChanges updatedAssets);

    // Autopool4626

    // event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event Nav(uint256 idle, uint256 debt, uint256 totalSupply);
    event TokensRecovered(address[] tokens, uint256[] amounts, address[] destinations);
    event Shutdown(IAutopool.VaultShutdownStatus reason);
    event RewarderSet(address newRewarder, address oldRewarder);
    event SymbolAndDescSet(string symbol, string desc);

    // AutopoolDebt

    event DestinationDebtReporting(
        address destination, AutopoolDebt.IdleDebtUpdates debtInfo, uint256 claimed, uint256 claimGasUsed
    );
    event NewNavShareFeeMark(uint256 navPerShare, uint256 timestamp);
    // event Nav(uint256 idle, uint256 debt, uint256 totalSupply);
    // event Withdraw(
    //     address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
    // );

    // AutopoolDestinations

    event DestinationVaultAdded(address destination);
    event DestinationVaultRemoved(address destination);
    event WithdrawalQueueSet(address[] destinations);
    event AddedToRemovalQueue(address destination);
    event RemovedFromRemovalQueue(address destination);

    // AutopoolFees

    event FeeCollected(uint256 fees, address feeSink, uint256 mintedShares, uint256 profit, uint256 totalAssets);
    event PeriodicFeeCollected(uint256 fees, address feeSink, uint256 mintedShares);
    // event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
    event PeriodicFeeSet(uint256 newFee);
    event PeriodicFeeSinkSet(address newPeriodicFeeSink);
    event LastPeriodicFeeTakeSet(uint256 lastPeriodicFeeTake);
    event RebalanceFeeHighWaterMarkEnabledSet(bool enabled);
    // event NewNavShareFeeMark(uint256 navPerShare, uint256 timestamp);
    event NewTotalAssetsHighWatermark(uint256 assets, uint256 timestamp);
    event StreamingFeeSet(uint256 newFee);
    event FeeSinkSet(address newFeeSink);
    event NewProfitUnlockTime(uint48 timeSeconds);

    // AutopoolToken

    /// @dev Emitted when `value` tokens are moved from one account `from` to another `to`.
    //event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}.
    /// `value` is the new allowance.
    // event Approval(address indexed owner, address indexed spender, uint256 value);

    /* ******************************** */
    /*      Errors                      */
    /* ******************************** */

    // Autopool

    error InvalidDecimals();
    error NavOpsInProgress();
    error NavDecreased(uint256 oldNav, uint256 newNav);
    error ValueSharesMismatch(uint256 value, uint256 shares);
    error ERC4626MintExceedsMax(uint256 shares, uint256 maxMint);
    error ERC4626DepositExceedsMax(uint256 assets, uint256 maxDeposit);
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    // Autopool4626

    error InvalidTotalAssetPurpose();
    error InvalidShutdownStatus(IAutopool.VaultShutdownStatus status);
    error RecoveryFailed();

    // AutopoolDestination

    error BaseAssetMismatch(address destinationVault);

    // AutopoolDebt

    error VaultShutdown();
    error WithdrawShareCalcInvalid(uint256 currentShares, uint256 cachedShares);
    //error RebalanceFailed(string message);
    error InvalidPrices();
    //error InvalidTotalAssetPurpose();
    error InvalidDestination(address destination);
    error TooFewAssets(uint256 requested, uint256 actual);
    error SharesAndAssetsReceived(uint256 assets, uint256 shares);
    error AmountExceedsAllowance(uint256 shares, uint256 allowed);
    error PositivePriceRecoupNotCovered(uint256 remaining);
    error InsufficientAssets(address asset);
    error RebalanceDestinationUnderlyerMismatch(address destination, address trueUnderlyer, address providedUnderlyer);
    error OnlyRebalanceToIdleAvailable();
    error UnregisteredDestination(address dest);
    error RebalanceDestinationsMatch();

    // AutopoolFees

    error InvalidFee(uint256 newFee);
    error AlreadySet();
    error DebtReportingStale();

    // AutopoolStrategyHooks

    /// @notice Fires when are at the maximum number of configured hooks for a function
    error MaxHooksSet();

    /// @notice Fires when a hook is already registered for a function
    error HookAlreadySet(address hook, uint256 fn);

    /// @notice Fires on removal when a hook doesn't exist
    error HookNotSet(address hook);

    /// @notice Fires on removal when a function is supposed to be registered but isn't
    error FunctionNotSet(address hook, uint256 fn);

    /// @notice Fires when a hook execution fails
    error HookExecutionFailed(address hook, bytes underlyingError);

    // AutopoolToken

    /// @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
    /// @param sender Address whose tokens are being transferred.
    /// @param balance Current balance for the interacting account.
    /// @param needed Minimum amount required to perform a transfer.
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /// @dev Indicates a failure with the token `sender`. Used in transfers.
    /// @param sender Address whose tokens are being transferred.
    error ERC20InvalidSender(address sender);

    /// @dev Indicates a failure with the token `receiver`. Used in transfers.
    /// @param receiver Address to which tokens are being transferred.
    error ERC20InvalidReceiver(address receiver);

    /// @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
    ///@param spender Address that may be allowed to operate on tokens without being their owner.
    /// @param allowance Amount of tokens a `spender` is allowed to operate with.
    ///@param needed Minimum amount required to perform a transfer.
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /// @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
    /// @param approver Address initiating an approval operation.
    error ERC20InvalidApprover(address approver);

    /// @dev Indicates a failure with the `spender` to be approved. Used in approvals.
    /// @param spender Address that may be allowed to operate on tokens without being their owner.
    error ERC20InvalidSpender(address spender);

    /// @dev Permit deadline has expired.
    error ERC2612ExpiredSignature(uint256 deadline);

    /// @dev Mismatched signature.
    error ERC2612InvalidSigner(address signer, address owner);

    /// @dev The nonce used for an `account` is not the expected current nonce.
    error InvalidAccountNonce(address account, uint256 currentNonce);

    /// @notice A full unit of this pool
    // solhint-disable-next-line func-name-mixedcase
    function ONE() external view returns (uint256);

    /// @notice Amount to pad scaling operations by
    function decimalPad() external view returns (uint256);

    /// @notice Query the type of vault
    function vaultType() external view returns (bytes32);

    /// @notice Strategy governing the pools rebalances
    function autoPoolStrategy() external view returns (IAutopoolStrategy);

    /// @notice Allow token recoverer to collect dust / unintended transfers (non-tracked assets only)
    function recover(address[] calldata tokens, uint256[] calldata amounts, address[] calldata destinations) external;

    /// @notice Set the order of destination vaults used for withdrawals
    // NOTE: will be done going directly to strategy (IStrategy) vault points to.
    //       How it'll delegate is still being decided
    // function setWithdrawalQueue(address[] calldata destinations) external;

    /// @notice Get a list of destination vaults with pending assets to clear out
    function getRemovalQueue() external view returns (address[] memory);

    function getFeeSettings() external view returns (AutopoolFeeSettings memory);

    /// @notice Initiate the shutdown procedures for this vault
    function shutdown(
        VaultShutdownStatus reason
    ) external;

    /// @notice True if the vault has been shutdown
    function isShutdown() external view returns (bool);

    /// @notice Returns the reason for shutdown (or `Active` if not shutdown)
    function shutdownStatus() external view returns (VaultShutdownStatus);

    /// @notice gets the list of supported destination vaults for the Autopool/Strategy
    /// @return _destinations List of supported destination vaults
    function getDestinations() external view returns (address[] memory _destinations);

    function convertToShares(
        uint256 assets,
        uint256 totalAssetsForPurpose,
        uint256 supply,
        Math.Rounding rounding
    ) external view returns (uint256 shares);

    function convertToAssets(
        uint256 shares,
        uint256 totalAssetsForPurpose,
        uint256 supply,
        Math.Rounding rounding
    ) external view returns (uint256 assets);

    function totalAssets(
        TotalAssetPurpose purpose
    ) external view returns (uint256);

    function getAssetBreakdown() external view returns (AssetBreakdown memory);

    /// @notice get a destinations last reported debt value
    /// @param destVault the address of the target destination
    /// @return destinations last reported debt value
    function getDestinationInfo(
        address destVault
    ) external view returns (AutopoolDebt.DestinationInfo memory);

    /// @notice check if a destination is registered with the vault
    function isDestinationRegistered(
        address destination
    ) external view returns (bool);

    /// @notice get if a destinationVault is queued for removal by the AutopoolETH
    function isDestinationQueuedForRemoval(
        address destination
    ) external view returns (bool);

    /// @notice Returns instance of vault rewarder.
    function rewarder() external view returns (IMainRewarder);

    /// @notice Returns boolean telling whether address passed in is past rewarder.
    function isPastRewarder(
        address _pastRewarder
    ) external view returns (bool);

    /// @notice Redeem exact shares proportionally from all destination vaults including idle
    /// @param shares The number of shares to redeem
    /// @param receiver The address to receive the assets
    /// @param owner The address of the owner of the shares to be redeemed
    /// @return assets The number of assets received
    /// @dev This function is used to redeem shares proportionally from all destination vaults including idle
    /// Any sort of recoup or credit is taken into account when redeeming
    // function redeemProrata(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}