// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ITreasuryModule
/// @notice Market-owned capital under onchain rules.
interface ITreasuryModule {
    event StrategyApproved(address indexed strategy, bool approved);
    event Allocated(address indexed strategy, address indexed token, uint256 amount, address indexed by);
    event Recalled(address indexed strategy, address indexed token, uint256 amount, address indexed by);
    event Withdrawn(address indexed token, uint256 amount, address indexed to);
    event Distributed(address indexed token, uint256 total, uint256 recipients);

    function initialize(address market) external;
    function market() external view returns (address);

    function idle(address token) external view returns (uint256);
    function allocated(address strategy, address token) external view returns (uint256);
    function totalValue(address token) external view returns (uint256);
    function isApproved(address strategy) external view returns (bool);
    function actionLimit(address token) external view returns (uint256);

    function approveStrategy(address strategy, bool approved) external;
    function allocate(address strategy, address token, uint256 amount) external;
    function recall(address strategy, address token, uint256 amount) external;
    function withdraw(address token, uint256 amount, address to) external;
    function distribute(address token, address[] calldata recipients, uint256[] calldata amounts) external;
}
