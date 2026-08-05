//
//  ExecutionState.swift
//  delivery-game
//

import Foundation

/// Lifecycle phase of a delivery run.
nonisolated enum ExecutionPhase: String, Equatable, Sendable {
    /// Engine created but `start()` has not been called.
    case idle
    /// At least one card remains to resolve.
    case running
    /// Every entered card after the depot has been resolved.
    case completed
}

/// One sequential resolution record for an entered card.
nonisolated struct ExecutionStepRecord: Equatable, Sendable {
    /// Zero-based index into `ExecutionInput.enteredCoordinates`.
    let enteredIndex: Int
    let coordinate: GridCoordinate
    let cardType: CardType
    let baseTravelMinutes: Int
    let delayMinutesApplied: Int
    let didDelay: Bool
    let didDamage: Bool

    var minutesAdded: Int {
        baseTravelMinutes + delayMinutesApplied
    }

    init(
        enteredIndex: Int,
        coordinate: GridCoordinate,
        outcome: CardResolutionOutcome
    ) {
        self.enteredIndex = enteredIndex
        self.coordinate = coordinate
        self.cardType = outcome.cardType
        self.baseTravelMinutes = outcome.baseTravelMinutes
        self.delayMinutesApplied = outcome.delayMinutesApplied
        self.didDelay = outcome.didDelay
        self.didDamage = outcome.didDamage
    }
}

/// Mutable run-scoped execution state owned by `ExecutionEngine`.
nonisolated struct ExecutionState: Equatable, Sendable {
    let input: ExecutionInput
    private(set) var phase: ExecutionPhase
    /// Index of the next entered card to resolve.
    private(set) var nextEnteredIndex: Int
    /// Elapsed delivery minutes accumulated from resolved cards.
    private(set) var elapsedMinutes: Int
    /// Run-scoped damage events recorded so far.
    private(set) var damageEventCount: Int
    private(set) var resolvedSteps: [ExecutionStepRecord]
    /// Authoritative ordered resolution events for this run.
    private(set) var eventLog: ExecutionEventLog

    var isComplete: Bool {
        phase == .completed
    }

    var remainingStepCount: Int {
        max(input.enteredCoordinates.count - nextEnteredIndex, 0)
    }

    /// Depot before any step; otherwise the most recently resolved coordinate.
    var currentCoordinate: GridCoordinate {
        if let last = resolvedSteps.last {
            return last.coordinate
        }
        return input.route.depot
    }

    init(input: ExecutionInput) {
        self.input = input
        self.phase = .idle
        self.nextEnteredIndex = 0
        self.elapsedMinutes = 0
        self.damageEventCount = 0
        self.resolvedSteps = []
        self.eventLog = ExecutionEventLog()
    }

    mutating func markStarted() {
        phase = input.enteredCoordinates.isEmpty ? .completed : .running
        if phase == .completed {
            eventLog.seal()
        }
    }

    mutating func appendResolvedStep(
        _ step: ExecutionStepRecord,
        delayRoll: Int? = nil,
        damageRoll: Int? = nil
    ) {
        resolvedSteps.append(step)
        elapsedMinutes += step.minutesAdded
        if step.didDamage {
            damageEventCount += 1
        }
        nextEnteredIndex = step.enteredIndex + 1

        let event = ExecutionResolutionEvent(
            enteredIndex: step.enteredIndex,
            coordinate: step.coordinate,
            cardType: step.cardType,
            baseTravelMinutes: step.baseTravelMinutes,
            delayMinutesApplied: step.delayMinutesApplied,
            didDelay: step.didDelay,
            didDamage: step.didDamage,
            delayRoll: delayRoll,
            damageRoll: damageRoll,
            elapsedMinutesAfter: elapsedMinutes,
            cumulativeDamageEventCount: damageEventCount
        )
        let rejection = eventLog.record(event)
        precondition(rejection == nil, "Event log must accept events before seal")

        if nextEnteredIndex >= input.enteredCoordinates.count {
            phase = .completed
            eventLog.seal()
        }
    }
}
