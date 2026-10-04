/**
 * A minimal Bactory agent. Every interval it reads the treasury, decides how much idle USDC to park
 * in an approved strategy, previews the action, and proposes it. The AgentGuard decides.
 *
 * The decision rule here is deliberately simple: keep `TARGET_ALLOCATED_PCT` of the treasury allocated.
 * Replace `decide()` with your own model; the guard enforces the market's limits either way.
 *
 *   AGENT_KEY=0x... FACTORY=0x... ASSET=0x... STRATEGY=0x... npx tsx examples/agent-bot.ts
 */
import { createPublicClient, createWalletClient, formatUnits, http, type Address, type Hex } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { baseSepolia } from 'viem/chains';
import { createBactory, type AgentAction } from '../src/index.js';

const TARGET_ALLOCATED_PCT = 40n;
const INTERVAL_MS = 60 * 60 * 1000;

const account = privateKeyToAccount(process.env.AGENT_KEY as Hex);
const publicClient = createPublicClient({ chain: baseSepolia, transport: http() });
const walletClient = createWalletClient({ account, chain: baseSepolia, transport: http() });
const bactory = await createBactory({ publicClient, walletClient, factory: process.env.FACTORY as Address });
const strategy = process.env.STRATEGY as Address;

const market = await bactory.findMarket({ asset: process.env.ASSET as Address, quote: 'USDC' });
if (!market) throw new Error('No market for this asset');
const { quote } = await market.state();
const treasury = await market.treasury();
const agents = await market.agents();

function decide(total: bigint, allocated: bigint, limit: bigint): AgentAction | null {
  const target = (total * TARGET_ALLOCATED_PCT) / 100n;
  if (allocated < target) {
    const amount = [target - allocated, limit].reduce((a, b) => (a < b ? a : b));
    return amount > 0n ? { kind: 'allocate', strategy, token: quote, amount } : null;
  }
  if (allocated > target) return { kind: 'recall', strategy, token: quote, amount: allocated - target };
  return null;
}

async function tick() {
  const p = await treasury.position(quote);
  const action = decide(p.totalValue, p.allocated, p.actionLimit);
  if (!action) return console.log('on target, nothing to propose');

  const check = await agents.preview(account.address, action);
  if (check !== 'None') return console.log(`would be rejected (${check}); not proposing`);

  const r = await agents.propose(action);
  console.log(`#${r.proposalId} ${action.kind} ${formatUnits(action.amount, 6)} USDC → ${r.executed ? 'EXECUTED' : 'REJECTED ' + r.reason}  ${r.hash}`);
}

await tick();
setInterval(() => tick().catch(e => console.error(e.shortMessage ?? e)), INTERVAL_MS);
