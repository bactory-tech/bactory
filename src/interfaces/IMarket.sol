// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IMarket
/// @notice A Bactory Market: the coordination layer around one existing asset.
interface IMarket {
    /// @notice Fee routing and strategy limits, set when the market is built and editable by its admin.
    struct Config {
        uint16 lpBps; // share of routed fees sent to the yield vault
        uint16 treasuryBps; // share sent to the treasury module
        uint16 builderBps; // share sent to the market builder
        address builder; // receives the builder share
        uint16 maxActionBps; // max share of a treasury balance one action may move
        uint16 slippageBps; // max slippage for actions that swap
        uint16 reserveBps; // share of a treasury balance that must stay idle
    }

    event FeesRouted(
        address indexed token, address indexed from, uint256 toVault, uint256 toTreasury, uint256 toBuilder
    );
    event ModuleActivated(uint8 indexed id, address module);
    event ModuleDeactivated(uint8 indexed id);
    event ConfigUpdated(Config config);
    event AdminTransferStarted(address indexed currentAdmin, address indexed pendingAdmin);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event Paused(bool paused);

    function initialize(address asset, address quote, address admin, address factory, Config calldata config) external;

    function asset() external view returns (address);
    function quote() external view returns (address);
    function admin() external view returns (address);
    function factory() external view returns (address);
    function paused() external view returns (bool);
    function config() external view returns (Config memory);
    function moduleOf(uint8 id) external view returns (address);
    function isActive(uint8 id) external view returns (bool);

    function routeFees(address token, uint256 amount) external;
    function activateModule(uint8 id) external returns (address module);
    function deactivateModule(uint8 id) external;
    function setConfig(Config calldata config) external;
    function setPaused(bool paused) external;
    function transferAdmin(address newAdmin) external;
    function acceptAdmin() external;
}
