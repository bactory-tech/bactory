// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AgentGuard} from "../src/modules/AgentGuard.sol";
import {TreasuryModule} from "../src/modules/TreasuryModule.sol";
import {HoldStrategy} from "../src/strategies/HoldStrategy.sol";
import {NetworkConfig} from "./config/NetworkConfig.sol";

/// @notice Registers an agent on a market's guard, wires the ETH/USD freshness check
///         and approves a HoldStrategy the agent may allocate to.
/// Env: PRIVATE_KEY (market admin), GUARD, TREASURY, AGENT, optional MAX_PER_DAY (default 4).
contract SetupAgent is Script {
    function run() external {
        NetworkConfig.Network memory net = NetworkConfig.get(block.chainid);
        uint256 pk = vm.envUint("PRIVATE_KEY");
        AgentGuard guard = AgentGuard(vm.envAddress("GUARD"));
        TreasuryModule treasury = TreasuryModule(vm.envAddress("TREASURY"));
        address agent = vm.envAddress("AGENT");
        uint16 maxPerDay = uint16(vm.envOr("MAX_PER_DAY", uint256(4)));

        vm.startBroadcast(pk);
        guard.registerAgent(agent, maxPerDay);
        guard.setOracle(net.ethUsdFeed, 1 hours, net.sequencerFeed);
        HoldStrategy strategy = new HoldStrategy(address(treasury));
        treasury.approveStrategy(address(strategy), true);
        vm.stopBroadcast();

        console2.log("Agent registered", agent);
        console2.log("HoldStrategy", address(strategy));
    }
}
