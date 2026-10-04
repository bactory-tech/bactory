import { describe, expect, it } from 'vitest';
import { AVAILABLE_MODULES, DEFAULT_LIMITS, ModuleId, NETWORKS, Rejection, network } from '../src/index.js';

describe('constants', () => {
  it('module ids match ModuleIds.sol', () => {
    expect(ModuleId).toEqual({ Treasury: 1, Yield: 2, Agents: 3, Liquidity: 4, Bounties: 5, Community: 6 });
    expect(AVAILABLE_MODULES).toEqual(['Treasury', 'Yield', 'Agents']);
  });

  it('rejection reasons match IAgentGuard.Rejection order', () => {
    expect(Rejection[0]).toBe('None');
    expect(Rejection[5]).toBe('ExceedsActionLimit');
    expect(Rejection).toHaveLength(9);
  });

  it('default fee split adds up to 100%', () => {
    expect(DEFAULT_LIMITS.lpBps + DEFAULT_LIMITS.treasuryBps + DEFAULT_LIMITS.builderBps).toBe(10_000);
  });
});

describe('networks', () => {
  it('knows Base and Base Sepolia', () => {
    expect(network(8453).name).toBe('Base');
    expect(network(84532).usdc).toBe(NETWORKS[84532].usdc);
  });

  it('refuses other chains', () => {
    expect(() => network(1)).toThrow(/not supported/);
  });
});
