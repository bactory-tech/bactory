// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ModuleIds
/// @notice Identifiers for the modules a Bactory market can activate.
/// @dev Liquidity, Bounties and Community are reserved ids: their modules ship in later releases.
library ModuleIds {
    uint8 internal constant TREASURY = 1;
    uint8 internal constant YIELD = 2;
    uint8 internal constant AGENTS = 3;
    uint8 internal constant LIQUIDITY = 4;
    uint8 internal constant BOUNTIES = 5;
    uint8 internal constant COMMUNITY = 6;

    /// @notice True for modules that can be deployed by the current factory.
    function isAvailable(uint8 id) internal pure returns (bool) {
        return id == TREASURY || id == YIELD || id == AGENTS;
    }
}
