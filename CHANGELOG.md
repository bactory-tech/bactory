# Changelog

## 0.1.0 — 2026-10-02

First version of the protocol.

- `BactoryFactory`: builds one market per (asset, quote) for existing assets; allow-listed quotes; deterministic market addresses; module deployment via minimal proxies.
- `Market`: fee routing with fallbacks, module activation, config with onchain limits, pause, two-step admin.
- `TreasuryModule`: approved strategies, per-action limit, idle reserve, recall, withdraw, reward distribution.
- `YieldVault`: ERC-4626 on the quote token with a decimals offset; deposits pause with the market, withdrawals never do.
- `AgentGuard`: proposals with rate limits, Chainlink freshness and sequencer checks, onchain rejection records, three-strike suspension, `preview`.
- Strategies: `HoldStrategy`, `VaultStrategy`.
- Scripts for Base and Base Sepolia; TypeScript SDK with examples.
