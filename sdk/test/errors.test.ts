import { describe, expect, it } from 'vitest';
import { ModuleInactiveError, ModuleNotAvailableError, NoWalletError, revertName } from '../src/index.js';

describe('errors', () => {
  it('carry clear messages', () => {
    expect(new ModuleInactiveError('Yield').message).toMatch(/Yield module is not active/);
    expect(new ModuleNotAvailableError('Liquidity').message).toMatch(/planned/);
    expect(new NoWalletError().message).toMatch(/walletClient/);
  });

  it('revertName returns null for non-contract errors', () => {
    expect(revertName(new Error('x'))).toBeNull();
  });
});
