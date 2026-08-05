//
//  ExecutionEngine.swift
//  delivery-game
//

import Foundation

/// Why an execution lifecycle transition was rejected.
nonisolated enum ExecutionEngineRejection: Equatable, Sendable {
    case alreadyStarted
    case notRunning
    case alreadyCompleted
}

/// Result of attempting to start execution.
nonisolated enum ExecutionStartResult: Equatable, Sendable {
    case started(ExecutionState)
    case rejected(ExecutionEngineRejection)
}

/// Result of attempting to resolve the next entered card.
nonisolated enum ExecutionAdvanceResult: Equatable, Sendable {
    case advanced(step: ExecutionStepRecord, state: ExecutionState)
    case completed(state: ExecutionState)
    case rejected(ExecutionEngineRejection)
}

/// Domain engine that walks one confirmed route from start to finish.
///
/// Owns execution lifecycle and sequential traversal. Card-specific timing and
/// hazard behaviour are intentionally deferred to later Epic 3 stories.
nonisolated struct ExecutionEngine: Equatable, Sendable {
    private(set) var state: ExecutionState
    private var hasStarted: Bool

    /// Snapshot of the immutable confirmed route this engine executes.
    var input: ExecutionInput {
        state.input
    }

    init(input: ExecutionInput) {
        self.state = ExecutionState(input: input)
        self.hasStarted = false
    }

    /// Begins execution exactly once for this engine instance.
    mutating func start() -> ExecutionStartResult {
        if hasStarted || state.phase != .idle {
            return .rejected(.alreadyStarted)
        }

        hasStarted = true
        state.markStarted()
        return .started(state)
    }

    /// Resolves the next entered card after the depot.
    ///
    /// Depot is never resolved as a movement step. Card effects are not applied
    /// yet — this advances lifecycle state only.
    mutating func advance() -> ExecutionAdvanceResult {
        switch state.phase {
        case .idle:
            return .rejected(.notRunning)
        case .completed:
            return .rejected(.alreadyCompleted)
        case .running:
            break
        }

        let index = state.nextEnteredIndex
        let coordinates = state.input.enteredCoordinates
        let cardTypes = state.input.enteredCardTypes

        guard index < coordinates.count, index < cardTypes.count else {
            return .rejected(.alreadyCompleted)
        }

        let step = ExecutionStepRecord(
            enteredIndex: index,
            coordinate: coordinates[index],
            cardType: cardTypes[index]
        )
        state.appendResolvedStep(step)

        if state.isComplete {
            return .completed(state: state)
        }
        return .advanced(step: step, state: state)
    }

    /// Advances until every entered card has been resolved, or rejects if not running.
    mutating func runToCompletion() -> ExecutionAdvanceResult {
        if state.phase == .idle {
            return .rejected(.notRunning)
        }
        if state.phase == .completed {
            return .rejected(.alreadyCompleted)
        }

        var lastResult: ExecutionAdvanceResult = .rejected(.notRunning)
        while state.phase == .running {
            lastResult = advance()
            if case .rejected = lastResult {
                return lastResult
            }
        }
        return lastResult
    }
}
