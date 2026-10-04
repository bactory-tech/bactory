import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { ChildProcess } from 'node:child_process';
import { getAddress, parseUnits, type Address } from 'viem';
import { createBactory, ModuleNotAvailableError, type Bactory } from '../src/index.js';
import { AGENT, BUILDER, agentWallet, artifact, builderWallet, deploy, publicClient, startAnvil } from './helpers.js';

let anvil: ChildProcess;
let bactory: Bactory;
let asset: Address;
let usdc: Address;
const erc20 = artifact('MockERC20.sol', 'MockERC20').abi;

async function mint(token: Address, to: Address, amount: bigint) {
  const hash = await builderWallet.writeContract({ address: token, abi: erc20, functionName: 'mint', args: [to, amount] } as never);
  await publicClient.waitForTransactionReceipt({ hash });
}

beforeAll(async () => {
  anvil = await startAnvil();
  asset = await deploy('MockERC20.sol', 'MockERC20', ['Aerodrome', 'AERO', 18]);
  usdc = await deploy('MockERC20.sol', 'MockERC20', ['USD Coin', 'USDC', 6]);
  const factory = await deploy('BactoryFactory.sol', 'BactoryFactory', [
    BUILDER.address,
    await deploy('Market.sol', 'Market'),
    await deploy('TreasuryModule.sol', 'TreasuryModule'),
    await deploy('YieldVault.sol', 'YieldVault'),
    await deploy('AgentGuard.sol', 'AgentGuard'),
    [usdc],
  ]);
  bactory = await createBactory({ publicClient, walletClient: builderWallet, factory });
});

afterAll(() => anvil?.kill());

describe('Bactory SDK', () => {
  it('builds a market around an existing asset, once', async () => {
    expect(await bactory.findMarket({ asset, quote: usdc })).toBeNull();
    const m = await bactory.market({ asset, quote: usdc });
    const again = await bactory.market({ asset, quote: usdc });
    expect(again.address).toBe(m.address);
    const s = await m.state();
    expect(getAddress(s.asset)).toBe(getAddress(asset));
    expect(s.admin).toBe(BUILDER.address);
    expect(s.config.lpBps).toBe(5000);
  });

  it('activates modules and refuses planned ones', async () => {
    const m = await bactory.market({ asset, quote: usdc });
    await expect(m.activate({ liquidity: true })).rejects.toBeInstanceOf(ModuleNotAvailableError);
    const done = await m.activate({ treasury: true, yield: true, agents: true });
    expect(Object.keys(done).sort()).toEqual(['Agents', 'Treasury', 'Yield']);
    const s = await m.state();
    expect(s.modules.Treasury.active && s.modules.Yield.active && s.modules.Agents.active).toBe(true);
    expect(s.modules.Liquidity.active).toBe(false);
  });

  it('routes fees and pays vault depositors', async () => {
    const m = await bactory.market({ asset, quote: usdc });
    const vault = await m.vault();
    await mint(usdc, BUILDER.address, parseUnits('2000', 6));
    await vault.deposit(parseUnits('1000', 6));
    await m.routeFees(usdc, parseUnits('200', 6)); // 100 to the vault
    const pos = await vault.positionOf(BUILDER.address);
    expect(pos.assets).toBeGreaterThanOrEqual(parseUnits('1099', 6));
  });

  it('lets an agent propose and enforces the limits', async () => {
    const m = await bactory.market({ asset, quote: usdc });
    const treasury = await m.treasury();
    const agents = await m.agents();
    const strategy = await deploy('HoldStrategy.sol', 'HoldStrategy', [treasury.address]);
    await treasury.approveStrategy(strategy);
    await mint(usdc, treasury.address, parseUnits('10000', 6));
    await agents.register(AGENT.address, 4);

    const asAgent = await createBactory({ publicClient, walletClient: agentWallet, factory: bactory.factory });
    const agentGuard = await asAgent.at(m.address).agents();

    const big = { kind: 'allocate' as const, strategy, token: usdc, amount: parseUnits('9000', 6) };
    expect(await agentGuard.preview(AGENT.address, big)).toBe('ExceedsActionLimit');
    const rejected = await agentGuard.propose(big);
    expect(rejected.executed).toBe(false);
    expect(rejected.reason).toBe('ExceedsActionLimit');

    const ok = await agentGuard.propose({ ...big, amount: parseUnits('1000', 6) });
    expect(ok.executed).toBe(true);
    expect(await treasury.allocatedTo(strategy, usdc)).toBe(parseUnits('1000', 6));
    expect((await agents.info(AGENT.address)).strikes).toBe(1);
  });
});
