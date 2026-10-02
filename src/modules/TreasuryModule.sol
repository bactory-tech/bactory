// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {MarketModule} from "./MarketModule.sol";
import {ITreasuryModule} from "../interfaces/ITreasuryModule.sol";
import {IStrategy} from "../interfaces/IStrategy.sol";
import {IMarket} from "../interfaces/IMarket.sol";
import {BactoryErrors} from "../libraries/BactoryErrors.sol";
import {ModuleIds} from "../libraries/ModuleIds.sol";
import {Bps} from "../libraries/Bps.sol";

/// @title TreasuryModule
/// @notice Holds market-owned capital and deploys it only into approved strategies, inside the market's limits.
/// @dev Two parties can move capital: the market admin, and the market's active AgentGuard
///      (which has already checked the agent's proposal). Both go through the same limits.
contract TreasuryModule is ITreasuryModule, MarketModule, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    mapping(address strategy => bool) public isApproved;
    mapping(address strategy => mapping(address token => uint256)) public allocated;
    mapping(address token => uint256) public totalAllocated;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address market_) external initializer {
        __MarketModule_init(market_);
        __ReentrancyGuard_init();
    }

    function market() public view override(ITreasuryModule, MarketModule) returns (address) {
        return address(_market);
    }

    modifier onlyAdminOrGuard() {
        bool isGuard = _market.isActive(ModuleIds.AGENTS) && msg.sender == _market.moduleOf(ModuleIds.AGENTS);
        if (msg.sender != _market.admin() && !isGuard) revert BactoryErrors.NotAuthorized(msg.sender);
        _;
    }

    // ---------------------------------------------------------------- views

    /// @inheritdoc ITreasuryModule
    function idle(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /// @inheritdoc ITreasuryModule
    function totalValue(address token) public view returns (uint256) {
        return idle(token) + totalAllocated[token];
    }

    /// @inheritdoc ITreasuryModule
    /// @dev The most one action may move: `maxActionBps` of the token's total value.
    function actionLimit(address token) public view returns (uint256) {
        return Bps.mul(totalValue(token), _market.config().maxActionBps);
    }

    /// @notice Idle balance that must remain after an allocation: `reserveBps` of total value.
    function reserveRequired(address token) public view returns (uint256) {
        return Bps.mul(totalValue(token), _market.config().reserveBps);
    }

    // ---------------------------------------------------------------- strategy moves

    /// @inheritdoc ITreasuryModule
    function approveStrategy(address strategy, bool approved) external onlyMarketAdmin {
        if (strategy == address(0)) revert BactoryErrors.ZeroAddress();
        isApproved[strategy] = approved;
        emit StrategyApproved(strategy, approved);
    }

    /// @inheritdoc ITreasuryModule
    function allocate(address strategy, address token, uint256 amount)
        external
        nonReentrant
        onlyAdminOrGuard
        whenMarketLive
    {
        if (amount == 0) revert BactoryErrors.ZeroAmount();
        if (!isApproved[strategy]) revert BactoryErrors.StrategyNotApproved(strategy);
        uint256 limit = actionLimit(token);
        if (amount > limit) revert BactoryErrors.ExceedsActionLimit(amount, limit);
        uint256 reserve = reserveRequired(token);
        uint256 idleNow = idle(token);
        uint256 idleAfter = idleNow > amount ? idleNow - amount : 0;
        if (idleAfter < reserve || amount > idleNow) revert BactoryErrors.BreaksReserve(idleAfter, reserve);

        allocated[strategy][token] += amount;
        totalAllocated[token] += amount;
        IERC20(token).safeTransfer(strategy, amount);
        IStrategy(strategy).onDeposit(token, amount);
        emit Allocated(strategy, token, amount, msg.sender);
    }

    /// @inheritdoc ITreasuryModule
    /// @dev Recalling capital back to the treasury is always allowed, even while the market is paused.
    function recall(address strategy, address token, uint256 amount) external nonReentrant onlyAdminOrGuard {
        if (amount == 0) revert BactoryErrors.ZeroAmount();
        uint256 current = allocated[strategy][token];
        if (amount > current) revert BactoryErrors.InsufficientAllocation(amount, current);

        allocated[strategy][token] = current - amount;
        totalAllocated[token] -= amount;
        IStrategy(strategy).withdraw(token, amount);
        emit Recalled(strategy, token, amount, msg.sender);
    }

    // ---------------------------------------------------------------- admin payouts

    /// @inheritdoc ITreasuryModule
    function withdraw(address token, uint256 amount, address to) external nonReentrant onlyMarketAdmin {
        if (to == address(0)) revert BactoryErrors.ZeroAddress();
        if (amount == 0) revert BactoryErrors.ZeroAmount();
        IERC20(token).safeTransfer(to, amount);
        emit Withdrawn(token, amount, to);
    }

    /// @inheritdoc ITreasuryModule
    /// @dev Reward distribution: one transfer per recipient, all from idle balance.
    function distribute(address token, address[] calldata recipients, uint256[] calldata amounts)
        external
        nonReentrant
        onlyMarketAdmin
        whenMarketLive
    {
        if (recipients.length != amounts.length) revert BactoryErrors.LengthMismatch();
        uint256 total;
        for (uint256 i; i < recipients.length; ++i) {
            if (recipients[i] == address(0)) revert BactoryErrors.ZeroAddress();
            total += amounts[i];
            IERC20(token).safeTransfer(recipients[i], amounts[i]);
        }
        emit Distributed(token, total, recipients.length);
    }
}
