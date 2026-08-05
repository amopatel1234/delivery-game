//
//  ExecutionPresentationState.swift
//  delivery-game
//

import Foundation

/// Visual consequence of the most recently revealed resolution event.
nonisolated enum ExecutionConsequenceKind: String, Equatable, Sendable {
    case movement
    case delay
    case damage

    var statusText: String {
        switch self {
        case .movement:
            "Moved"
        case .delay:
            "Delayed"
        case .damage:
            "Damaged"
        }
    }
}

/// Presentation-neutral snapshot of one execution playback frame.
///
/// Built only from confirmed input + sealed (or in-progress) event history.
/// SwiftUI must not feed values back into the domain engine.
nonisolated struct ExecutionPresentationState: Equatable, Sendable {
    enum Phase: String, Equatable, Sendable {
        case ready
        case running
        case completed
    }

    let jobDisplayName: String
    let totalStepCount: Int
    /// Number of resolution events revealed to the player so far.
    let revealedEventCount: Int
    let playerCoordinate: GridCoordinate
    /// Card currently highlighted as resolving; `nil` when idle/complete.
    let activeCoordinate: GridCoordinate?
    let elapsedMinutes: Int
    let damageEventCount: Int
    let lastConsequence: ExecutionConsequenceKind?
    let phase: Phase
    /// Planning select/undo/confirm remain locked for the whole run.
    let arePlanningControlsLocked: Bool

    var progressFraction: Double {
        guard totalStepCount > 0 else { return 1 }
        return Double(revealedEventCount) / Double(totalStepCount)
    }

    var progressLabel: String {
        if totalStepCount == 0 {
            return "0 / 0"
        }
        return "\(revealedEventCount) / \(totalStepCount)"
    }

    var statusMessage: String {
        switch phase {
        case .ready:
            return "Ready to execute · \(totalStepCount) cards after Depot"
        case .running:
            if let lastConsequence {
                return "\(lastConsequence.statusText) · card \(revealedEventCount) of \(totalStepCount)"
            }
            return "Executing · card \(max(revealedEventCount, 1)) of \(totalStepCount)"
        case .completed:
            return "Execution complete · \(elapsedMinutes) min · \(damageEventCount) damage"
        }
    }

    var accessibilityLabel: String {
        "\(jobDisplayName). \(statusMessage). Elapsed \(elapsedMinutes) minutes. Damage \(damageEventCount)."
    }

    /// Frame before any event is revealed (player still at depot).
    static func ready(
        input: ExecutionInput,
        eventCount: Int,
        controlsLocked: Bool = true
    ) -> ExecutionPresentationState {
        ExecutionPresentationState(
            jobDisplayName: input.jobDisplayName,
            totalStepCount: eventCount,
            revealedEventCount: 0,
            playerCoordinate: input.route.depot,
            activeCoordinate: nil,
            elapsedMinutes: 0,
            damageEventCount: 0,
            lastConsequence: nil,
            phase: eventCount == 0 ? .completed : .ready,
            arePlanningControlsLocked: controlsLocked
        )
    }

    /// Builds a playback frame after `revealedEventCount` events are shown.
    static func snapshot(
        input: ExecutionInput,
        events: [ExecutionResolutionEvent],
        revealedEventCount: Int,
        controlsLocked: Bool = true
    ) -> ExecutionPresentationState {
        let clamped = min(max(revealedEventCount, 0), events.count)
        if clamped == 0 {
            return .ready(input: input, eventCount: events.count, controlsLocked: controlsLocked)
        }

        let revealed = Array(events.prefix(clamped))
        let latest = revealed[clamped - 1]
        let completed = clamped >= events.count
        return ExecutionPresentationState(
            jobDisplayName: input.jobDisplayName,
            totalStepCount: events.count,
            revealedEventCount: clamped,
            playerCoordinate: latest.coordinate,
            activeCoordinate: completed ? nil : latest.coordinate,
            elapsedMinutes: latest.elapsedMinutesAfter,
            damageEventCount: latest.cumulativeDamageEventCount,
            lastConsequence: consequence(for: latest),
            phase: completed ? .completed : .running,
            arePlanningControlsLocked: controlsLocked
        )
    }

    /// Convenience from a sealed event log.
    static func snapshot(
        input: ExecutionInput,
        eventLog: ExecutionEventLog,
        revealedEventCount: Int,
        controlsLocked: Bool = true
    ) -> ExecutionPresentationState {
        snapshot(
            input: input,
            events: eventLog.events,
            revealedEventCount: revealedEventCount,
            controlsLocked: controlsLocked
        )
    }

    static func consequence(for event: ExecutionResolutionEvent) -> ExecutionConsequenceKind {
        if event.didDamage {
            return .damage
        }
        if event.didDelay {
            return .delay
        }
        return .movement
    }
}

/// Planning chrome enablement while a confirmed route is executing or locked.
nonisolated struct PlanningControlLock: Equatable, Sendable {
    let isEditingLocked: Bool
    let canUndoRoute: Bool
    let canConfirmRoute: Bool

    var canSelectCards: Bool { !isEditingLocked }
    var canUndo: Bool { !isEditingLocked && canUndoRoute }
    var canConfirm: Bool { !isEditingLocked && canConfirmRoute }

    static func afterConfirmation(
        canUndoRoute: Bool = false,
        canConfirmRoute: Bool = false
    ) -> PlanningControlLock {
        PlanningControlLock(
            isEditingLocked: true,
            canUndoRoute: canUndoRoute,
            canConfirmRoute: canConfirmRoute
        )
    }
}

/// Domain-side helper that resolves a confirmed route into a sealed event log
/// and an immutable Epic 4 hand-off. Presentation consumes the log; it does
/// not re-roll hazards.
nonisolated enum ExecutionRunPreparer {
    /// Default visual cadence between revealed cards (nanoseconds).
    static let defaultStepDelayNanoseconds: UInt64 = 450_000_000

    static func prepare(
        input: ExecutionInput,
        seed: UInt64
    ) -> (state: ExecutionState, eventLog: ExecutionEventLog, result: ExecutionResult) {
        var engine = ExecutionEngine(input: input, seed: seed)
        _ = engine.start()
        _ = engine.runToCompletion()
        guard case .completed(let result) = engine.finish() else {
            preconditionFailure("Completed run must produce an ExecutionResult")
        }
        return (engine.state, engine.state.eventLog, result)
    }

    static func prepare(
        input: ExecutionInput,
        scriptedRolls: [Int]
    ) -> (state: ExecutionState, eventLog: ExecutionEventLog, result: ExecutionResult) {
        var engine = ExecutionEngine(input: input, scriptedRolls: scriptedRolls)
        _ = engine.start()
        _ = engine.runToCompletion()
        guard case .completed(let result) = engine.finish() else {
            preconditionFailure("Completed run must produce an ExecutionResult")
        }
        return (engine.state, engine.state.eventLog, result)
    }
}
