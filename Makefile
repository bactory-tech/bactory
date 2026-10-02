-include .env

.PHONY: install build test test-ci coverage fmt snapshot sdk-install sdk-test deploy-sepolia build-market-sepolia

install:
	forge install foundry-rs/forge-std OpenZeppelin/openzeppelin-contracts@v5.1.0 OpenZeppelin/openzeppelin-contracts-upgradeable@v5.1.0

build:
	forge build

test:
	forge test -vv

test-ci:
	FOUNDRY_PROFILE=ci forge test -vv

coverage:
	forge coverage --report summary --no-match-coverage "(test|script)/"

fmt:
	forge fmt

snapshot:
	forge snapshot

sdk-install:
	cd sdk && npm install

sdk-test: build
	cd sdk && npm run abis && npm run typecheck && npm test

deploy-sepolia:
	forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify

build-market-sepolia:
	forge script script/BuildMarket.s.sol --rpc-url base_sepolia --broadcast
