// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {BactoryFactory} from "../src/BactoryFactory.sol";
import {Market} from "../src/Market.sol";
import {TreasuryModule} from "../src/modules/TreasuryModule.sol";
import {YieldVault} from "../src/modules/YieldVault.sol";
import {AgentGuard} from "../src/modules/AgentGuard.sol";
import {NetworkConfig} from "./config/NetworkConfig.sol";

/// @notice Deploys the implementations and the factory, with USDC and WETH as allowed quotes.
/// Usage: forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --verify
contract Deploy is Script {
    function run() external returns (BactoryFactory factory) {
        NetworkConfig.Network memory net = NetworkConfig.get(block.chainid);
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envOr("FACTORY_OWNER", vm.addr(pk));

        address[] memory quotes = new address[](2);
        quotes[0] = net.usdc;
        quotes[1] = net.weth;

        vm.startBroadcast(pk);
        Market marketImpl = new Market();
        TreasuryModule treasuryImpl = new TreasuryModule();
        YieldVault vaultImpl = new YieldVault();
        AgentGuard guardImpl = new AgentGuard();
        factory = new BactoryFactory(
            owner, address(marketImpl), address(treasuryImpl), address(vaultImpl), address(guardImpl), quotes
        );
        vm.stopBroadcast();

        console2.log("chain", block.chainid);
        console2.log("BactoryFactory", address(factory));
        console2.log("Market impl", address(marketImpl));
        console2.log("TreasuryModule impl", address(treasuryImpl));
        console2.log("YieldVault impl", address(vaultImpl));
        console2.log("AgentGuard impl", address(guardImpl));
    }
}
