// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IAgentGuard
/// @notice Agents propose. Contracts enforce.
interface IAgentGuard {
    enum ActionKind {
        Allocate,
        Recall
    }

    struct Action {
        ActionKind kind;
        address strategy;
        address token;
        uint256 amount;
    }

    /// @notice Why a proposal was rejected. `None` means it executed.
    enum Rejection {
        None,
        AgentSuspended,
        RateLimited,
        OracleNotFresh,
        StrategyNotApproved,
        ExceedsActionLimit,
        BreaksReserve,
        InsufficientAllocation,
        MarketPaused
    }

    struct AgentInfo {
        bool registered;
        bool suspended;
        uint16 maxPerDay;
        uint16 usedToday;
        uint32 dayIndex;
        uint32 accepted;
        uint32 rejected;
        uint8 strikes;
    }

    event AgentRegistered(address indexed agent, uint16 maxPerDay);
    event AgentRemoved(address indexed agent);
    event AgentReinstated(address indexed agent);
    event AgentSuspended(address indexed agent);
    event OracleSet(address feed, uint32 maxAge, address sequencerFeed);
    event ProposalExecuted(address indexed agent, uint256 indexed id, Action action);
    event ProposalRejected(address indexed agent, uint256 indexed id, Action action, Rejection reason);

    function initialize(address market) external;
    function market() external view returns (address);
    function agentInfo(address agent) external view returns (AgentInfo memory);
    function proposalCount() external view returns (uint256);
    function strikesToSuspend() external view returns (uint8);

    function registerAgent(address agent, uint16 maxPerDay) external;
    function removeAgent(address agent) external;
    function reinstateAgent(address agent) external;
    function setOracle(address feed, uint32 maxAge, address sequencerFeed) external;

    /// @notice Submits an action. Returns true when it executed, false when the guard rejected it.
    /// @dev A rejection is recorded onchain and never reverts, so every decision stays visible.
    function propose(Action calldata action) external returns (bool executed, Rejection reason);

    /// @notice Runs every check without executing anything.
    function preview(address agent, Action calldata action) external view returns (Rejection reason);
}
