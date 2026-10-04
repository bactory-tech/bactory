export { bactoryFactoryAbi } from './BactoryFactory.js';
export { marketAbi } from './Market.js';
export { treasuryModuleAbi } from './TreasuryModule.js';
export { yieldVaultAbi } from './YieldVault.js';
export { agentGuardAbi } from './AgentGuard.js';
export { holdStrategyAbi } from './HoldStrategy.js';

/** Minimal ERC-20 ABI used for approvals and balances. */
export const erc20Abi = [
  { type: 'function', name: 'approve', stateMutability: 'nonpayable', inputs: [{ name: 'spender', type: 'address' }, { name: 'amount', type: 'uint256' }], outputs: [{ type: 'bool' }] },
  { type: 'function', name: 'allowance', stateMutability: 'view', inputs: [{ name: 'owner', type: 'address' }, { name: 'spender', type: 'address' }], outputs: [{ type: 'uint256' }] },
  { type: 'function', name: 'balanceOf', stateMutability: 'view', inputs: [{ name: 'account', type: 'address' }], outputs: [{ type: 'uint256' }] },
  { type: 'function', name: 'decimals', stateMutability: 'view', inputs: [], outputs: [{ type: 'uint8' }] },
  { type: 'function', name: 'symbol', stateMutability: 'view', inputs: [], outputs: [{ type: 'string' }] },
] as const;
