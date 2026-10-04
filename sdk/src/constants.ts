/** Module ids, matching src/libraries/ModuleIds.sol. */
export const ModuleId = {
  Treasury: 1,
  Yield: 2,
  Agents: 3,
  Liquidity: 4,
  Bounties: 5,
  Community: 6,
} as const;
export type ModuleName = keyof typeof ModuleId;

/** Modules the current factory can deploy. The rest are planned. */
export const AVAILABLE_MODULES: readonly ModuleName[] = ['Treasury', 'Yield', 'Agents'];

/** Why AgentGuard rejected a proposal, matching IAgentGuard.Rejection. */
export const Rejection = [
  'None',
  'AgentSuspended',
  'RateLimited',
  'OracleNotFresh',
  'StrategyNotApproved',
  'ExceedsActionLimit',
  'BreaksReserve',
  'InsufficientAllocation',
  'MarketPaused',
] as const;
export type RejectionReason = (typeof Rejection)[number];

export const ActionKind = { Allocate: 0, Recall: 1 } as const;

export const BPS = 10_000;

/** Default market config used when a builder does not pass one. */
export const DEFAULT_LIMITS = {
  lpBps: 5_000,
  treasuryBps: 3_500,
  builderBps: 1_500,
  maxActionBps: 2_500,
  slippageBps: 50,
  reserveBps: 3_000,
} as const;
