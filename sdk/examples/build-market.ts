/**
 * Build a market around an existing asset and activate the core modules.
 *
 *   PRIVATE_KEY=0x... FACTORY=0x... ASSET=0x... npx tsx examples/build-market.ts
 */
import { createPublicClient, createWalletClient, http, type Address, type Hex } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { baseSepolia } from 'viem/chains';
import { createBactory } from '../src/index.js';

const account = privateKeyToAccount(process.env.PRIVATE_KEY as Hex);
const publicClient = createPublicClient({ chain: baseSepolia, transport: http() });
const walletClient = createWalletClient({ account, chain: baseSepolia, transport: http() });

const bactory = await createBactory({ publicClient, walletClient, factory: process.env.FACTORY as Address });

// 01 Connect Asset → 02 Build Market
const market = await bactory.market({ asset: process.env.ASSET as Address, quote: 'USDC' });
console.log('market', market.address);

// 03 Activate Modules
const activated = await market.activate({ treasury: true, yield: true, agents: true });
console.log('activated', activated);

// 04 Operate
console.log(await market.state());
