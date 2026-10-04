# Fee routing

`Market.routeFees(token, amount)` pulls `amount` of `token` from the caller and splits it by the market config:

| Config field | Receives |
|---|---|
| `lpBps` | the YieldVault (raises its share price) |
| `treasuryBps` | the TreasuryModule |
| `builderBps` | `config.builder` |

The three shares must add up to `10_000` (100%). The builder's part takes the rounding dust, so the parts always add up to `amount` exactly.

## Fallbacks

No fee is ever stuck in the market:

1. The vault only accepts the market's **quote** token. If the vault is inactive, or the token is not the quote, the vault's share goes to the treasury.
2. If the treasury is inactive, its share (including anything it received from step 1) goes to the builder.

## Who calls it

Anyone: a Uniswap v4 hook (planned Liquidity module), a keeper that collects LP fees, or the builder sending revenue by hand.

## Limits in the same config

| Field | Max | Used by |
|---|---|---|
| `maxActionBps` | 5,000 (50%) | Treasury: most one action may move |
| `reserveBps` | 10,000 | Treasury: share of value that must stay idle |
| `slippageBps` | 500 (5%) | Swap-based strategies |
