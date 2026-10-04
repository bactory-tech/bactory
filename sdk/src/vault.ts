import type { Address } from 'viem';
import { erc20Abi, yieldVaultAbi } from './abis/index.js';
import { type BactoryContext, requireWallet, write } from './context.js';

/** The market's ERC-4626 yield vault on its quote token. */
export class Vault {
  constructor(private readonly ctx: BactoryContext, public readonly address: Address) {}

  private read<T>(functionName: string, args: readonly unknown[] = []) {
    return this.ctx.publicClient.readContract({ address: this.address, abi: yieldVaultAbi, functionName, args } as never) as Promise<T>;
  }

  async stats() {
    const [asset, totalAssets, totalSupply, sharePrice, decimals] = await Promise.all([
      this.read<Address>('asset'), this.read<bigint>('totalAssets'), this.read<bigint>('totalSupply'),
      this.read<bigint>('sharePrice'), this.read<number>('decimals'),
    ]);
    return { asset, totalAssets, totalSupply, sharePrice, decimals };
  }

  /** Shares and their current value in assets for `owner`. */
  async positionOf(owner: Address) {
    const shares = await this.read<bigint>('balanceOf', [owner]);
    const assets = await this.read<bigint>('convertToAssets', [shares]);
    return { shares, assets };
  }

  /** Approves the vault if needed, then deposits `assets` for the connected wallet. */
  async deposit(assets: bigint, receiver?: Address) {
    const wallet = requireWallet(this.ctx);
    const owner = wallet.account.address;
    const asset = await this.read<Address>('asset');
    const allowance = (await this.ctx.publicClient.readContract({ address: asset, abi: erc20Abi, functionName: 'allowance', args: [owner, this.address] })) as bigint;
    if (allowance < assets) {
      await write(this.ctx, { address: asset, abi: erc20Abi, functionName: 'approve', args: [this.address, assets] } as never);
    }
    return write(this.ctx, { address: this.address, abi: yieldVaultAbi, functionName: 'deposit', args: [assets, receiver ?? owner] } as never);
  }

  /** Redeems `shares` (default: all) back to assets. */
  async redeem(shares?: bigint, receiver?: Address) {
    const owner = requireWallet(this.ctx).account.address;
    const amount = shares ?? (await this.read<bigint>('balanceOf', [owner]));
    return write(this.ctx, { address: this.address, abi: yieldVaultAbi, functionName: 'redeem', args: [amount, receiver ?? owner, owner] } as never);
  }
}
