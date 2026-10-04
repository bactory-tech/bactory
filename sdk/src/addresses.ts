import type { Address } from 'viem';

/** Existing Base contracts Bactory builds on (same values as script/config/NetworkConfig.sol). */
export const NETWORKS = {
  8453: {
    name: 'Base',
    usdc: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    weth: '0x4200000000000000000000000000000000000006',
    ethUsdFeed: '0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70',
    sequencerFeed: '0xBCF85224fc0756B9Fa45aA7892530B47e10b6433',
    uniswapV4PoolManager: '0x498581fF718922c3f8e6A244956aF099B2652b2b',
  },
  84532: {
    name: 'Base Sepolia',
    usdc: '0x036CbD53842c5426634e7929541eC2318f3dCF7e',
    weth: '0x4200000000000000000000000000000000000006',
    ethUsdFeed: '0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1',
    sequencerFeed: '0x0000000000000000000000000000000000000000',
    uniswapV4PoolManager: '0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408',
  },
} as const satisfies Record<number, { name: string; usdc: Address; weth: Address; ethUsdFeed: Address; sequencerFeed: Address; uniswapV4PoolManager: Address }>;

export type SupportedChainId = keyof typeof NETWORKS;

/**
 * BactoryFactory deployments. Empty until the protocol is deployed;
 * pass `factory` to `createBactory` to use your own deployment.
 */
export const FACTORIES: Partial<Record<SupportedChainId, Address>> = {};

export function network(chainId: number) {
  const n = NETWORKS[chainId as SupportedChainId];
  if (!n) throw new Error(`Bactory: chain ${chainId} is not supported (use Base 8453 or Base Sepolia 84532)`);
  return n;
}
