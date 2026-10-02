// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MarketModule} from "./MarketModule.sol";
import {IAgentGuard} from "../interfaces/IAgentGuard.sol";
import {ITreasuryModule} from "../interfaces/ITreasuryModule.sol";
import {BactoryErrors} from "../libraries/BactoryErrors.sol";
import {ModuleIds} from "../libraries/ModuleIds.sol";
import {OracleLib} from "../libraries/OracleLib.sol";
import {Bps} from "../libraries/Bps.sol";

/// @title AgentGuard
/// @notice Agents propose. Contracts enforce.
/// @dev An agent never holds market assets and never gets admin rights. It submits an action;
///      the guard checks it against the market's limits and either executes it through the treasury
///      or records the rejection with its reason. Three rejections suspend the agent.
contract AgentGuard is IAgentGuard, MarketModule {
    uint8 public constant strikesToSuspend = 3;

    mapping(address agent => AgentInfo) internal _agents;
    uint256 public proposalCount;

    address public oracleFeed;
    uint32 public oracleMaxAge;
    address public sequencerFeed;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address market_) external initializer {
        __MarketModule_init(market_);
    }

    function market() public view override(IAgentGuard, MarketModule) returns (address) {
        return address(_market);
    }

    // ---------------------------------------------------------------- admin

    function registerAgent(address agent, uint16 maxPerDay) external onlyMarketAdmin {
        if (agent == address(0)) revert BactoryErrors.ZeroAddress();
        AgentInfo storage a = _agents[agent];
        a.registered = true;
        a.maxPerDay = maxPerDay;
        emit AgentRegistered(agent, maxPerDay);
    }

    function removeAgent(address agent) external onlyMarketAdmin {
        delete _agents[agent];
        emit AgentRemoved(agent);
    }

    function reinstateAgent(address agent) external onlyMarketAdmin {
        AgentInfo storage a = _agents[agent];
        a.suspended = false;
        a.strikes = 0;
        emit AgentReinstated(agent);
    }

    /// @param feed Price feed every proposal must find fresh, or address(0) to skip the price check.
    /// @param maxAge Seconds a price may be old.
    /// @param sequencer L2 sequencer uptime feed (Base: Chainlink), or address(0).
    function setOracle(address feed, uint32 maxAge, address sequencer) external onlyMarketAdmin {
        oracleFeed = feed;
        oracleMaxAge = maxAge;
        sequencerFeed = sequencer;
        emit OracleSet(feed, maxAge, sequencer);
    }

    // ---------------------------------------------------------------- proposals

    function agentInfo(address agent) external view returns (AgentInfo memory) {
        return _agents[agent];
    }

    /// @inheritdoc IAgentGuard
    function propose(Action calldata action) external returns (bool executed, Rejection reason) {
        AgentInfo storage a = _agents[msg.sender];
        if (!a.registered) revert BactoryErrors.NotAuthorized(msg.sender);

        uint256 id = ++proposalCount;
        reason = _check(msg.sender, action);

        if (reason == Rejection.None) {
            _consumeRate(a);
            ITreasuryModule treasury = _treasury();
            if (action.kind == ActionKind.Allocate) treasury.allocate(action.strategy, action.token, action.amount);
            else treasury.recall(action.strategy, action.token, action.amount);
            a.accepted += 1;
            emit ProposalExecuted(msg.sender, id, action);
            return (true, Rejection.None);
        }

        if (reason != Rejection.RateLimited && reason != Rejection.AgentSuspended) {
            _consumeRate(a);
            a.strikes += 1;
            if (a.strikes >= strikesToSuspend) {
                a.suspended = true;
                emit AgentSuspended(msg.sender);
            }
        }
        a.rejected += 1;
        emit ProposalRejected(msg.sender, id, action, reason);
        return (false, reason);
    }

    /// @inheritdoc IAgentGuard
    function preview(address agent, Action calldata action) external view returns (Rejection) {
        return _check(agent, action);
    }

    // ---------------------------------------------------------------- checks

    function _check(address agent, Action calldata action) internal view returns (Rejection) {
        AgentInfo storage a = _agents[agent];
        if (a.suspended) return Rejection.AgentSuspended;
        if (_market.paused() && action.kind == ActionKind.Allocate) return Rejection.MarketPaused;
        uint32 today = uint32(block.timestamp / 1 days);
        uint16 used = a.dayIndex == today ? a.usedToday : 0;
        if (used >= a.maxPerDay) return Rejection.RateLimited;

        OracleLib.Status s = OracleLib.check(oracleFeed, oracleMaxAge, sequencerFeed);
        if (s != OracleLib.Status.Ok && s != OracleLib.Status.NoFeed) return Rejection.OracleNotFresh;

        ITreasuryModule treasury = _treasury();
        if (action.kind == ActionKind.Allocate) {
            if (!treasury.isApproved(action.strategy)) return Rejection.StrategyNotApproved;
            if (action.amount == 0 || action.amount > treasury.actionLimit(action.token)) {
                return Rejection.ExceedsActionLimit;
            }
            uint256 idleNow = treasury.idle(action.token);
            uint256 reserve = Bps.mul(treasury.totalValue(action.token), _market.config().reserveBps);
            if (action.amount > idleNow || idleNow - action.amount < reserve) return Rejection.BreaksReserve;
        } else {
            if (action.amount == 0 || action.amount > treasury.allocated(action.strategy, action.token)) {
                return Rejection.InsufficientAllocation;
            }
        }
        return Rejection.None;
    }

    function _consumeRate(AgentInfo storage a) internal {
        uint32 today = uint32(block.timestamp / 1 days);
        if (a.dayIndex != today) {
            a.dayIndex = today;
            a.usedToday = 0;
        }
        a.usedToday += 1;
    }

    function _treasury() internal view returns (ITreasuryModule) {
        if (!_market.isActive(ModuleIds.TREASURY)) revert BactoryErrors.ModuleNotActive(ModuleIds.TREASURY);
        return ITreasuryModule(_market.moduleOf(ModuleIds.TREASURY));
    }
}
