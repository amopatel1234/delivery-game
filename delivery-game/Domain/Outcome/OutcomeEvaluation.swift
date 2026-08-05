//
//  OutcomeEvaluation.swift
//  delivery-game
//

import Foundation

/// High-level delivery result before reward settlement (E4-S02).
nonisolated enum DeliveryOutcomeStatus: String, Equatable, Sendable {
    case completed
    case failed
}

/// Timing band relative to Target Time and Deadline.
///
/// Canonical boundaries (Gameplay Rules):
/// - early: before Target Time
/// - onTarget: exactly at Target Time
/// - late: after Target Time and before Deadline
/// - missedDeadline: at or after Deadline
nonisolated enum DeliveryTimingBand: String, Equatable, Sendable {
    case early
    case onTarget
    case late
    case missedDeadline
}

/// Deterministic outcome evaluation produced from an immutable execution result.
///
/// Does not calculate rewards. Settlement (E4-S02) consumes this status plus
/// the same execution totals.
nonisolated struct DeliveryOutcomeEvaluation: Equatable, Sendable {
    let status: DeliveryOutcomeStatus
    let timingBand: DeliveryTimingBand
    let elapsedMinutes: Int
    let targetTimeMinutes: Int
    let deadlineMinutes: Int
    let damageEventCount: Int
    let didReachDestination: Bool

    var isCompleted: Bool { status == .completed }
    var isFailed: Bool { status == .failed }
}

/// Pure outcome evaluation against Target Time and Deadline rules.
nonisolated enum OutcomeEvaluator {
    /// Evaluates a finished execution hand-off.
    static func evaluate(_ result: ExecutionResult) -> DeliveryOutcomeEvaluation {
        evaluate(
            elapsedMinutes: result.elapsedMinutes,
            targetTimeMinutes: result.targetTimeMinutes,
            deadlineMinutes: result.deadlineMinutes,
            damageEventCount: result.damageEventCount,
            didReachDestination: result.didReachDestination
        )
    }

    /// Evaluates timing boundaries without requiring a full execution result.
    ///
    /// Preconditions match authored jobs: `deadlineMinutes > targetTimeMinutes`
    /// and non-negative elapsed time.
    static func evaluate(
        elapsedMinutes: Int,
        targetTimeMinutes: Int,
        deadlineMinutes: Int,
        damageEventCount: Int = 0,
        didReachDestination: Bool = true
    ) -> DeliveryOutcomeEvaluation {
        precondition(elapsedMinutes >= 0, "elapsedMinutes must be non-negative")
        precondition(targetTimeMinutes >= 0, "targetTimeMinutes must be non-negative")
        precondition(
            deadlineMinutes > targetTimeMinutes,
            "deadlineMinutes must be greater than targetTimeMinutes"
        )
        precondition(damageEventCount >= 0, "damageEventCount must be non-negative")

        let timingBand = Self.timingBand(
            elapsedMinutes: elapsedMinutes,
            targetTimeMinutes: targetTimeMinutes,
            deadlineMinutes: deadlineMinutes
        )

        let status: DeliveryOutcomeStatus
        if !didReachDestination || timingBand == .missedDeadline {
            status = .failed
        } else {
            status = .completed
        }

        return DeliveryOutcomeEvaluation(
            status: status,
            timingBand: timingBand,
            elapsedMinutes: elapsedMinutes,
            targetTimeMinutes: targetTimeMinutes,
            deadlineMinutes: deadlineMinutes,
            damageEventCount: damageEventCount,
            didReachDestination: didReachDestination
        )
    }

    static func timingBand(
        elapsedMinutes: Int,
        targetTimeMinutes: Int,
        deadlineMinutes: Int
    ) -> DeliveryTimingBand {
        if elapsedMinutes >= deadlineMinutes {
            return .missedDeadline
        }
        if elapsedMinutes < targetTimeMinutes {
            return .early
        }
        if elapsedMinutes == targetTimeMinutes {
            return .onTarget
        }
        return .late
    }
}
