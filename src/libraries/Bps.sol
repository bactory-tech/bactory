// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Bps
/// @notice Basis-point helpers. 10_000 bps = 100%.
library Bps {
    uint256 internal constant DENOMINATOR = 10_000;

    /// @notice `amount * bps / 10_000`, rounded down.
    function mul(uint256 amount, uint256 bps) internal pure returns (uint256) {
        return amount * bps / DENOMINATOR;
    }

    /// @notice Splits `amount` into three parts by bps. The last part takes the rounding dust,
    ///         so the parts always add up to `amount` exactly.
    function split3(uint256 amount, uint256 aBps, uint256 bBps)
        internal
        pure
        returns (uint256 a, uint256 b, uint256 c)
    {
        a = mul(amount, aBps);
        b = mul(amount, bBps);
        c = amount - a - b;
    }
}
