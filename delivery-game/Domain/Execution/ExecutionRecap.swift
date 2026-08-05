//
//  ExecutionRecap.swift
//  delivery-game
//

import Foundation

/// One card row in a completed-route recap.
///
/// Movement time, delay and damage are kept separate so presentation and
/// Epic 4 settlement can reuse the same values.
nonisolated struct ExecutionRecapEntry: Equatable, Sendable, Identifiable {
    /// Matches `ExecutionResolutionEvent.enteredIndex`.
    let enteredIndex: Int
    let coordinate: GridCoordinate
    let cardType: CardType
    /// Base travel minutes for this card (excludes delay).
    let baseTravelMinutes: Int
    /// Delay minutes applied on this card (0 when none).
    let delayMinutesApplied: Int
    let didDelay: Bool
    let didDamage: Bool
    let delayRoll: Int?
    let damageRoll: Int?

    var id: Int { enteredIndex }

    var movementMinutes: Int { baseTravelMinutes }
    var delayMinutes: Int { delayMinutesApplied }
    var minutesAdded: Int { baseTravelMinutes + delayMinutesApplied }

    init(event: ExecutionResolutionEvent) {
        self.enteredIndex = event.enteredIndex
        self.coordinate = event.coordinate
        self.cardType = event.cardType
        self.baseTravelMinutes = event.baseTravelMinutes
        self.delayMinutesApplied = event.delayMinutesApplied
        self.didDelay = event.didDelay
        self.didDamage = event.didDamage
        self.delayRoll = event.delayRoll
        self.damageRoll = event.damageRoll
    }
}

/// Presentation-independent summary of a finished execution run.
///
/// Built only from confirmed input + sealed event history. Does not decide
/// completed/failed payout status (Epic 4).
nonisolated struct ExecutionRecap: Equatable, Sendable {
    let jobID: SeededJobID
    let jobDisplayName: String
    let targetTimeMinutes: Int
    let deadlineMinutes: Int
    let entries: [ExecutionRecapEntry]
    let totalBaseTravelMinutes: Int
    let totalDelayMinutes: Int
    let totalElapsedMinutes: Int
    let totalDamageEvents: Int
    let delayedCardCount: Int

    var cardCount: Int { entries.count }

    /// Builds a recap from a sealed (or complete) event log.
    static func from(
        input: ExecutionInput,
        eventLog: ExecutionEventLog
    ) -> ExecutionRecap {
        from(input: input, events: eventLog.events)
    }

    /// Builds a recap from an execution state after the run finishes.
    static func from(
        input: ExecutionInput,
        state: ExecutionState
    ) -> ExecutionRecap {
        let recap = from(input: input, events: state.eventLog.events)
        precondition(
            recap.totalElapsedMinutes == state.elapsedMinutes,
            "Recap elapsed minutes must match execution state"
        )
        precondition(
            recap.totalDamageEvents == state.damageEventCount,
            "Recap damage count must match execution state"
        )
        return recap
    }

    static func from(
        input: ExecutionInput,
        events: [ExecutionResolutionEvent]
    ) -> ExecutionRecap {
        let entries = events.map(ExecutionRecapEntry.init(event:))
        let totalBase = entries.reduce(0) { $0 + $1.baseTravelMinutes }
        let totalDelay = entries.reduce(0) { $0 + $1.delayMinutesApplied }
        let delayedCount = entries.filter(\.didDelay).count
        let damageCount = entries.filter(\.didDamage).count
        let elapsed = events.last?.elapsedMinutesAfter ?? 0

        return ExecutionRecap(
            jobID: input.jobID,
            jobDisplayName: input.jobDisplayName,
            targetTimeMinutes: input.targetTimeMinutes,
            deadlineMinutes: input.deadlineMinutes,
            entries: entries,
            totalBaseTravelMinutes: totalBase,
            totalDelayMinutes: totalDelay,
            totalElapsedMinutes: elapsed,
            totalDamageEvents: damageCount,
            delayedCardCount: delayedCount
        )
    }
}
