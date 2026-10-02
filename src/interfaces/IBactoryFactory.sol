// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IMarket} from "./IMarket.sol";

/// @title IBactoryFactory
/// @notice Builds markets around assets that already exist. It never creates tokens.
interface IBactoryFactory {
    event MarketBuilt(address indexed asset, address indexed quote, address indexed market, address admin);
    event QuoteAllowed(address indexed quote, bool allowed);
    event ModuleDeployed(address indexed market, uint8 indexed id, address module);
    event ImplementationSet(uint8 indexed id, address implementation);

    function buildMarket(address asset, address quote, IMarket.Config calldata config) external returns (address market);
    function deployModule(uint8 id) external returns (address module);

    function marketOf(address asset, address quote) external view returns (address);
    function isMarket(address market) external view returns (bool);
    function allMarkets() external view returns (address[] memory);
    function marketCount() external view returns (uint256);
    function isQuoteAllowed(address quote) external view returns (bool);
    function marketImplementation() external view returns (address);
    function moduleImplementation(uint8 id) external view returns (address);
}
