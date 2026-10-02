// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IStrategy} from "../interfaces/IStrategy.sol";
import {BactoryErrors} from "../libraries/BactoryErrors.sol";

/// @title BaseStrategy
/// @notice Base for treasury strategies: bound to one treasury, which is the only account that can move funds.
abstract contract BaseStrategy is IStrategy {
    using SafeERC20 for IERC20;

    address public immutable treasury;

    modifier onlyTreasury() {
        if (msg.sender != treasury) revert BactoryErrors.NotTreasury(msg.sender);
        _;
    }

    constructor(address treasury_) {
        if (treasury_ == address(0)) revert BactoryErrors.ZeroAddress();
        treasury = treasury_;
    }

    function onDeposit(address token, uint256 amount) external onlyTreasury {
        _deploy(token, amount);
    }

    function withdraw(address token, uint256 amount) external onlyTreasury {
        _free(token, amount);
        IERC20(token).safeTransfer(treasury, amount);
    }

    function balanceOf(address token) external view virtual returns (uint256);

    /// @dev Put `amount` of `token` (already held by this contract) to work.
    function _deploy(address token, uint256 amount) internal virtual;

    /// @dev Make sure at least `amount` of `token` is held by this contract.
    function _free(address token, uint256 amount) internal virtual;
}
