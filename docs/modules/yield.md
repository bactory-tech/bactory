# Yield module

An ERC-4626 vault on the market's quote token (for example USDC).

- Anyone can deposit the quote token and receive shares (`bv<ASSET>`, 12 decimals for a 6-decimal quote).
- `Market.routeFees` sends `lpBps` of quote-token fees straight into the vault. No shares are minted for them, so the **share price rises** and every depositor earns pro rata.
- `sharePrice()` returns the assets one whole share is worth.

## Safety

- **Decimals offset of 6**: a first depositor cannot profitably inflate the share price to steal later deposits.
- **Pause**: when the market is paused, `maxDeposit`/`maxMint` return 0. Withdrawals and redemptions keep working.

## Using it as a treasury strategy

`VaultStrategy(treasury, vault)` lets a market's treasury park idle quote in its own vault, so treasury capital also earns the LP fee stream.
