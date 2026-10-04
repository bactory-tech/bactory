// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {BactoryFactory} from "../src/BactoryFactory.sol";
import {IMarket} from "../src/interfaces/IMarket.sol";
import {ModuleIds} from "../src/libraries/ModuleIds.sol";
import {NetworkConfig} from "./config/NetworkConfig.sol";

/// @notice Builds a market around an existing asset and activates the core modules.
/// Env: PRIVATE_KEY, FACTORY, ASSET, optional QUOTE (defaults to USDC), optional MODULES ("treasury,yield,agents").
contract BuildMarket is Script {
    function run() external returns (address market) {
        NetworkConfig.Network memory net = NetworkConfig.get(block.chainid);
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address builder = vm.addr(pk);
        BactoryFactory factory = BactoryFactory(vm.envAddress("FACTORY"));
        address asset = vm.envAddress("ASSET");
        address quote = vm.envOr("QUOTE", net.usdc);
        string memory mods = vm.envOr("MODULES", string("treasury,yield,agents"));

        IMarket.Config memory c = IMarket.Config({
            lpBps: 5_000,
            treasuryBps: 3_500,
            builderBps: 1_500,
            builder: builder,
            maxActionBps: 2_500,
            slippageBps: 50,
            reserveBps: 3_000
        });

        vm.startBroadcast(pk);
        market = factory.buildMarket(asset, quote, c);
        IMarket m = IMarket(market);
        if (_has(mods, "treasury")) console2.log("TreasuryModule", m.activateModule(ModuleIds.TREASURY));
        if (_has(mods, "yield")) console2.log("YieldVault", m.activateModule(ModuleIds.YIELD));
        if (_has(mods, "agents")) console2.log("AgentGuard", m.activateModule(ModuleIds.AGENTS));
        vm.stopBroadcast();

        console2.log("Market", market);
    }

    function _has(string memory list, string memory item) internal pure returns (bool) {
        bytes memory l = bytes(list);
        bytes memory it = bytes(item);
        if (it.length > l.length) return false;
        for (uint256 i; i + it.length <= l.length; ++i) {
            bool hit = true;
            for (uint256 j; j < it.length; ++j) {
                if (l[i + j] != it[j]) {
                    hit = false;
                    break;
                }
            }
            if (hit) return true;
        }
        return false;
    }
}
