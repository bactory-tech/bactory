// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title NetworkConfig
/// @notice Addresses of the existing Base contracts Bactory builds on.
library NetworkConfig {
    uint256 internal constant BASE = 8453;
    uint256 internal constant BASE_SEPOLIA = 84532;

    struct Network {
        address usdc;
        address weth;
        address ethUsdFeed; // Chainlink ETH / USD
        address sequencerFeed; // Chainlink L2 sequencer uptime (mainnet only)
        address uniswapV4PoolManager;
    }

    function get(uint256 chainId) internal pure returns (Network memory n) {
        if (chainId == BASE) {
            n = Network({
                usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
                weth: 0x4200000000000000000000000000000000000006,
                ethUsdFeed: 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70,
                sequencerFeed: 0xBCF85224fc0756B9Fa45aA7892530B47e10b6433,
                uniswapV4PoolManager: 0x498581fF718922c3f8e6A244956aF099B2652b2b
            });
        } else if (chainId == BASE_SEPOLIA) {
            n = Network({
                usdc: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
                weth: 0x4200000000000000000000000000000000000006,
                ethUsdFeed: 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1,
                sequencerFeed: address(0),
                uniswapV4PoolManager: 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
            });
        } else {
            revert("NetworkConfig: unsupported chain");
        }
    }
}
