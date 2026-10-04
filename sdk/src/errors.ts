import { BaseError, ContractFunctionRevertedError } from 'viem';

/** Thrown when an action needs a module that is not active on the market. */
export class ModuleInactiveError extends Error {
  constructor(public readonly module: string) {
    super(`Bactory: the ${module} module is not active on this market. Activate it first.`);
  }
}

/** Thrown when a planned module (Liquidity, Bounties, Community) is requested. */
export class ModuleNotAvailableError extends Error {
  constructor(public readonly module: string) {
    super(`Bactory: the ${module} module is planned and cannot be activated yet.`);
  }
}

/** Thrown when a write is attempted without a wallet client. */
export class NoWalletError extends Error {
  constructor() {
    super('Bactory: this action sends a transaction; pass a walletClient to createBactory.');
  }
}

/** Returns the custom error name (e.g. "ExceedsActionLimit") from a viem contract error, if any. */
export function revertName(err: unknown): string | null {
  if (err instanceof BaseError) {
    const revert = err.walk(e => e instanceof ContractFunctionRevertedError);
    if (revert instanceof ContractFunctionRevertedError) return revert.data?.errorName ?? null;
  }
  return null;
}
