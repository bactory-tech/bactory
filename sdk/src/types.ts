import type { Address, Hash } from 'viem';
import type { ModuleName, RejectionReason } from './constants.js';

export interface MarketConfig {
  lpBps: number;
  treasuryBps: number;
  builderBps: number;
  builder: Address;
  maxActionBps: number;
  slippageBps: number;
  reserveBps: number;
}

export interface MarketState {
  address: Address;
  asset: Address;
  quote: Address;
  admin: Address;
  paused: boolean;
  config: MarketConfig;
  modules: Record<ModuleName, { address: Address | null; active: boolean }>;
}

export type ActivateOptions = Partial<Record<Lowercase<ModuleName>, boolean>>;

export interface AgentAction {
  kind: 'allocate' | 'recall';
  strategy: Address;
  token: Address;
  amount: bigint;
}

export interface ProposalResult {
  hash: Hash;
  executed: boolean;
  reason: RejectionReason;
  proposalId: bigint;
}
