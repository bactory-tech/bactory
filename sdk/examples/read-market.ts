/**
 * Read-only: print a market's configuration, modules, vault and treasury figures. No wallet needed.
 *
 *   FACTORY=0x... ASSET=0x... npx tsx examples/read-market.ts
 */
import { createPublicClient, formatUnits, http, type Address } from 'viem';
import { baseSepolia } from 'viem/chains';
import { createBactory } from '../src/index.js';

const publicClient = createPublicClient({ chain: baseSepolia, transport: http() });
const bactory = await createBactory({ publicClient, factory: process.env.FACTORY as Address });

const market = await bactory.findMarket({ asset: process.env.ASSET as Address, quote: 'USDC' });
if (!market) {
  console.log('No Bactory market for this asset yet. Anyone can build one.');
  process.exit(0);
}

const s = await market.state();
console.log(`Market ${s.address}  asset ${s.asset}  quote ${s.quote}  admin ${s.admin}${s.paused ? '  PAUSED' : ''}`);
console.log(`Fees  vault ${s.config.lpBps / 100}%  treasury ${s.config.treasuryBps / 100}%  builder ${s.config.builderBps / 100}%`);
console.log(`Limits  ${s.config.maxActionBps / 100}% per action  reserve ${s.config.reserveBps / 100}%`);
for (const [name, m] of Object.entries(s.modules)) console.log(`  ${name.padEnd(10)} ${m.active ? 'active' : '—'}  ${m.address ?? ''}`);

if (s.modules.Yield.active) {
  const v = await (await market.vault()).stats();
  console.log(`Vault TVL ${formatUnits(v.totalAssets, 6)} USDC`);
}
if (s.modules.Treasury.active) {
  const t = await (await market.treasury()).position(s.quote);
  console.log(`Treasury ${formatUnits(t.totalValue, 6)} USDC  (idle ${formatUnits(t.idle, 6)}, limit per action ${formatUnits(t.actionLimit, 6)})`);
}
