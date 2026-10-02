// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IMarket} from "./interfaces/IMarket.sol";
import {IBactoryFactory} from "./interfaces/IBactoryFactory.sol";
import {BactoryErrors} from "./libraries/BactoryErrors.sol";
import {ModuleIds} from "./libraries/ModuleIds.sol";
import {Bps} from "./libraries/Bps.sol";

/// @title Market
/// @notice The coordination layer between an existing asset and the modules built around it.
/// @dev Deployed as a minimal proxy by `BactoryFactory`. Holds no funds between calls:
///      fees pass straight through to the vault, the treasury and the builder.
contract Market is IMarket, Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    uint16 public constant MAX_ACTION_BPS = 5_000; // one action moves at most 50% of a balance
    uint16 public constant MAX_SLIPPAGE_BPS = 500; // 5%

    address public asset;
    address public quote;
    address public admin;
    address public pendingAdmin;
    address public factory;
    bool public paused;

    Config internal _config;
    mapping(uint8 id => address module) public moduleOf;
    mapping(uint8 id => bool active) public isActive;

    modifier onlyAdmin() {
        if (msg.sender != admin) revert BactoryErrors.NotMarketAdmin(msg.sender);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IMarket
    function initialize(address asset_, address quote_, address admin_, address factory_, Config calldata config_)
        external
        initializer
    {
        if (asset_ == address(0) || quote_ == address(0) || admin_ == address(0) || factory_ == address(0)) {
            revert BactoryErrors.ZeroAddress();
        }
        __ReentrancyGuard_init();
        asset = asset_;
        quote = quote_;
        admin = admin_;
        factory = factory_;
        _setConfig(config_);
    }

    // ---------------------------------------------------------------- views

    /// @inheritdoc IMarket
    function config() external view returns (Config memory) {
        return _config;
    }

    // ---------------------------------------------------------------- fees

    /// @inheritdoc IMarket
    /// @dev Anyone can route fees in (a pool hook, a keeper, the builder). The split follows `config`.
    ///      The vault only takes the quote token; anything it cannot take goes to the treasury,
    ///      and anything the treasury cannot take goes to the builder, so no fee is ever stuck.
    function routeFees(address token, uint256 amount) external nonReentrant {
        if (paused) revert BactoryErrors.MarketPaused();
        if (amount == 0) revert BactoryErrors.ZeroAmount();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        (uint256 toVault, uint256 toTreasury, uint256 toBuilder) =
            Bps.split3(amount, _config.lpBps, _config.treasuryBps);

        address vault = isActive[ModuleIds.YIELD] && token == quote ? moduleOf[ModuleIds.YIELD] : address(0);
        if (vault == address(0)) (toTreasury, toVault) = (toTreasury + toVault, 0);

        address treasury = isActive[ModuleIds.TREASURY] ? moduleOf[ModuleIds.TREASURY] : address(0);
        if (treasury == address(0)) (toBuilder, toTreasury) = (toBuilder + toTreasury, 0);

        if (toVault > 0) IERC20(token).safeTransfer(vault, toVault);
        if (toTreasury > 0) IERC20(token).safeTransfer(treasury, toTreasury);
        if (toBuilder > 0) IERC20(token).safeTransfer(_config.builder, toBuilder);

        emit FeesRouted(token, msg.sender, toVault, toTreasury, toBuilder);
    }

    // ---------------------------------------------------------------- modules

    /// @inheritdoc IMarket
    /// @dev First activation deploys the module through the factory; later activations reuse it.
    function activateModule(uint8 id) external onlyAdmin returns (address module) {
        if (!ModuleIds.isAvailable(id)) revert BactoryErrors.ModuleNotAvailable(id);
        if (isActive[id]) revert BactoryErrors.ModuleAlreadyActive(id);
        module = moduleOf[id];
        if (module == address(0)) {
            module = IBactoryFactory(factory).deployModule(id);
            moduleOf[id] = module;
        }
        isActive[id] = true;
        emit ModuleActivated(id, module);
    }

    /// @inheritdoc IMarket
    function deactivateModule(uint8 id) external onlyAdmin {
        if (!isActive[id]) revert BactoryErrors.ModuleNotActive(id);
        isActive[id] = false;
        emit ModuleDeactivated(id);
    }

    // ---------------------------------------------------------------- admin

    /// @inheritdoc IMarket
    function setConfig(Config calldata config_) external onlyAdmin {
        _setConfig(config_);
    }

    /// @inheritdoc IMarket
    function setPaused(bool paused_) external onlyAdmin {
        paused = paused_;
        emit Paused(paused_);
    }

    /// @inheritdoc IMarket
    function transferAdmin(address newAdmin) external onlyAdmin {
        pendingAdmin = newAdmin;
        emit AdminTransferStarted(admin, newAdmin);
    }

    /// @inheritdoc IMarket
    function acceptAdmin() external {
        if (msg.sender != pendingAdmin) revert BactoryErrors.NotPendingAdmin(msg.sender);
        emit AdminTransferred(admin, msg.sender);
        admin = msg.sender;
        pendingAdmin = address(0);
    }

    function _setConfig(Config calldata c) internal {
        uint256 total = uint256(c.lpBps) + c.treasuryBps + c.builderBps;
        if (total != Bps.DENOMINATOR) revert BactoryErrors.InvalidFeeSplit(total);
        if (c.builder == address(0)) revert BactoryErrors.ZeroAddress();
        if (c.maxActionBps > MAX_ACTION_BPS) revert BactoryErrors.LimitTooHigh(c.maxActionBps, MAX_ACTION_BPS);
        if (c.slippageBps > MAX_SLIPPAGE_BPS) revert BactoryErrors.LimitTooHigh(c.slippageBps, MAX_SLIPPAGE_BPS);
        if (c.reserveBps > Bps.DENOMINATOR) revert BactoryErrors.LimitTooHigh(c.reserveBps, Bps.DENOMINATOR);
        _config = c;
        emit ConfigUpdated(c);
    }
}
