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
///
/// Card timing and hazard details are filled by later Epic 3 stories.
nonisolated struct ExecutionStepRecord: Equatable, Sendable {
    /// Zero-based index into `ExecutionInput.enteredCoordinates`.
    let enteredIndex: Int
    let coordinate: GridCoordinate
    let cardType: CardType
}

/// Mutable run-scoped execution state owned by `ExecutionEngine`.
nonisolated struct ExecutionState: Equatable, Sendable {
    let input: ExecutionInput
    private(set) var phase: ExecutionPhase
    /// Index of the next entered card to resolve.
    private(set) var nextEnteredIndex: Int
    /// Elapsed delivery minutes. Timing accumulation arrives in E3-S02.
    private(set) var elapsedMinutes: Int
    /// Run-scoped damage events. Hazard rolls arrive in E3-S03.
    private(set) var damageEventCount: Int
    private(set) var resolvedSteps: [ExecutionStepRecord]

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
    }

    mutating func markStarted() {
        phase = input.enteredCoordinates.isEmpty ? .completed : .running
    }

    mutating func appendResolvedStep(_ step: ExecutionStepRecord) {
        resolvedSteps.append(step)
        nextEnteredIndex = step.enteredIndex + 1
        if nextEnteredIndex >= input.enteredCoordinates.count {
            phase = .completed
        }
    }
}
