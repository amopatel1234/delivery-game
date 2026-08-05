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
/// Production runs use seeded RNG via `HazardResolver`. Fixed outcomes remain
/// available for tests that assert card resolution without rolling.
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

/// How Heavy Traffic hazards are decided for one execution run.
nonisolated enum ExecutionHazardMode: Equatable, Sendable {
    /// Scripted outcome for every Heavy Traffic card (tests).
    case fixed(HeavyTrafficHazardOutcome)
    /// Seeded RNG rolls via `HazardResolver` (production).
    case seeded(SeededRandomNumberGenerator)
    /// Scripted inclusive percentile rolls via `HazardResolver` (tests).
    case scripted(FixedSequenceRandomNumberGenerator)
}

/// Hazard decision plus any RNG rolls actually consumed.
nonisolated struct HeavyTrafficHazardDecision: Equatable, Sendable {
    let outcome: HeavyTrafficHazardOutcome
    let delayRoll: Int?
    let damageRoll: Int?

    static func fixed(_ outcome: HeavyTrafficHazardOutcome) -> HeavyTrafficHazardDecision {
        HeavyTrafficHazardDecision(outcome: outcome, delayRoll: nil, damageRoll: nil)
    }

    static func from(_ result: HazardResolutionResult) -> HeavyTrafficHazardDecision {
        HeavyTrafficHazardDecision(
            outcome: result.outcome,
            delayRoll: result.delayRoll,
            damageRoll: result.damageRoll
        )
    }
}

/// Domain engine that walks one confirmed route from start to finish.
///
/// Owns execution lifecycle, sequential traversal, and card resolution via
/// `CardResolver`. Probabilistic Heavy Traffic rolls use injected RNG.
nonisolated struct ExecutionEngine: Equatable, Sendable {
    private(set) var state: ExecutionState
    private var hasStarted: Bool
    private var hazardMode: ExecutionHazardMode

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
        self.hazardMode = .fixed(heavyTrafficHazard)
    }

    init(input: ExecutionInput, seed: UInt64) {
        self.state = ExecutionState(input: input)
        self.hasStarted = false
        self.hazardMode = .seeded(SeededRandomNumberGenerator(seed: seed))
    }

    init(input: ExecutionInput, rng: SeededRandomNumberGenerator) {
        self.state = ExecutionState(input: input)
        self.hasStarted = false
        self.hazardMode = .seeded(rng)
    }

    init(input: ExecutionInput, scriptedRolls: [Int]) {
        self.state = ExecutionState(input: input)
        self.hasStarted = false
        self.hazardMode = .scripted(FixedSequenceRandomNumberGenerator(values: scriptedRolls))
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
        let hazardDecision: HeavyTrafficHazardDecision?
        if cardType == .heavyTraffic {
            hazardDecision = nextHeavyTrafficDecision()
        } else {
            hazardDecision = nil
        }

        switch CardResolver.resolve(
            cardType: cardType,
            heavyTrafficHazard: hazardDecision?.outcome
        ) {
        case .rejected(.missingHeavyTrafficHazard):
            return .rejected(.missingHeavyTrafficHazard)
        case .resolved(let outcome):
            let step = ExecutionStepRecord(
                enteredIndex: index,
                coordinate: coordinates[index],
                outcome: outcome
            )
            state.appendResolvedStep(
                step,
                delayRoll: hazardDecision?.delayRoll,
                damageRoll: hazardDecision?.damageRoll
            )

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

    private mutating func nextHeavyTrafficDecision() -> HeavyTrafficHazardDecision {
        switch hazardMode {
        case .fixed(let outcome):
            return .fixed(outcome)
        case .seeded(var rng):
            let result = HazardResolver.resolveHeavyTraffic(rng: &rng)
            hazardMode = .seeded(rng)
            return .from(result)
        case .scripted(var rng):
            let result = HazardResolver.resolveHeavyTraffic(rng: &rng)
            hazardMode = .scripted(rng)
            return .from(result)
        }
    }
}
