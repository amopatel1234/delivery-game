//
//  SeededJobCatalogue.swift
//  delivery-game
//

import Foundation

/// Stable identifiers for the five authored MVP jobs.
nonisolated enum SeededJobID: String, CaseIterable, Codable, Sendable, Hashable {
    case directButRisky = "direct_but_risky"
    case predictableDetour = "predictable_detour"
    case fastLaneTemptation = "fast_lane_temptation"
    case deadlinePressure = "deadline_pressure"
    case closeDecision = "close_decision"
}

/// Authored metadata for one seeded MVP job.
///
/// Seeds and timing values are provisional balancing inputs until Epic 6 validation.
nonisolated struct SeededJobDefinition: Equatable, Sendable, Hashable {
    let id: SeededJobID
    let displayName: String
    let seed: UInt64
    /// Whole minutes used as the early-bonus boundary.
    let targetTimeMinutes: Int
    /// Whole minutes at which the run fails.
    let deadlineMinutes: Int
    let designNotes: String
}

/// Complete immutable job instance ready for planning and execution.
nonisolated struct SeededJob: Equatable, Sendable, Hashable {
    let definition: SeededJobDefinition
    let economy: EconomyConfiguration
    let board: GeneratedBoard

    var id: SeededJobID { definition.id }
    var displayName: String { definition.displayName }
    var seed: UInt64 { definition.seed }
    var targetTimeMinutes: Int { definition.targetTimeMinutes }
    var deadlineMinutes: Int { definition.deadlineMinutes }
}

/// Catalogue and loader for the five authored MVP jobs.
nonisolated enum SeededJobCatalogue {
    /// First job in the sequential MVP play order.
    static let defaultJobID: SeededJobID = .directButRisky

    static let definitions: [SeededJobDefinition] = [
        SeededJobDefinition(
            id: .directButRisky,
            displayName: "Direct but Risky",
            seed: 1001,
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            designNotes: "Short route with Heavy Traffic exposure and a safer alternative."
        ),
        SeededJobDefinition(
            id: .predictableDetour,
            displayName: "Predictable Detour",
            seed: 2002,
            targetTimeMinutes: 12,
            deadlineMinutes: 18,
            designNotes: "Longer deterministic route competing with a shorter uncertain route."
        ),
        SeededJobDefinition(
            id: .fastLaneTemptation,
            displayName: "Fast Lane Temptation",
            seed: 3003,
            targetTimeMinutes: 9,
            deadlineMinutes: 15,
            designNotes: "Fast Lane meaningfully changes timing or reward potential."
        ),
        SeededJobDefinition(
            id: .deadlinePressure,
            displayName: "Deadline Pressure",
            seed: 4004,
            targetTimeMinutes: 10,
            deadlineMinutes: 12,
            designNotes: "Tight timing margin where route composition matters."
        ),
        SeededJobDefinition(
            id: .closeDecision,
            displayName: "Close Decision",
            seed: 5005,
            targetTimeMinutes: 11,
            deadlineMinutes: 17,
            designNotes: "Two comparable routes with no obviously dominant option."
        ),
    ]

    /// Canonical Job 1 → Job 5 order for MVP progression.
    static let sequentialOrder: [SeededJobID] = definitions.map(\.id)

    static func definition(for id: SeededJobID) -> SeededJobDefinition {
        guard let definition = definitions.first(where: { $0.id == id }) else {
            preconditionFailure("Missing authored definition for \(id.rawValue)")
        }
        return definition
    }

    /// Loads Job 1 by default.
    static func loadDefault(
        economy: EconomyConfiguration = .mvp,
        recipe: DeckRecipe = .mvp
    ) throws -> SeededJob {
        try load(id: defaultJobID, economy: economy, recipe: recipe)
    }

    /// Loads any authored job directly for development and tests.
    static func load(
        id: SeededJobID,
        economy: EconomyConfiguration = .mvp,
        recipe: DeckRecipe = .mvp
    ) throws -> SeededJob {
        let definition = definition(for: id)
        precondition(
            definition.deadlineMinutes > definition.targetTimeMinutes,
            "Deadline must be after Target Time for \(id.rawValue)"
        )

        let board = try BoardGenerator.generate(seed: definition.seed, recipe: recipe)
        return SeededJob(
            definition: definition,
            economy: economy,
            board: board
        )
    }
}
