/**
 * Deposit USDC into a market's yield vault and print the position.
 *
 *   PRIVATE_KEY=0x... FACTORY=0x... ASSET=0x... AMOUNT=100 npx tsx examples/deposit.ts
 */
import { createPublicClient, createWalletClient, formatUnits, http, parseUnits, type Address, type Hex } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { baseSepolia } from 'viem/chains';
import { createBactory } from '../src/index.js';

const account = privateKeyToAccount(process.env.PRIVATE_KEY as Hex);
const publicClient = createPublicClient({ chain: baseSepolia, transport: http() });
const walletClient = createWalletClient({ account, chain: baseSepolia, transport: http() });
const bactory = await createBactory({ publicClient, walletClient, factory: process.env.FACTORY as Address });

const market = await bactory.findMarket({ asset: process.env.ASSET as Address, quote: 'USDC' });
if (!market) throw new Error('No market for this asset');
const vault = await market.vault();

await vault.deposit(parseUnits(process.env.AMOUNT ?? '100', 6));
const pos = await vault.positionOf(account.address);
console.log(`shares ${pos.shares}  worth ${formatUnits(pos.assets, 6)} USDC`);
