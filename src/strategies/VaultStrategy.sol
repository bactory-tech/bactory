// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {BaseStrategy} from "./BaseStrategy.sol";
import {BactoryErrors} from "../libraries/BactoryErrors.sol";

/// @title VaultStrategy
/// @notice Deposits treasury capital into one ERC-4626 vault (for example a market's own YieldVault,
///         or a lending vault on Base) and redeems it on recall.
contract VaultStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    IERC4626 public immutable vault;

    error WrongToken(address token);

    constructor(address treasury_, address vault_) BaseStrategy(treasury_) {
        if (vault_ == address(0)) revert BactoryErrors.ZeroAddress();
        vault = IERC4626(vault_);
    }

    function balanceOf(address token) external view override returns (uint256) {
        if (token != vault.asset()) return 0;
        return vault.convertToAssets(vault.balanceOf(address(this))) + IERC20(token).balanceOf(address(this));
    }

    function _deploy(address token, uint256 amount) internal override {
        if (token != vault.asset()) revert WrongToken(token);
        IERC20(token).forceApprove(address(vault), amount);
        vault.deposit(amount, address(this));
    }

    function _free(address token, uint256 amount) internal override {
        if (token != vault.asset()) revert WrongToken(token);
        uint256 held = IERC20(token).balanceOf(address(this));
        if (held < amount) vault.withdraw(amount - held, address(this), address(this));
    }
}
