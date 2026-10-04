import type { Account, Address, Chain, Hash, Hex, Transport, WalletClient } from 'viem';
import { NoWalletError } from './errors.js';

/**
 * The subset of a viem public client the SDK uses. Kept structural so any chain's client fits
 * (Base's OP-stack client types differ from the generic ones).
 */
export interface ReadClient {
  getChainId(): Promise<number>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  readContract(args: any): Promise<unknown>;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  simulateContract(args: any): Promise<{ request: unknown; result: unknown }>;
  waitForTransactionReceipt(args: { hash: Hash }): Promise<{ logs: readonly { address: Address; data: Hex; topics: readonly Hex[] }[] }>;
}

/** Shared clients every SDK object uses. */
export interface BactoryContext {
  publicClient: ReadClient;
  walletClient?: WalletClient<Transport, Chain, Account>;
  factory: Address;
  chainId: number;
}

export function requireWallet(ctx: BactoryContext): WalletClient<Transport, Chain, Account> {
  if (!ctx.walletClient) throw new NoWalletError();
  return ctx.walletClient;
}

/** Sends a contract write and waits for it to be mined. */
export async function write(ctx: BactoryContext, request: Parameters<WalletClient['writeContract']>[0]) {
  const wallet = requireWallet(ctx);
  const { request: simulated, result } = await ctx.publicClient.simulateContract({ ...(request as object), account: wallet.account } as never);
  const hash = await wallet.writeContract(simulated as never);
  const receipt = await ctx.publicClient.waitForTransactionReceipt({ hash });
  return { hash, receipt, result: result as unknown };
}
