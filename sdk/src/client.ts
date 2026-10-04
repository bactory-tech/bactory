import type { Account, Address, Chain, Transport, WalletClient } from 'viem';
import { bactoryFactoryAbi } from './abis/index.js';
import { FACTORIES, network, type SupportedChainId } from './addresses.js';
import { DEFAULT_LIMITS } from './constants.js';
import { type BactoryContext, type ReadClient, requireWallet, write } from './context.js';
import { Market } from './market.js';
import type { MarketConfig } from './types.js';

export interface CreateBactoryOptions {
  /** Any viem public client (e.g. createPublicClient({ chain: base, transport: http() })). */
  publicClient: ReadClient;
  walletClient?: WalletClient<Transport, Chain, Account>;
  /** BactoryFactory address. Defaults to the known deployment for the chain, if any. */
  factory?: Address;
}

export interface MarketParams {
  /** An asset that already exists on Base. Bactory never creates tokens. */
  asset: Address;
  /** 'USDC', 'WETH' or a token address. Defaults to USDC. */
  quote?: 'USDC' | 'WETH' | Address;
  /** Overrides for fee routing and limits. The builder defaults to the connected wallet. */
  config?: Partial<MarketConfig>;
}

/** Entry point. @example const bactory = await createBactory({ publicClient, walletClient }) */
export async function createBactory(opts: CreateBactoryOptions) {
  const chainId = await opts.publicClient.getChainId();
  const net = network(chainId);
  const factory = opts.factory ?? FACTORIES[chainId as SupportedChainId];
  if (!factory) throw new Error(`Bactory: no factory known for chain ${chainId}; pass { factory }`);
  const ctx: BactoryContext = { publicClient: opts.publicClient, walletClient: opts.walletClient, factory, chainId };

  const resolveQuote = (q: MarketParams['quote']): Address => (q === undefined || q === 'USDC' ? net.usdc : q === 'WETH' ? net.weth : q);
  const readFactory = <T>(functionName: string, args: readonly unknown[] = []) =>
    ctx.publicClient.readContract({ address: factory, abi: bactoryFactoryAbi, functionName, args } as never) as Promise<T>;

  return {
    chainId,
    network: net,
    factory,

    /** The market for (asset, quote), or null if nobody has built it yet. */
    async findMarket({ asset, quote }: Omit<MarketParams, 'config'>) {
      const addr = await readFactory<Address>('marketOf', [asset, resolveQuote(quote)]);
      return /^0x0+$/.test(addr) ? null : new Market(ctx, addr);
    },

    /**
     * Returns the market for (asset, quote), building it first if it does not exist.
     * @example const market = await bactory.market({ asset: AERO, quote: 'USDC' })
     */
    async market({ asset, quote, config }: MarketParams) {
      const q = resolveQuote(quote);
      const existing = await readFactory<Address>('marketOf', [asset, q]);
      if (!/^0x0+$/.test(existing)) return new Market(ctx, existing);
      const builder = config?.builder ?? requireWallet(ctx).account.address;
      const full: MarketConfig = { ...DEFAULT_LIMITS, builder, ...config };
      await write(ctx, { address: factory, abi: bactoryFactoryAbi, functionName: 'buildMarket', args: [asset, q, full] } as never);
      return new Market(ctx, await readFactory<Address>('marketOf', [asset, q]));
    },

    /** Market at a known address. */
    at(address: Address) {
      return new Market(ctx, address);
    },

    /** Every market the factory has built. */
    async allMarkets() {
      const list = await readFactory<Address[]>('allMarkets');
      return list.map(a => new Market(ctx, a));
    },
  };
}

export type Bactory = Awaited<ReturnType<typeof createBactory>>;
