// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BactoryErrors
/// @notice Custom errors shared across the protocol.
library BactoryErrors {
    error ZeroAddress();
    error NotAContract(address account);
    error SameAssetAndQuote();
    error QuoteNotAllowed(address quote);
    error MarketExists(address market);
    error NotAMarket(address caller);
    error NotMarketAdmin(address caller);
    error NotPendingAdmin(address caller);
    error NotAuthorized(address caller);
    error ModuleNotAvailable(uint8 id);
    error ModuleAlreadyActive(uint8 id);
    error ModuleNotActive(uint8 id);
    error InvalidFeeSplit(uint256 totalBps);
    error LimitTooHigh(uint256 value, uint256 max);
    error ZeroAmount();
    error MarketPaused();
    error StrategyNotApproved(address strategy);
    error ExceedsActionLimit(uint256 amount, uint256 limit);
    error BreaksReserve(uint256 idleAfter, uint256 reserveRequired);
    error InsufficientAllocation(uint256 requested, uint256 allocated);
    error LengthMismatch();
    error NotTreasury(address caller);
}
