// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IStrategy
/// @notice A place a treasury can deploy capital. Only the treasury that owns it can move funds.
interface IStrategy {
    /// @notice Called by the treasury after it transferred `amount` of `token` to the strategy.
    function onDeposit(address token, uint256 amount) external;

    /// @notice Sends `amount` of `token` back to the treasury.
    function withdraw(address token, uint256 amount) external;

    /// @notice Value the strategy holds for the treasury, in `token`.
    function balanceOf(address token) external view returns (uint256);

    function treasury() external view returns (address);
}
