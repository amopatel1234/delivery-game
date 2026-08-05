//
//  MaximumRewardEstimator.swift
//  delivery-game
//

import Foundation

/// Estimates the highest achievable reward for a planned route.
///
/// Uses deterministic arrival only. Unresolved random delays and damage
/// penalties are excluded so the preview never understates the best case.
nonisolated enum MaximumRewardEstimator {
    /// Best-case completed-run payout for the given timing and economy inputs.
    /// Returns zero when deterministic arrival is at or after the Deadline.
    static func estimate(_ input: MaximumRewardEstimationInput) -> Int {
        let arrival = input.deterministicArrivalMinutes
        let target = input.targetTimeMinutes
        let deadline = input.deadlineMinutes
        let economy = input.economy

        if arrival >= deadline {
            return 0
        }

        var reward = economy.baseReward

        if arrival < target {
            let earlyMinutes = target - arrival
            reward += earlyMinutes * economy.earlyBonusPerMinute
        } else if arrival > target {
            let lateMinutes = arrival - target
            reward -= lateMinutes * economy.latenessPenaltyPerMinute
        }

        return economy.clampReward(reward)
    }

    static func estimate(analysis: PlanningAnalysisResult) -> Int {
        estimate(analysis.maximumRewardEstimationInput)
    }

    /// Theoretical ceiling for equivalent job timing and economy when arrival is zero.
    static func theoreticalMaximum(for input: MaximumRewardEstimationInput) -> Int {
        let economy = input.economy
        return economy.clampReward(
            economy.baseReward
                + input.targetTimeMinutes * economy.earlyBonusPerMinute
        )
    }
}
