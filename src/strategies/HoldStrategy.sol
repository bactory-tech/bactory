// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BaseStrategy} from "./BaseStrategy.sol";

/// @title HoldStrategy
/// @notice The simplest strategy: it holds what the treasury sends. Useful as a segregated reserve,
///         and as the reference implementation for writing new strategies.
contract HoldStrategy is BaseStrategy {
    constructor(address treasury_) BaseStrategy(treasury_) {}

    function balanceOf(address token) external view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function _deploy(address, uint256) internal override {}

    function _free(address, uint256) internal override {}
}
