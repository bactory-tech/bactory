# Architecture

Bactory turns an asset that already exists into a programmable market. The protocol has three layers.

## 1. Factory

`BactoryFactory` is the only entry point for building markets.

- `buildMarket(asset, quote, config)` clones the `Market` implementation at a deterministic address (`predictMarket`) and makes the caller its admin.
- The asset must already have code. The factory never deploys or mints tokens.
- Quotes are allow-listed by the factory owner (USDC and WETH on Base).
- `deployModule(id)` can only be called by a market the factory built. It clones the module implementation and initializes it for that market.

## 2. Market

`Market` is the coordination layer. It owns no funds between calls.

| Field | Meaning |
|---|---|
| `asset`, `quote` | The pair the market is built around |
| `admin` | The market builder; can change config, modules, pause |
| `config` | Fee split and limits (see [fee-routing.md](fee-routing.md)) |
| `moduleOf[id]`, `isActive[id]` | Which modules exist and run |

## 3. Modules

| Id | Module | Status |
|---|---|---|
| 1 | [Treasury](modules/treasury.md) | core |
| 2 | [Yield](modules/yield.md) | core |
| 3 | [Agents](modules/agents.md) | beta |
| 4 | Liquidity (Uniswap v4 hook) | planned |
| 5 | Bounties | planned |
| 6 | Community | planned |

Modules are independent contracts with their own permissions. Deactivating a module keeps its address and state, so reactivating it resumes where it stopped.

## Flow

```
builder ──buildMarket──▶ Factory ──clone──▶ Market
builder ──activateModule──▶ Market ──deployModule──▶ Factory ──clone──▶ Module
anyone ──routeFees──▶ Market ──split──▶ YieldVault / Treasury / builder
agent ──propose──▶ AgentGuard ──checks──▶ Treasury.allocate / recall
```
