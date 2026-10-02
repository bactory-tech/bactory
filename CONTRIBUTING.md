# Contributing

1. Fork and branch from `main`.
2. `make install && make build && make test` must pass.
3. New behaviour needs a test in `test/unit` (and a fuzz or invariant test when it touches balances).
4. Run `forge fmt` before committing.
5. SDK changes: `make sdk-test`.
6. Keep the language of the product: Bactory **connects** assets and **builds** markets. It never launches or creates tokens.

## Layout conventions

- One contract per file; interfaces in `src/interfaces`, named `I<Name>`.
- Custom errors live in `src/libraries/BactoryErrors.sol`.
- Basis points everywhere (`10_000 = 100%`), via `src/libraries/Bps.sol`.
- Tests: `test_<what>` for unit, `test_revert_<what>` for failures, `testFuzz_` and `invariant_` prefixes.
