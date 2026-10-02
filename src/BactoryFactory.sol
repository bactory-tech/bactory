// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IBactoryFactory} from "./interfaces/IBactoryFactory.sol";
import {IMarket} from "./interfaces/IMarket.sol";
import {ITreasuryModule} from "./interfaces/ITreasuryModule.sol";
import {IAgentGuard} from "./interfaces/IAgentGuard.sol";
import {YieldVault} from "./modules/YieldVault.sol";
import {BactoryErrors} from "./libraries/BactoryErrors.sol";
import {ModuleIds} from "./libraries/ModuleIds.sol";

/// @title BactoryFactory
/// @notice Builds one Bactory Market per (asset, quote) pair and deploys the modules markets ask for.
/// @dev Bactory does not create tokens: `buildMarket` only accepts an asset that already has code onchain.
contract BactoryFactory is IBactoryFactory, Ownable2Step {
    address public immutable marketImplementation;
    mapping(uint8 id => address implementation) public moduleImplementation;

    mapping(address asset => mapping(address quote => address market)) public marketOf;
    mapping(address market => bool) public isMarket;
    mapping(address quote => bool) public isQuoteAllowed;
    address[] internal _markets;

    constructor(
        address owner_,
        address marketImpl,
        address treasuryImpl,
        address vaultImpl,
        address guardImpl,
        address[] memory quotes
    ) Ownable(owner_) {
        if (marketImpl == address(0)) revert BactoryErrors.ZeroAddress();
        marketImplementation = marketImpl;
        _setImplementation(ModuleIds.TREASURY, treasuryImpl);
        _setImplementation(ModuleIds.YIELD, vaultImpl);
        _setImplementation(ModuleIds.AGENTS, guardImpl);
        for (uint256 i; i < quotes.length; ++i) {
            isQuoteAllowed[quotes[i]] = true;
            emit QuoteAllowed(quotes[i], true);
        }
    }

    // ---------------------------------------------------------------- build

    /// @inheritdoc IBactoryFactory
    /// @dev The caller becomes the market admin (the "market builder").
    function buildMarket(address asset, address quote, IMarket.Config calldata config)
        external
        returns (address market)
    {
        if (asset == address(0) || quote == address(0)) revert BactoryErrors.ZeroAddress();
        if (asset == quote) revert BactoryErrors.SameAssetAndQuote();
        if (asset.code.length == 0) revert BactoryErrors.NotAContract(asset);
        if (!isQuoteAllowed[quote]) revert BactoryErrors.QuoteNotAllowed(quote);
        address existing = marketOf[asset][quote];
        if (existing != address(0)) revert BactoryErrors.MarketExists(existing);

        market = Clones.cloneDeterministic(marketImplementation, _salt(asset, quote));
        IMarket(market).initialize(asset, quote, msg.sender, address(this), config);

        marketOf[asset][quote] = market;
        isMarket[market] = true;
        _markets.push(market);
        emit MarketBuilt(asset, quote, market, msg.sender);
    }

    /// @inheritdoc IBactoryFactory
    /// @dev Only callable by a market this factory built, during `Market.activateModule`.
    function deployModule(uint8 id) external returns (address module) {
        if (!isMarket[msg.sender]) revert BactoryErrors.NotAMarket(msg.sender);
        address impl = moduleImplementation[id];
        if (impl == address(0)) revert BactoryErrors.ModuleNotAvailable(id);

        module = Clones.clone(impl);
        if (id == ModuleIds.TREASURY) {
            ITreasuryModule(module).initialize(msg.sender);
        } else if (id == ModuleIds.YIELD) {
            address quote = IMarket(msg.sender).quote();
            string memory sym = _symbol(IMarket(msg.sender).asset());
            YieldVault(module)
                .initialize(msg.sender, quote, string.concat("Bactory ", sym, " Yield"), string.concat("bv", sym));
        } else {
            IAgentGuard(module).initialize(msg.sender);
        }
        emit ModuleDeployed(msg.sender, id, module);
    }

    // ---------------------------------------------------------------- owner

    function setQuoteAllowed(address quote, bool allowed) external onlyOwner {
        if (quote == address(0)) revert BactoryErrors.ZeroAddress();
        isQuoteAllowed[quote] = allowed;
        emit QuoteAllowed(quote, allowed);
    }

    /// @notice Points new modules of `id` at a new implementation. Existing modules are not touched.
    function setModuleImplementation(uint8 id, address implementation) external onlyOwner {
        _setImplementation(id, implementation);
    }

    // ---------------------------------------------------------------- views

    function allMarkets() external view returns (address[] memory) {
        return _markets;
    }

    function marketCount() external view returns (uint256) {
        return _markets.length;
    }

    /// @notice Address a market for (asset, quote) will have, before it is built.
    function predictMarket(address asset, address quote) external view returns (address) {
        return Clones.predictDeterministicAddress(marketImplementation, _salt(asset, quote));
    }

    // ---------------------------------------------------------------- internal

    function _setImplementation(uint8 id, address implementation) internal {
        if (!ModuleIds.isAvailable(id)) revert BactoryErrors.ModuleNotAvailable(id);
        if (implementation == address(0)) revert BactoryErrors.ZeroAddress();
        moduleImplementation[id] = implementation;
        emit ImplementationSet(id, implementation);
    }

    function _salt(address asset, address quote) internal pure returns (bytes32) {
        return keccak256(abi.encode(asset, quote));
    }

    function _symbol(address token) internal view returns (string memory) {
        try IERC20Metadata(token).symbol() returns (string memory s) {
            return bytes(s).length > 0 && bytes(s).length <= 16 ? s : "ASSET";
        } catch {
            return "ASSET";
        }
    }
}
