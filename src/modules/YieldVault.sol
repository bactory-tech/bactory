// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

import {MarketModule} from "./MarketModule.sol";

/// @title YieldVault
/// @notice ERC-4626 vault on the market's quote token. Fees the market routes here raise the share price,
///         so every depositor earns from market activity in proportion to their shares.
/// @dev A decimals offset of 6 makes share-inflation (donation) attacks uneconomic for small first deposits.
contract YieldVault is ERC4626Upgradeable, MarketModule {
    event FeesReceived(uint256 assetsAfter);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address market_, address quote, string calldata name_, string calldata symbol_)
        external
        initializer
    {
        __MarketModule_init(market_);
        __ERC20_init(name_, symbol_);
        __ERC4626_init(IERC20(quote));
    }

    /// @dev Deposits pause with the market; withdrawals never do, so depositors can always leave.
    function maxDeposit(address receiver) public view override returns (uint256) {
        return _market.paused() ? 0 : super.maxDeposit(receiver);
    }

    function maxMint(address receiver) public view override returns (uint256) {
        return _market.paused() ? 0 : super.maxMint(receiver);
    }

    /// @notice Assets per one whole share, scaled to the asset's decimals.
    function sharePrice() external view returns (uint256) {
        return convertToAssets(10 ** decimals());
    }

    function _decimalsOffset() internal pure override returns (uint8) {
        return 6;
    }
}
