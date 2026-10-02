// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IMarket} from "../interfaces/IMarket.sol";
import {BactoryErrors} from "../libraries/BactoryErrors.sol";

/// @title MarketModule
/// @notice Shared base for modules: each module belongs to exactly one market and follows its admin.
abstract contract MarketModule is Initializable {
    IMarket internal _market;

    modifier onlyMarketAdmin() {
        if (msg.sender != _market.admin()) revert BactoryErrors.NotMarketAdmin(msg.sender);
        _;
    }

    modifier whenMarketLive() {
        if (_market.paused()) revert BactoryErrors.MarketPaused();
        _;
    }

    function __MarketModule_init(address market_) internal onlyInitializing {
        if (market_ == address(0)) revert BactoryErrors.ZeroAddress();
        _market = IMarket(market_);
    }

    /// @notice The market this module belongs to.
    function market() public view virtual returns (address) {
        return address(_market);
    }
}
