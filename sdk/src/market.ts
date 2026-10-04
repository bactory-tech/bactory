import { type Address, zeroAddress } from 'viem';
import { erc20Abi, marketAbi } from './abis/index.js';
import { AVAILABLE_MODULES, ModuleId, type ModuleName } from './constants.js';
import { type BactoryContext, write } from './context.js';
import { ModuleInactiveError, ModuleNotAvailableError } from './errors.js';
import { Treasury } from './treasury.js';
import { Vault } from './vault.js';
import { Agents } from './agents.js';
import type { ActivateOptions, MarketConfig, MarketState } from './types.js';

const NAMES = Object.keys(ModuleId) as ModuleName[];
const cap = (s: string) => (s[0].toUpperCase() + s.slice(1)) as ModuleName;

/** A Bactory Market: the coordination layer around one existing asset. */
export class Market {
  constructor(private readonly ctx: BactoryContext, public readonly address: Address) {}

  private read<T>(functionName: string, args: readonly unknown[] = []) {
    return this.ctx.publicClient.readContract({ address: this.address, abi: marketAbi, functionName, args } as never) as Promise<T>;
  }

  /** Everything about the market in one call: asset, quote, admin, limits and modules. */
  async state(): Promise<MarketState> {
    const [asset, quote, admin, paused, config] = await Promise.all([
      this.read<Address>('asset'), this.read<Address>('quote'), this.read<Address>('admin'),
      this.read<boolean>('paused'), this.read<MarketConfig>('config'),
    ]);
    const modules = {} as MarketState['modules'];
    await Promise.all(NAMES.map(async n => {
      const [addr, active] = await Promise.all([this.read<Address>('moduleOf', [ModuleId[n]]), this.read<boolean>('isActive', [ModuleId[n]])]);
      modules[n] = { address: addr === zeroAddress ? null : addr, active };
    }));
    return { address: this.address, asset, quote, admin, paused, config: { ...config }, modules };
  }

  /**
   * Activates modules. Already-active ones are skipped.
   * @example await market.activate({ treasury: true, yield: true })
   */
  async activate(options: ActivateOptions) {
    const wanted = Object.entries(options).filter(([, on]) => on).map(([k]) => cap(k));
    for (const name of wanted) if (!AVAILABLE_MODULES.includes(name)) throw new ModuleNotAvailableError(name);
    const done: Partial<Record<ModuleName, Address>> = {};
    for (const name of wanted) {
      if (await this.read<boolean>('isActive', [ModuleId[name]])) continue;
      await write(this.ctx, { address: this.address, abi: marketAbi, functionName: 'activateModule', args: [ModuleId[name]] } as never);
      done[name] = await this.read<Address>('moduleOf', [ModuleId[name]]);
    }
    return done;
  }

  deactivate(module: ModuleName) {
    return write(this.ctx, { address: this.address, abi: marketAbi, functionName: 'deactivateModule', args: [ModuleId[module]] } as never);
  }

  setConfig(config: MarketConfig) {
    return write(this.ctx, { address: this.address, abi: marketAbi, functionName: 'setConfig', args: [config] } as never);
  }

  setPaused(paused: boolean) {
    return write(this.ctx, { address: this.address, abi: marketAbi, functionName: 'setPaused', args: [paused] } as never);
  }

  /** Approves and routes `amount` of `token` through the market's fee split. */
  async routeFees(token: Address, amount: bigint) {
    await write(this.ctx, { address: token, abi: erc20Abi, functionName: 'approve', args: [this.address, amount] } as never);
    return write(this.ctx, { address: this.address, abi: marketAbi, functionName: 'routeFees', args: [token, amount] } as never);
  }

  private async module(name: ModuleName) {
    const [addr, active] = await Promise.all([this.read<Address>('moduleOf', [ModuleId[name]]), this.read<boolean>('isActive', [ModuleId[name]])]);
    if (!active || addr === zeroAddress) throw new ModuleInactiveError(name);
    return addr;
  }

  async treasury() { return new Treasury(this.ctx, await this.module('Treasury')); }
  async vault() { return new Vault(this.ctx, await this.module('Yield')); }
  async agents() { return new Agents(this.ctx, await this.module('Agents')); }
}
