import { type Address, decodeEventLog } from 'viem';
import { agentGuardAbi } from './abis/index.js';
import { ActionKind, Rejection, type RejectionReason } from './constants.js';
import { type BactoryContext, write } from './context.js';
import type { AgentAction, ProposalResult } from './types.js';

const toTuple = (a: AgentAction) => ({ kind: ActionKind[a.kind === 'allocate' ? 'Allocate' : 'Recall'], strategy: a.strategy, token: a.token, amount: a.amount });

/** The market's AgentGuard. Agents propose; the contract enforces. */
export class Agents {
  constructor(private readonly ctx: BactoryContext, public readonly address: Address) {}

  async info(agent: Address) {
    const i = (await this.ctx.publicClient.readContract({ address: this.address, abi: agentGuardAbi, functionName: 'agentInfo', args: [agent] })) as {
      registered: boolean; suspended: boolean; maxPerDay: number; usedToday: number; accepted: number; rejected: number; strikes: number;
    };
    return { ...i };
  }

  /** Runs every guard check for `agent` without executing anything. */
  async preview(agent: Address, action: AgentAction): Promise<RejectionReason> {
    const r = (await this.ctx.publicClient.readContract({ address: this.address, abi: agentGuardAbi, functionName: 'preview', args: [agent, toTuple(action)] })) as number;
    return Rejection[Number(r)];
  }

  /** Submits a proposal from the connected wallet (which must be a registered agent). */
  async propose(action: AgentAction): Promise<ProposalResult> {
    const { hash, receipt } = await write(this.ctx, { address: this.address, abi: agentGuardAbi, functionName: 'propose', args: [toTuple(action)] } as never);
    for (const log of receipt.logs) {
      if (log.address.toLowerCase() !== this.address.toLowerCase()) continue;
      try {
        const ev = decodeEventLog({ abi: agentGuardAbi, data: log.data, topics: log.topics as [`0x${string}`, ...`0x${string}`[]] });
        if (ev.eventName === 'ProposalExecuted') return { hash, executed: true, reason: 'None', proposalId: (ev.args as { id: bigint }).id };
        if (ev.eventName === 'ProposalRejected') {
          const a = ev.args as { id: bigint; reason: number };
          return { hash, executed: false, reason: Rejection[Number(a.reason)], proposalId: a.id };
        }
      } catch { /* not a guard event */ }
    }
    throw new Error('Bactory: proposal mined but no guard event was found');
  }

  register(agent: Address, maxPerDay = 4) {
    return write(this.ctx, { address: this.address, abi: agentGuardAbi, functionName: 'registerAgent', args: [agent, maxPerDay] } as never);
  }

  remove(agent: Address) {
    return write(this.ctx, { address: this.address, abi: agentGuardAbi, functionName: 'removeAgent', args: [agent] } as never);
  }

  reinstate(agent: Address) {
    return write(this.ctx, { address: this.address, abi: agentGuardAbi, functionName: 'reinstateAgent', args: [agent] } as never);
  }

  /** Requires a fresh price on every proposal (and, on Base mainnet, a live sequencer). */
  setOracle(feed: Address, maxAgeSeconds: number, sequencerFeed: Address) {
    return write(this.ctx, { address: this.address, abi: agentGuardAbi, functionName: 'setOracle', args: [feed, maxAgeSeconds, sequencerFeed] } as never);
  }
}
