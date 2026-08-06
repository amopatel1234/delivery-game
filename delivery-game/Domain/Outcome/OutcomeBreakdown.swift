//
//  OutcomeBreakdown.swift
//  delivery-game
//

import Foundation

/// Identifies a single reward line in an outcome breakdown.
nonisolated enum OutcomeBreakdownLineKind: String, Equatable, Sendable, Hashable, CaseIterable {
    case baseReward
    case earlyBonus
    case latenessPenalty
    case damagePenalty
    case finalReward
}

/// One presentation-neutral reward row derived from settlement.
///
/// Amounts are always non-negative magnitudes; `isDeduction` marks penalties.
nonisolated struct OutcomeBreakdownLineItem: Equatable, Sendable, Hashable {
    let kind: OutcomeBreakdownLineKind
    let amount: Int
    let isDeduction: Bool
    /// Whole minutes early/late or damage-event count when applicable.
    let quantity: Int?
}

/// Immutable, presentation-neutral explanation of how final reward was calculated.
///
/// Maps one-to-one from `RewardSettlement` without recalculating components.
nonisolated struct OutcomeBreakdown: Equatable, Sendable, Hashable {
    let status: DeliveryOutcomeStatus
    let timingBand: DeliveryTimingBand
    let elapsedMinutes: Int
    let targetTimeMinutes: Int
    let deadlineMinutes: Int
    let damageEventCount: Int
    let didReachDestination: Bool

    let baseReward: Int
    let earlyMinutes: Int
    let earlyBonus: Int
    let lateMinutes: Int
    let latenessPenalty: Int
    let damagePenalty: Int
    let rawCompletedReward: Int
    let finalReward: Int

    var isFailed: Bool { status == .failed }
    var isCompleted: Bool { status == .completed }

    /// Ordered reward rows including zero-value components.
    var rewardLineItems: [OutcomeBreakdownLineItem] {
        [
            OutcomeBreakdownLineItem(
                kind: .baseReward,
                amount: baseReward,
                isDeduction: false,
                quantity: nil
            ),
            OutcomeBreakdownLineItem(
                kind: .earlyBonus,
                amount: earlyBonus,
                isDeduction: false,
                quantity: earlyMinutes > 0 ? earlyMinutes : nil
            ),
            OutcomeBreakdownLineItem(
                kind: .latenessPenalty,
                amount: latenessPenalty,
                isDeduction: true,
                quantity: lateMinutes > 0 ? lateMinutes : nil
            ),
            OutcomeBreakdownLineItem(
                kind: .damagePenalty,
                amount: damagePenalty,
                isDeduction: true,
                quantity: damageEventCount > 0 ? damageEventCount : nil
            ),
            OutcomeBreakdownLineItem(
                kind: .finalReward,
                amount: finalReward,
                isDeduction: false,
                quantity: nil
            ),
        ]
    }
}

/// Maps settled rewards into a presentation-neutral breakdown.
nonisolated enum OutcomeBreakdownBuilder {
    /// Builds a breakdown from a finished execution hand-off.
    static func build(from result: ExecutionResult) -> OutcomeBreakdown {
        build(from: RewardSettler.settle(result))
    }

    /// Maps settlement fields without recalculating reward components.
    static func build(from settlement: RewardSettlement) -> OutcomeBreakdown {
        let evaluation = settlement.evaluation
        return OutcomeBreakdown(
            status: evaluation.status,
            timingBand: evaluation.timingBand,
            elapsedMinutes: evaluation.elapsedMinutes,
            targetTimeMinutes: evaluation.targetTimeMinutes,
            deadlineMinutes: evaluation.deadlineMinutes,
            damageEventCount: evaluation.damageEventCount,
            didReachDestination: evaluation.didReachDestination,
            baseReward: settlement.baseReward,
            earlyMinutes: settlement.earlyMinutes,
            earlyBonus: settlement.earlyBonus,
            lateMinutes: settlement.lateMinutes,
            latenessPenalty: settlement.latenessPenalty,
            damagePenalty: settlement.damagePenalty,
            rawCompletedReward: settlement.rawCompletedReward,
            finalReward: settlement.finalReward
        )
    }
}
