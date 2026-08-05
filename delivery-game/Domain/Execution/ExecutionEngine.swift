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
    case missingHeavyTrafficHazard
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

/// Supplies Heavy Traffic hazard decisions during execution.
///
/// E3-S03 replaces scripted providers with seeded RNG rolls.
nonisolated protocol HeavyTrafficHazardProviding: Sendable {
    mutating func nextHeavyTrafficHazard() -> HeavyTrafficHazardOutcome
}

/// Always returns a fixed Heavy Traffic outcome. Useful in tests.
nonisolated struct FixedHeavyTrafficHazardProvider: HeavyTrafficHazardProviding, Equatable {
    var outcome: HeavyTrafficHazardOutcome

    mutating func nextHeavyTrafficHazard() -> HeavyTrafficHazardOutcome {
        outcome
    }
}

/// Domain engine that walks one confirmed route from start to finish.
///
/// Owns execution lifecycle, sequential traversal, and card resolution via
/// `CardResolver`. Probabilistic Heavy Traffic rolls are injected.
nonisolated struct ExecutionEngine: Equatable, Sendable {
    private(set) var state: ExecutionState
    private var hasStarted: Bool
    private var heavyTrafficHazardProvider: FixedHeavyTrafficHazardProvider

    /// Snapshot of the immutable confirmed route this engine executes.
    var input: ExecutionInput {
        state.input
    }

    init(
        input: ExecutionInput,
        heavyTrafficHazard: HeavyTrafficHazardOutcome = .noHazard
    ) {
        self.state = ExecutionState(input: input)
        self.hasStarted = false
        self.heavyTrafficHazardProvider = FixedHeavyTrafficHazardProvider(
            outcome: heavyTrafficHazard
        )
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

        let cardType = cardTypes[index]
        let hazard: HeavyTrafficHazardOutcome?
        if cardType == .heavyTraffic {
            hazard = heavyTrafficHazardProvider.nextHeavyTrafficHazard()
        } else {
            hazard = nil
        }

        switch CardResolver.resolve(cardType: cardType, heavyTrafficHazard: hazard) {
        case .rejected(.missingHeavyTrafficHazard):
            return .rejected(.missingHeavyTrafficHazard)
        case .resolved(let outcome):
            let step = ExecutionStepRecord(
                enteredIndex: index,
                coordinate: coordinates[index],
                outcome: outcome
            )
            state.appendResolvedStep(step)

            if state.isComplete {
                return .completed(state: state)
            }
            return .advanced(step: step, state: state)
        }
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
