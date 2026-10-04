import { spawn, type ChildProcess } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { createPublicClient, createWalletClient, http, type Abi, type Address, type Hex } from 'viem';
import { mnemonicToAccount } from 'viem/accounts';
import { foundry } from 'viem/chains';

const OUT = join(__dirname, '..', '..', 'out');
export const RPC = 'http://127.0.0.1:8549';

// Anvil's default dev mnemonic (public, test-only): account 0 builds, account 1 is the agent.
const MNEMONIC = 'test test test test test test test test test test test junk';
export const BUILDER = mnemonicToAccount(MNEMONIC, { addressIndex: 0 });
export const AGENT = mnemonicToAccount(MNEMONIC, { addressIndex: 1 });

export function artifact(file: string, name: string) {
  const j = JSON.parse(readFileSync(join(OUT, file, `${name}.json`), 'utf8'));
  return { abi: j.abi as Abi, bytecode: j.bytecode.object as Hex };
}

/** Starts a local anvil on chain id 84532 so the SDK treats it as Base Sepolia. */
export async function startAnvil(): Promise<ChildProcess> {
  const p = spawn('anvil', ['--port', '8549', '--chain-id', '84532', '--silent'], { stdio: 'ignore' });
  for (let i = 0; i < 50; i++) {
    try { await fetch(RPC, { method: 'POST', headers: { 'content-type': 'application/json' }, body: '{"jsonrpc":"2.0","id":1,"method":"eth_chainId"}' }); return p; }
    catch { await new Promise(r => setTimeout(r, 200)); }
  }
  throw new Error('anvil did not start');
}

const chain = { ...foundry, id: 84532 };
export const publicClient = createPublicClient({ chain, transport: http(RPC), pollingInterval: 50 });
export const builderWallet = createWalletClient({ account: BUILDER, chain, transport: http(RPC), pollingInterval: 50 });
export const agentWallet = createWalletClient({ account: AGENT, chain, transport: http(RPC), pollingInterval: 50 });

export async function deploy(file: string, name: string, args: unknown[] = []): Promise<Address> {
  const { abi, bytecode } = artifact(file, name);
  const hash = await builderWallet.deployContract({ abi, bytecode, args } as never);
  const r = await publicClient.waitForTransactionReceipt({ hash });
  return r.contractAddress!;
}
