# @bactory/sdk

TypeScript SDK for [Bactory](https://bactory.tech), built on [viem](https://viem.sh).

```bash
npm install @bactory/sdk viem
```

## Build a market around an existing asset

```ts
import { createPublicClient, createWalletClient, http } from 'viem'
import { baseSepolia } from 'viem/chains'
import { createBactory } from '@bactory/sdk'

const publicClient = createPublicClient({ chain: baseSepolia, transport: http() })
const walletClient = createWalletClient({ account, chain: baseSepolia, transport: http() })

const bactory = await createBactory({ publicClient, walletClient, factory: FACTORY })

const market = await bactory.market({ asset: WETH, quote: 'USDC' }) // builds it if needed
await market.activate({ treasury: true, yield: true, agents: true })
```

## Read

```ts
const m = await bactory.findMarket({ asset, quote: 'USDC' })  // null if not built
const state = await m.state()                                  // config, admin, modules
const vault = await m.vault()
await vault.stats()                                            // TVL, share price
const treasury = await m.treasury()
await treasury.position(usdc)                                  // idle, allocated, limits
```

## Agents

```ts
const agents = await market.agents()
await agents.register(agentAddress, 4)                        // admin

// as the agent:
const reason = await agents.preview(agentAddress, action)     // 'None' or why it would fail
const r = await agents.propose(action)                        // { executed, reason, proposalId, hash }
```

## Modules

`Treasury`, `Yield` and `Agents` can be activated. `Liquidity`, `Bounties` and `Community` are planned; asking for them throws `ModuleNotAvailableError`.

## Development

```bash
npm install
npm run abis       # after `forge build` in the repo root
npm run typecheck
npm test           # needs `anvil` (Foundry) on PATH
```

Examples in [`examples/`](examples): `build-market.ts`, `read-market.ts`, `deposit.ts`, `agent-bot.ts`.
