# Agents module (beta)

**Agents propose. Contracts enforce.**

An agent is any account (usually an automated program) the market admin registers on the market's `AgentGuard`. It never holds assets and never gets admin rights.

## Proposing

```solidity
(bool executed, Rejection reason) = guard.propose(Action({
    kind: ActionKind.Allocate,   // or Recall
    strategy: strategy,
    token: usdc,
    amount: 1_000e6
}));
```

Checks, in order. The first that fails is the recorded reason:

| Check | Rejection |
|---|---|
| Agent suspended | `AgentSuspended` |
| Market paused (allocations only) | `MarketPaused` |
| Over the agent's daily limit | `RateLimited` |
| Chainlink price stale / invalid, or Base sequencer down or within 1 h of restart | `OracleNotFresh` |
| Strategy not approved | `StrategyNotApproved` |
| Amount over `maxActionBps` of treasury value | `ExceedsActionLimit` |
| Would leave less than `reserveBps` idle | `BreaksReserve` |
| Recall more than allocated | `InsufficientAllocation` |

A rejected proposal **does not revert**: it emits `ProposalRejected` with the reason, so every decision is visible onchain. Every rejection except rate limiting and suspension adds a strike; **three strikes suspend** the agent until the admin calls `reinstateAgent`.

`preview(agent, action)` runs the same checks without executing anything, so agents can test before proposing.

## Admin

- `registerAgent(agent, maxPerDay)`, `removeAgent`, `reinstateAgent`
- `setOracle(feed, maxAge, sequencerFeed)` — on Base mainnet use ETH/USD `0x7104…Bb70` and the sequencer feed `0xBCF8…6433`.

An example agent lives in `sdk/examples/agent-bot.ts`.
