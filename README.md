# Bactory Protocol

**Modular market infrastructure on Base.** Build more around any asset.

Bactory does not create tokens. It builds a **Market** around an asset that already exists on Base,
and lets the market's builder activate **modules** around it: a treasury, an ERC-4626 yield vault and
an agent guard today; liquidity (Uniswap v4), bounties and community next.

```
Connect Asset → Build Market → Activate Modules → Operate
```

Website: https://bactory.tech · X: [@bactorydottech](https://x.com/bactorydottech)

> **Status:** development · contracts **unaudited** · not deployed to Base mainnet.

## How it fits together

```
                 BactoryFactory
                       │  buildMarket(asset, quote, config)
                       ▼
 existing ERC-20 ── Market ──────────────── routeFees(token, amount)
                       │                      │  split by config
       ┌───────────────┼───────────────┐      ▼
  TreasuryModule    YieldVault     AgentGuard
  (capital, limits) (ERC-4626)     (agents propose, contract enforces)
       │
   strategies (HoldStrategy, VaultStrategy, …)
```

- **BactoryFactory** builds one market per (asset, quote). The asset must already be a contract; quotes are allow-listed (USDC, WETH). Markets and modules are cheap minimal-proxy clones.
- **Market** stores the asset, quote, admin, fee split and limits, and which modules are active. It routes fees and holds nothing between calls.
- **TreasuryModule** holds market-owned capital and moves it only into approved strategies, never more than `maxActionBps` per action, always leaving `reserveBps` idle.
- **YieldVault** is an ERC-4626 vault on the quote token. Fees routed to it raise the share price for every depositor.
- **AgentGuard** lets registered agents propose treasury actions. Each proposal is checked (rate limit, Chainlink freshness and L2 sequencer, approved strategy, action limit, reserve) and either executed or recorded as rejected. Three rejections suspend an agent. Agents never hold assets.

More in [`docs/`](docs/).

## Repository

| Path | What it is |
|---|---|
| `src/` | Solidity contracts |
| `src/interfaces/` | Public interfaces |
| `src/libraries/` | Errors, bps math, oracle checks, module ids |
| `src/modules/` | Treasury, YieldVault, AgentGuard |
| `src/strategies/` | Treasury strategies |
| `test/` | Unit, integration, fuzz and invariant tests (Foundry) |
| `script/` | Deployment and setup scripts for Base and Base Sepolia |
| `sdk/` | TypeScript SDK (`@bactory/sdk`, built on viem) with examples and tests |
| `docs/` | Architecture and module documentation |

## Quick start

Requirements: [Foundry](https://book.getfoundry.sh/getting-started/installation), Node 18+.

```bash
git clone <this repo> bactory && cd bactory
forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts@v5.1.0 OpenZeppelin/openzeppelin-contracts-upgradeable@v5.1.0
forge build
forge test
```

SDK:

```bash
cd sdk
npm install
npm run abis      # copy ABIs from ../out after forge build
npm test          # starts a local anvil and runs the SDK end to end
```

## Deploy to Base Sepolia

```bash
cp .env.example .env   # fill in PRIVATE_KEY and RPC URLs
source .env
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify
FACTORY=0x... ASSET=0x... forge script script/BuildMarket.s.sol --rpc-url base_sepolia --broadcast
```

See [`docs/deployment.md`](docs/deployment.md).

## Use it from TypeScript

```ts
import { createBactory } from '@bactory/sdk'

const bactory = await createBactory({ publicClient, walletClient, factory })
const market = await bactory.market({ asset: AERO, quote: 'USDC' })
await market.activate({ treasury: true, yield: true, agents: true })
```

## Security

Unaudited, experimental software. Do not use real funds. See [`SECURITY.md`](SECURITY.md).

## License

MIT
