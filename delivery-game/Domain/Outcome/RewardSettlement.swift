//
//  RewardSettlement.swift
//  delivery-game
//

import Foundation

/// Immutable payout produced from an outcome evaluation and shared economy rules.
///
/// Component fields remain available even when the final reward is zero so
/// E4-S03 can explain failed and clamped runs without recalculating.
nonisolated struct RewardSettlement: Equatable, Sendable {
    let evaluation: DeliveryOutcomeEvaluation
    let economy: EconomyConfiguration

    /// Base reward considered for a completed run (always the economy base).
    let baseReward: Int
    /// Whole minutes earlier than Target Time (`0` when not early).
    let earlyMinutes: Int
    let earlyBonus: Int
    /// Whole minutes later than Target Time before Deadline (`0` when not late).
    let lateMinutes: Int
    let latenessPenalty: Int
    let damageEventCount: Int
    let damagePenalty: Int
    /// Completed-run arithmetic before clamping (`base + early - late - damage`).
    let rawCompletedReward: Int
    /// Settled payout. Failed runs are always `0`; completed runs are clamped.
    let finalReward: Int

    var status: DeliveryOutcomeStatus { evaluation.status }
    var timingBand: DeliveryTimingBand { evaluation.timingBand }
    var isFailed: Bool { evaluation.isFailed }
    var isCompleted: Bool { evaluation.isCompleted }
}

/// Pure reward settlement over immutable execution / outcome data.
///
/// Uses the same `EconomyConfiguration` as planning maximum-reward previews.
/// Consumes no randomness.
nonisolated enum RewardSettler {
    /// Settles a finished execution hand-off.
    static func settle(_ result: ExecutionResult) -> RewardSettlement {
        settle(
            evaluation: OutcomeEvaluator.evaluate(result),
            economy: result.economy
        )
    }

    /// Settles from an already-computed outcome evaluation.
    static func settle(
        evaluation: DeliveryOutcomeEvaluation,
        economy: EconomyConfiguration
    ) -> RewardSettlement {
        let earlyMinutes: Int
        let lateMinutes: Int
        switch evaluation.timingBand {
        case .early:
            earlyMinutes = evaluation.targetTimeMinutes - evaluation.elapsedMinutes
            lateMinutes = 0
        case .late:
            earlyMinutes = 0
            lateMinutes = evaluation.elapsedMinutes - evaluation.targetTimeMinutes
        case .onTarget, .missedDeadline:
            earlyMinutes = 0
            lateMinutes = 0
        }

        let earlyBonus = earlyMinutes * economy.earlyBonusPerMinute
        let latenessPenalty = lateMinutes * economy.latenessPenaltyPerMinute
        let damagePenalty = evaluation.damageEventCount * economy.damagePenaltyPerEvent
        let rawCompletedReward =
            economy.baseReward + earlyBonus - latenessPenalty - damagePenalty

        let finalReward: Int
        if evaluation.isFailed {
            finalReward = 0
        } else {
            finalReward = economy.clampReward(rawCompletedReward)
        }

        return RewardSettlement(
            evaluation: evaluation,
            economy: economy,
            baseReward: economy.baseReward,
            earlyMinutes: earlyMinutes,
            earlyBonus: earlyBonus,
            lateMinutes: lateMinutes,
            latenessPenalty: latenessPenalty,
            damageEventCount: evaluation.damageEventCount,
            damagePenalty: damagePenalty,
            rawCompletedReward: rawCompletedReward,
            finalReward: finalReward
        )
    }
}
