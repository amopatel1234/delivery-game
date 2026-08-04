//
//  EconomyConfiguration.swift
//  delivery-game
//

import Foundation

/// Shared MVP economy values used by planning previews and final settlement.
nonisolated struct EconomyConfiguration: Equatable, Sendable, Hashable {
    /// Starting payout for a completed run before bonuses and penalties.
    let baseReward: Int

    /// Coins added per whole minute earlier than Target Time.
    let earlyBonusPerMinute: Int

    /// Coins subtracted per whole minute later than Target Time (before Deadline).
    let latenessPenaltyPerMinute: Int

    /// Coins subtracted once per recorded damage event on a completed run.
    let damagePenaltyPerEvent: Int

    /// Lowest allowed final reward for a completed run.
    let minimumReward: Int

    /// Canonical shared configuration for every initial seeded MVP job.
    static let mvp = EconomyConfiguration(
        baseReward: 100,
        earlyBonusPerMinute: 5,
        latenessPenaltyPerMinute: 20,
        damagePenaltyPerEvent: 20,
        minimumReward: 0
    )

    /// Applies the canonical completed-run reward clamp.
    func clampReward(_ reward: Int) -> Int {
        max(reward, minimumReward)
    }
}
