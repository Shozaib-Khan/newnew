// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.

pragma solidity ^0.8.24;

// solhint-disable no-inline-assembly,avoid-low-level-calls

import { Errors } from "src/utils/Errors.sol";
import { SSTORE2 } from "src/external/solady/SSTORE2.sol";
import { LibBytes } from "src/external/solady/LibBytes.sol";
import { AutopoolState } from "src/vault/libs/AutopoolState.sol";
import { IStrategyHook } from "src/interfaces/strategy/IStrategyHook.sol";

library AutopoolStrategyHooks {
    /// =====================================================
    /// Hook configurations are read and stored via SSTORE2.
    /// The storage is formatted as fixed length packed byte20(address) arrays
    /// that are themselves packed in the order of the function definitions
    /// on the interface.
    /// For example, lets say we have 3 hooks configured (with 8 functions and 10 hooks supported):
    ///   - Hook 1, address(1), supports onRebalanceStart (1) and onRebalanceFeeProfitHandlingComplete (16)
    ///   - Hook 2, address(2), supports onRebalanceStart (1) and onRebalanceInAssetsReturned (4)
    ///   - Hook 3, address(3), supports onRebalanceComplete (32)
    /// Storage would look like:
    ///   0000000000000000000000000000000000000001 - Start of hooks to call onRebalanceStart() (flag 1) for
    ///   0000000000000000000000000000000000000002
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000 - Hooks to call onRebalanceOutAssetsReady() (flag 2) for
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000002 - Hooks to call onRebalanceInAssetsReturned() (flag 4) for
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000 - Hooks to call onRebalanceDestinationVaultUpdated() (flag 8) for
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000001 - Hooks to call onRebalanceFeeProfitHandlingComplete() (flag 16) for
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000003 - Start of hooks to call onRebalanceComplete() (flag 32) for
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000 - Start of hooks to call onDestinationDebtReport() (flag 64) for
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000 - Start of hooks to call onNavUpdate() (flag 128) for
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000
    ///   0000000000000000000000000000000000000000

    /// Adding hooks should append to the lowest empty of the section
    /// Removing hooks should shift remainder down to maintain order

    /// =====================================================
    /// Constants
    /// =====================================================

    /// @notice Returns maximum number of hooks supported
    uint256 public constant NUM_HOOKS = 10;

    /// @notice Returns the number of hook functions supported
    uint256 public constant NUM_FUNCTIONS = 8;

    /// @notice Max function flag given the number of functions
    uint256 private constant MAX_FN_FLAG = 2 ** NUM_FUNCTIONS;

    /// =====================================================
    /// Errors
    /// =====================================================

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

    /// =====================================================
    /// Structs
    /// =====================================================

    /// @notice Used for view/display purposes
    struct HookConfiguration {
        address[NUM_HOOKS] onRebalanceStart;
        address[NUM_HOOKS] onRebalanceOutAssetsReady;
        address[NUM_HOOKS] onRebalanceInAssetsReturned;
        address[NUM_HOOKS] onRebalanceDestinationVaultUpdated;
        address[NUM_HOOKS] onRebalanceFeeProfitHandlingComplete;
        address[NUM_HOOKS] onRebalanceComplete;
        address[NUM_HOOKS] onDestinationDebtReport;
        address[NUM_HOOKS] onNavUpdate;
    }

    /// =====================================================
    /// Functions - External
    /// =====================================================

    /// @notice Execute all hooks, in order, based on the provided configuration
    /// @dev Caller is responsible for ensuring fnIndex and call are correctly paired
    /// @param hooks Packed hooks configuration data
    /// @param fnIndex Index of the function to execute
    /// @param call Call to make to the hook
    function executeHooks(bytes memory hooks, uint256 fnIndex, bytes memory call) external {
        uint256 hookIx = (fnIndex * NUM_HOOKS * 20) + 32; // 32 for the length of bytes
        uint256 hookEndIx = hookIx + (20 * NUM_HOOKS);

        while (hookIx < hookEndIx) {
            // Pull the bytes out at the index and convert to address
            address addrVal;
            assembly {
                addrVal := shr(96, mload(add(hooks, hookIx)))
            }

            // If its there an address, we execute, otherwise we're done
            if (addrVal != address(0)) {
                (bool result, bytes memory errorData) = addrVal.call(call);
                if (!result) {
                    revert HookExecutionFailed(addrVal, errorData);
                }
            } else {
                break;
            }

            unchecked {
                hookIx += 20;
            }
        }
    }

    /// @notice Add a set of hooks to the Autopools configuration
    /// @param $ Storage data of the calling Autopool
    /// @param newHooks Set of hooks to add to the Autopool
    /// @param configDatas Set of datas to pass to the onRegistered function of the hook
    function addHooks(AutopoolState storage $, IStrategyHook[] memory newHooks, bytes[] memory configDatas) external {
        bytes memory flags = getHookBytes($);

        uint256 len = newHooks.length;
        Errors.verifyNotZero(len, "len");
        Errors.verifyArrayLengths(len, configDatas.length, "ars");

        for (uint256 i = 0; i < len;) {
            flags = _addHook(flags, newHooks[i], configDatas[i]);

            unchecked {
                ++i;
            }
        }

        $.hookStore = SSTORE2.write(flags);
    }

    /// @notice Remove a hook from the Autopools configuration
    /// @param $ Storage data of the calling Autopool
    /// @param hookToRemove Hook to remove from to the Autopool
    /// @param cleanupData Data to pass to the onUnregistered function of the hook
    function removeHook(AutopoolState storage $, IStrategyHook hookToRemove, bytes calldata cleanupData) external {
        Errors.verifyNotZero(address(hookToRemove), "hookToRemove");

        bytes memory flags;

        address hookStorage = $.hookStore;
        if (hookStorage != address(0)) {
            flags = SSTORE2.read(hookStorage);
        } else {
            revert HookNotSet(address(hookToRemove));
        }

        // We are OK with assumption that supported flags can't change between
        // register and unregister
        uint8 supportedHookFunctions = hookToRemove.getFnFlags();
        Errors.verifyNotZero(supportedHookFunctions, "supportedHookFunctions");
        uint256 fnToCheck = 1;

        bytes memory newFlagsData;
        uint256 bytesIndex = 0;

        // Loop over all the functions hook slots
        // build our replacement storage data, newFlagsData
        // Replace the address with empty where needed
        bytes memory empty = hex"0000000000000000000000000000000000000000";

        while (fnToCheck < MAX_FN_FLAG) {
            uint256 hookIx = 0;
            bool needToRemove = supportedHookFunctions & fnToCheck == fnToCheck;
            bool removed = false;

            while (hookIx < NUM_HOOKS) {
                // Get our existing value
                address addrVal;
                {
                    bytes memory val = LibBytes.slice(flags, bytesIndex, bytesIndex + 20);
                    assembly {
                        addrVal := shr(96, mload(add(val, 32)))
                    }
                }
                if (addrVal == address(hookToRemove)) {
                    // Don't put anything in its spot so that the remaining
                    // values will shift down. We'll tack an empty onto the end
                    removed = true;
                } else {
                    // Not the value we're looking for, forward it on
                    newFlagsData = LibBytes.concat(newFlagsData, abi.encodePacked(addrVal));
                }

                unchecked {
                    ++hookIx;
                    bytesIndex += 20;
                }
            }

            if (needToRemove && !removed) {
                revert FunctionNotSet(address(hookToRemove), fnToCheck);
            }

            // We don't support duplicates so we know it was only in once
            // We will revert if didn't remove, so we know we removed one item
            // Add an empty onto the end in its place
            if (removed) {
                newFlagsData = LibBytes.concat(newFlagsData, empty);
            }

            unchecked {
                fnToCheck *= 2;
            }
        }

        // We removed it so run the cleanup
        hookToRemove.onUnregistered(cleanupData);

        $.hookStore = SSTORE2.write(newFlagsData);
    }

    /// @notice Get hooks in a proper format
    /// @dev Do not use in any executing code
    /// @param $ Storage data of the calling Autopool
    function getHooks(
        AutopoolState storage $
    ) external view returns (HookConfiguration memory) {
        bytes memory flags = getHookBytes($);

        uint256 memSize = NUM_HOOKS * NUM_FUNCTIONS * 32;
        assembly {
            // Get our working space for building the struct
            let structPtr := mload(0x40)

            // Update pointer to new position
            mstore(0x40, add(structPtr, memSize))

            // Get the store of our addresses, first 32 is array size
            let dataPtr := add(flags, 32)
            let dataEnd := add(dataPtr, mload(flags))
            let offset := 0

            // Loop our data and set the addresses
            for { } lt(dataPtr, dataEnd) { } {
                let word := mload(dataPtr)

                // Convert to address
                word := shr(96, word)

                // Add address to struct
                mstore(add(structPtr, offset), word)

                // Increment our counters
                dataPtr := add(dataPtr, 20)
                offset := add(offset, 32)
            }

            return(structPtr, memSize)
        }
    }

    /// =====================================================
    /// Functions - Public
    /// =====================================================

    /// @notice Get hooks in a proper format
    /// @dev Do not use in any executing code
    /// @param $ Storage data of the calling Autopool
    function getHookBytes(
        AutopoolState storage $
    ) public view returns (bytes memory) {
        bytes memory flags;

        address hookStorage = $.hookStore;
        if (hookStorage != address(0)) {
            flags = SSTORE2.read(hookStorage);
        } else {
            // If we haven't set any data initialize the array
            // to all empty addresses
            flags = new bytes(NUM_HOOKS * NUM_FUNCTIONS * 20);
        }

        return flags;
    }

    /// =====================================================
    /// Functions - Private
    /// =====================================================

    /// @notice Add a hook to the Autopools configuration
    /// @param flags Existing hook data
    /// @param newHook Hook to add to the Autopool
    /// @param configData Data to pass to the onRegistered function of the hook
    /// @return New flags configuration storage data
    function _addHook(
        bytes memory flags,
        IStrategyHook newHook,
        bytes memory configData
    ) private returns (bytes memory) {
        Errors.verifyNotZero(address(newHook), "newHook");

        uint8 supportedHookFunctions = newHook.getFnFlags();
        Errors.verifyNotZero(supportedHookFunctions, "supportedHookFunctions");
        uint256 fnToCheck = 1;

        bytes memory newFlagsData;
        uint256 bytesIndex = 0;

        // Loop over all the functions hook slots and
        // build our replacement storage data, newFlagsData
        // Splice in our new values where we need
        while (fnToCheck < MAX_FN_FLAG) {
            uint256 hookIx = 0;
            bool needToSet = supportedHookFunctions & fnToCheck == fnToCheck;
            bool set = false;
            while (hookIx < NUM_HOOKS) {
                // Get our existing value
                bytes memory val = LibBytes.slice(flags, bytesIndex, bytesIndex + 20);

                if (needToSet && !set) {
                    address addrVal;
                    assembly {
                        addrVal := shr(96, mload(add(val, 32)))
                    }

                    if (addrVal == address(newHook)) {
                        revert HookAlreadySet(addrVal, fnToCheck);
                    } else if (addrVal == address(0)) {
                        // If the space is empty we can use it
                        set = true;
                        newFlagsData = LibBytes.concat(newFlagsData, abi.encodePacked(newHook));
                    } else {
                        // Space isn't empty so forward the existing value
                        newFlagsData = LibBytes.concat(newFlagsData, val);
                    }
                } else {
                    // We don't need to set, or already set, so just forward the current value
                    newFlagsData = LibBytes.concat(newFlagsData, val);
                }

                unchecked {
                    ++hookIx;
                    bytesIndex += 20;
                }
            }

            if (needToSet && !set) {
                // We needed to configure the hook but couldn't. Means we couldn't find
                // a spot which implies we have the maximum number already configured
                revert MaxHooksSet();
            }

            unchecked {
                fnToCheck *= 2;
            }
        }

        // We were able to add it to the config, so set it up
        newHook.onRegistered(configData);

        return newFlagsData;
    }
}