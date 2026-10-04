# Treasury module

Holds market-owned capital and deploys it only into approved strategies.

## Who can move capital

| Caller | allocate / recall | withdraw / distribute | approveStrategy |
|---|---|---|---|
| Market admin | ✓ | ✓ | ✓ |
| Active AgentGuard | ✓ (after its checks) | — | — |
| Anyone else | — | — | — |

## Rules on `allocate(strategy, token, amount)`

1. The market is not paused.
2. `strategy` is approved.
3. `amount ≤ actionLimit(token)` = `maxActionBps` of the token's total value (idle + allocated).
4. After the transfer, idle balance stays `≥ reserveRequired(token)` = `reserveBps` of total value.

`recall` is always allowed, even while paused, up to what was allocated to that strategy.

## Accounting

`allocated[strategy][token]` and `totalAllocated[token]` track principal sent to strategies. `totalValue(token)` = idle + totalAllocated. Strategy gains are realised when capital is recalled; the invariant tests check that the books match strategy balances under random activity.

## Writing a strategy

Extend `BaseStrategy` and implement `_deploy`, `_free` and `balanceOf`. Only the bound treasury can call `onDeposit` and `withdraw`. See `HoldStrategy` (holds funds) and `VaultStrategy` (deposits into any ERC-4626 vault).
