import type { Address } from 'viem';
import { treasuryModuleAbi } from './abis/index.js';
import { type BactoryContext, write } from './context.js';

/** The market's treasury: market-owned capital under onchain rules. */
export class Treasury {
  constructor(private readonly ctx: BactoryContext, public readonly address: Address) {}

  private read<T>(functionName: string, args: readonly unknown[] = []) {
    return this.ctx.publicClient.readContract({ address: this.address, abi: treasuryModuleAbi, functionName, args } as never) as Promise<T>;
  }

  /** Idle balance, allocated capital, total value and the current limits for one token. */
  async position(token: Address) {
    const [idle, totalValue, actionLimit, reserveRequired] = await Promise.all([
      this.read<bigint>('idle', [token]),
      this.read<bigint>('totalValue', [token]),
      this.read<bigint>('actionLimit', [token]),
      this.read<bigint>('reserveRequired', [token]),
    ]);
    return { idle, allocated: totalValue - idle, totalValue, actionLimit, reserveRequired };
  }

  allocatedTo(strategy: Address, token: Address) {
    return this.read<bigint>('allocated', [strategy, token]);
  }

  isApproved(strategy: Address) {
    return this.read<boolean>('isApproved', [strategy]);
  }

  approveStrategy(strategy: Address, approved = true) {
    return write(this.ctx, { address: this.address, abi: treasuryModuleAbi, functionName: 'approveStrategy', args: [strategy, approved] } as never);
  }

  allocate(strategy: Address, token: Address, amount: bigint) {
    return write(this.ctx, { address: this.address, abi: treasuryModuleAbi, functionName: 'allocate', args: [strategy, token, amount] } as never);
  }

  recall(strategy: Address, token: Address, amount: bigint) {
    return write(this.ctx, { address: this.address, abi: treasuryModuleAbi, functionName: 'recall', args: [strategy, token, amount] } as never);
  }

  withdraw(token: Address, amount: bigint, to: Address) {
    return write(this.ctx, { address: this.address, abi: treasuryModuleAbi, functionName: 'withdraw', args: [token, amount, to] } as never);
  }

  distribute(token: Address, payouts: { to: Address; amount: bigint }[]) {
    return write(this.ctx, {
      address: this.address, abi: treasuryModuleAbi, functionName: 'distribute',
      args: [token, payouts.map(p => p.to), payouts.map(p => p.amount)],
    } as never);
  }
}
