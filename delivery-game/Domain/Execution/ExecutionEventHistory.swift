//
//  ExecutionEventHistory.swift
//  delivery-game
//

import Foundation

/// One structured resolution event for an entered card after the depot.
///
/// Authoritative input for presentation, recap, and later settlement. Roll
/// fields are present only when an RNG value was actually consumed.
nonisolated struct ExecutionResolutionEvent: Equatable, Sendable {
    /// Zero-based index into `ExecutionInput.enteredCoordinates`.
    let enteredIndex: Int
    let coordinate: GridCoordinate
    let cardType: CardType
    let baseTravelMinutes: Int
    let delayMinutesApplied: Int
    let didDelay: Bool
    let didDamage: Bool
    /// Inclusive 1...100 delay roll when Heavy Traffic consumed one; otherwise `nil`.
    let delayRoll: Int?
    /// Inclusive 1...100 damage roll when delay succeeded and damage was rolled; otherwise `nil`.
    let damageRoll: Int?
    /// Elapsed delivery minutes after this card resolved.
    let elapsedMinutesAfter: Int
    /// Cumulative damage-event count after this card resolved.
    let cumulativeDamageEventCount: Int

    var minutesAdded: Int {
        baseTravelMinutes + delayMinutesApplied
    }

    /// Consumed percentile rolls in order (delay, then damage when present).
    var consumedRolls: [Int] {
        var rolls: [Int] = []
        if let delayRoll {
            rolls.append(delayRoll)
        }
        if let damageRoll {
            rolls.append(damageRoll)
        }
        return rolls
    }
}

/// Why appending to an event log was rejected.
nonisolated enum ExecutionEventLogRejection: Error, Equatable, Sendable {
    case sealed
}

/// Ordered execution event log for one delivery run.
///
/// Mutable while the run is in progress; sealed on completion so settlement and
/// presentation can rely on a fixed history.
nonisolated struct ExecutionEventLog: Equatable, Sendable {
    private(set) var events: [ExecutionResolutionEvent]
    /// When `true`, further `record` calls are rejected.
    private(set) var isSealed: Bool

    /// Final elapsed minutes derived from the last event (0 when empty).
    var totalElapsedMinutes: Int {
        events.last?.elapsedMinutesAfter ?? 0
    }

    /// Final damage-event count derived from the last event (0 when empty).
    var totalDamageEventCount: Int {
        events.last?.cumulativeDamageEventCount ?? 0
    }

    init(events: [ExecutionResolutionEvent] = [], isSealed: Bool = false) {
        self.events = events
        self.isSealed = isSealed
    }

    /// Appends one resolution event while the log is open.
    mutating func record(_ event: ExecutionResolutionEvent) -> Result<Void, ExecutionEventLogRejection> {
        if isSealed {
            return .failure(.sealed)
        }
        events.append(event)
        return .success(())
    }

    /// Freezes the log after execution completes. Idempotent.
    mutating func seal() {
        isSealed = true
    }

    /// Settlement-facing snapshot that does not require live execution state.
    var settlementSnapshot: ExecutionSettlementSnapshot {
        ExecutionSettlementSnapshot(
            events: events,
            totalElapsedMinutes: totalElapsedMinutes,
            totalDamageEventCount: totalDamageEventCount
        )
    }
}

/// Immutable view of a completed run suitable for outcome/settlement consumers.
nonisolated struct ExecutionSettlementSnapshot: Equatable, Sendable {
    let events: [ExecutionResolutionEvent]
    let totalElapsedMinutes: Int
    let totalDamageEventCount: Int
}
