# Deployment

## Base Sepolia

1. `cp .env.example .env` and set `PRIVATE_KEY`, `BASE_SEPOLIA_RPC_URL`, `BASESCAN_API_KEY`.
2. Get Base Sepolia ETH from a faucet (Coinbase Developer Platform or Alchemy).
3. Deploy:

```bash
source .env
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify
```

The script prints the factory and the four implementation addresses. Record them in `deployments/README.md`.

4. Build a market around an existing asset (here WETH, quoted in USDC) and activate the modules:

```bash
FACTORY=0x... ASSET=0x4200000000000000000000000000000000000006 \
  forge script script/BuildMarket.s.sol --rpc-url base_sepolia --broadcast
```

5. Register an agent, set the Chainlink check and approve a strategy:

```bash
GUARD=0x... TREASURY=0x... AGENT=0x... \
  forge script script/SetupAgent.s.sol --rpc-url base_sepolia --broadcast
```

## Network addresses used

Defined once in `script/config/NetworkConfig.sol` and mirrored in `sdk/src/addresses.ts`.

| | Base (8453) | Base Sepolia (84532) |
|---|---|---|
| USDC | `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913` | `0x036CbD53842c5426634e7929541eC2318f3dCF7e` |
| WETH | `0x4200000000000000000000000000000000000006` | same |
| Chainlink ETH/USD | `0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70` | `0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1` |
| Sequencer uptime | `0xBCF85224fc0756B9Fa45aA7892530B47e10b6433` | — |
| Uniswap v4 PoolManager | `0x498581fF718922c3f8e6A244956aF099B2652b2b` | `0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408` |

## Mainnet

Not before an external audit.
