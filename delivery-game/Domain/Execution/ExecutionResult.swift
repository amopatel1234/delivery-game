//
//  ExecutionResult.swift
//  delivery-game
//

import Foundation

/// Immutable hand-off from execution into Epic 4 outcome / settlement.
///
/// Contains everything settlement needs without live engine state or
/// presentation. Does not decide completed/failed payout status.
nonisolated struct ExecutionResult: Equatable, Sendable {
    /// Confirmed planning input (job config, economy, route, card types).
    let input: ExecutionInput
    /// Final elapsed delivery minutes after every entered card resolved.
    let elapsedMinutes: Int
    /// Total damage events recorded during the run.
    let damageEventCount: Int
    /// Sealed ordered resolution history (authoritative for settlement).
    let eventLog: ExecutionEventLog
    /// Presentation-independent journey summary derived from the same history.
    let recap: ExecutionRecap
    /// `true` when the destination card was resolved as the final entered step.
    let didReachDestination: Bool

    /// Job economy configuration carried for settlement (no re-lookup required).
    var economy: EconomyConfiguration { input.economy }

    var jobID: SeededJobID { input.jobID }
    var targetTimeMinutes: Int { input.targetTimeMinutes }
    var deadlineMinutes: Int { input.deadlineMinutes }

    /// Settlement-facing event snapshot (events + totals only).
    var settlementSnapshot: ExecutionSettlementSnapshot {
        eventLog.settlementSnapshot
    }

    /// Builds a result from a finished execution state.
    static func from(state: ExecutionState) -> ExecutionResult {
        precondition(state.phase == .completed, "ExecutionResult requires a completed state")
        precondition(state.eventLog.isSealed, "ExecutionResult requires a sealed event log")

        let recap = ExecutionRecap.from(input: state.input, state: state)
        let reachedDestination =
            state.resolvedSteps.last?.coordinate == .destination
            || (
                state.input.enteredCoordinates.last == .destination
                    && state.resolvedSteps.count == state.input.enteredCoordinates.count
            )

        return ExecutionResult(
            input: state.input,
            elapsedMinutes: state.elapsedMinutes,
            damageEventCount: state.damageEventCount,
            eventLog: state.eventLog,
            recap: recap,
            didReachDestination: reachedDestination
        )
    }
}

/// Why producing an execution result was rejected.
nonisolated enum ExecutionCompletionRejection: Equatable, Sendable {
    /// Engine has not finished resolving every entered card.
    case notCompleted
    /// `finish()` already produced a result for this engine instance.
    case alreadyTransitioned
}

/// Result of attempting the one-shot execution → outcome transition.
nonisolated enum ExecutionCompletionResult: Equatable, Sendable {
    case completed(ExecutionResult)
    case rejected(ExecutionCompletionRejection)
}
