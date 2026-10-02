# Security

Bactory is **unaudited, experimental software**. Do not deposit real funds.

## Reporting a vulnerability

Please do not open a public issue. Send a direct message to [@bactorydottech](https://x.com/bactorydottech)
with a description and, if possible, a failing Foundry test. We will acknowledge within 72 hours.

## Design choices that limit risk

- **No token creation.** The factory only builds markets around existing contracts.
- **Agents never hold assets.** An agent can only call `AgentGuard.propose`; the guard executes through the treasury, inside the market's limits.
- **Limits are enforced onchain:** `maxActionBps` (≤ 50%), `reserveBps`, `slippageBps` (≤ 5%), approved strategies only, per-agent daily rate limit, three strikes suspend.
- **Oracle checks:** Chainlink freshness and the Base L2 sequencer uptime feed with a one-hour grace period.
- **Exits stay open:** pausing a market blocks new deposits and allocations, never vault withdrawals or recalls.
- **Inflation-attack resistance:** the yield vault uses a decimals offset of 6.
- **Two-step admin transfer** on markets; `Ownable2Step` on the factory.

## Known limitations

- Strategies are trusted once the market admin approves them. Review strategy code before approval.
- Fee routing trusts the token's `transfer` semantics; fee-on-transfer and rebasing quote tokens are not supported (the factory allow-lists quotes for this reason).
- The liquidity (Uniswap v4 hook), bounties and community modules are not implemented yet.
