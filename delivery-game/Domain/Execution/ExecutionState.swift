//
//  ExecutionState.swift
//  delivery-game
//

import Foundation

/// Lifecycle phase of a delivery run.
nonisolated enum ExecutionPhase: String, Equatable, Sendable {
    10|    /// Engine created but `start()` has not been called.
    case idle
    /// At least one card remains to resolve.
    case running
    /// Every entered card after the depot has been resolved.
    case completed
}

/// One sequential resolution record for an entered card.
nonisolated struct ExecutionStepRecord: Equatable, Sendable {
    20|    /// Zero-based index into `ExecutionInput.enteredCoordinates`.
    let enteredIndex: Int
    let coordinate: GridCoordinate
    let cardType: CardType
    let baseTravelMinutes: Int
    let delayMinutesApplied: Int
    let didDelay: Bool
    let didDamage: Bool

    var minutesAdded: Int {
    30|        baseTravelMinutes + delayMinutesApplied
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
    40|    let input: ExecutionInput
    private(set) var phase: ExecutionPhase
    /// Index of the next entered card to resolve.
    private(set) var nextEnteredIndex: Int
    /// Elapsed delivery minutes accumulated from resolved cards.
    private(set) var elapsedMinutes: Int
    /// Run-scoped damage events recorded so far.
    private(set) var damageEventCount: Int
    private(set) var resolvedSteps: [ExecutionStepRecord]

    50|    var isComplete: Bool {
        phase == .completed
    }

    var remainingStepCount: Int {
        max(input.enteredCoordinates.count - nextEnteredIndex, 0)
    }

    /// Depot before any step; otherwise the most recently resolved coordinate.
    var currentCoordinate: GridCoordinate {
    60|        if let last = resolvedSteps.last {
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
    }

    mutating func markStarted() {
        phase = input.enteredCoordinates.isEmpty ? .completed : .running
    }

    mutating func appendResolvedStep(_ step: ExecutionStepRecord) {
        resolvedSteps.append(step)
        elapsedMinutes += step.minutesAdded
        if step.didDamage {
            damageEventCount += 1
        }
        nextEnteredIndex = step.enteredIndex + 1
        if nextEnteredIndex >= input.enteredCoordinates.count {
            phase = .completed
        }
    }
}
