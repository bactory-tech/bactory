// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAggregatorV3} from "../interfaces/IAggregatorV3.sol";

/// @title OracleLib
/// @notice Freshness checks for Chainlink feeds on an L2.
library OracleLib {
    /// @notice Grace period after the L2 sequencer comes back up, during which prices are not trusted.
    uint256 internal constant SEQUENCER_GRACE = 1 hours;

    enum Status {
        Ok,
        NoFeed,
        InvalidAnswer,
        Stale,
        SequencerDown,
        SequencerGrace
    }

    /// @notice Checks a price feed (and optionally the L2 sequencer uptime feed).
    /// @param feed Price feed. `address(0)` means no oracle is configured and returns `NoFeed`.
    /// @param maxAge Maximum seconds since the last update.
    /// @param sequencerFeed Chainlink L2 sequencer uptime feed, or `address(0)` to skip.
    function check(address feed, uint256 maxAge, address sequencerFeed) internal view returns (Status) {
        if (sequencerFeed != address(0)) {
            (, int256 down, uint256 startedAt,,) = IAggregatorV3(sequencerFeed).latestRoundData();
            if (down != 0) return Status.SequencerDown;
            if (block.timestamp - startedAt < SEQUENCER_GRACE) return Status.SequencerGrace;
        }
        if (feed == address(0)) return Status.NoFeed;
        (, int256 answer,, uint256 updatedAt,) = IAggregatorV3(feed).latestRoundData();
        if (answer <= 0 || updatedAt > block.timestamp) return Status.InvalidAnswer;
        if (block.timestamp - updatedAt > maxAge) return Status.Stale;
        return Status.Ok;
    }
}
