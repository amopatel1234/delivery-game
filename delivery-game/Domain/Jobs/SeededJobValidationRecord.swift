//
//  SeededJobValidationRecord.swift
//  delivery-game
//

import Foundation

/// Accepted seed / timing / intent snapshot for one authored MVP job.
nonisolated struct SeededJobValidationEntry: Equatable, Sendable {
    let id: SeededJobID
    let displayName: String
    let seed: UInt64
    let targetTimeMinutes: Int
    let deadlineMinutes: Int
    let designIntent: String
    let requiredCardTypes: Set<CardType>
}

/// Canonical internal-validation record for the five seeded jobs (E6-S04).
nonisolated enum SeededJobValidationRecord {
    /// Accepted catalogue values used for pre-TestFlight balance sign-off.
    static let entries: [SeededJobValidationEntry] = [
        SeededJobValidationEntry(
            id: .directButRisky,
            displayName: "Direct but Risky",
            seed: 1001,
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            designIntent: "Short route with Heavy Traffic exposure and a safer alternative.",
            requiredCardTypes: [.heavyTraffic]
        ),
        SeededJobValidationEntry(
            id: .predictableDetour,
            displayName: "Predictable Detour",
            seed: 2002,
            targetTimeMinutes: 12,
            deadlineMinutes: 18,
            designIntent: "Longer deterministic route competing with a shorter uncertain route.",
            requiredCardTypes: [.roadworks, .lightTraffic]
        ),
        SeededJobValidationEntry(
            id: .fastLaneTemptation,
            displayName: "Fast Lane Temptation",
            seed: 3003,
            targetTimeMinutes: 9,
            deadlineMinutes: 15,
            designIntent: "Fast Lane meaningfully changes timing or reward potential.",
            requiredCardTypes: [.fastLane]
        ),
        SeededJobValidationEntry(
            id: .deadlinePressure,
            displayName: "Deadline Pressure",
            seed: 4004,
            targetTimeMinutes: 10,
            deadlineMinutes: 12,
            designIntent: "Tight timing margin where route composition matters.",
            requiredCardTypes: [.heavyTraffic, .lightTraffic]
        ),
        SeededJobValidationEntry(
            id: .closeDecision,
            displayName: "Close Decision",
            seed: 5005,
            targetTimeMinutes: 11,
            deadlineMinutes: 17,
            designIntent: "Two comparable routes with no obviously dominant option.",
            requiredCardTypes: [.fastLane, .roadworks, .heavyTraffic]
        ),
    ]

    static func entry(for id: SeededJobID) -> SeededJobValidationEntry {
        guard let entry = entries.first(where: { $0.id == id }) else {
            preconditionFailure("Missing validation entry for \(id.rawValue)")
        }
        return entry
    }

    /// Ensures the validation record stays aligned with the live catalogue.
    static func matchesCatalogueDefinition(_ definition: SeededJobDefinition) -> Bool {
        let entry = entry(for: definition.id)
        return entry.displayName == definition.displayName
            && entry.seed == definition.seed
            && entry.targetTimeMinutes == definition.targetTimeMinutes
            && entry.deadlineMinutes == definition.deadlineMinutes
            && entry.designIntent == definition.designNotes
    }
}
