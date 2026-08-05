//
//  CardResolver.swift
//  delivery-game
//

import Foundation

/// Injected Heavy Traffic hazard outcome.
///
/// Probability rolls are produced by `HazardResolver`. This value is the
/// decision those rolls produce; damage is only applied when a delay also occurred.
nonisolated struct HeavyTrafficHazardOutcome: Equatable, Sendable {
    let delayed: Bool
    let damaged: Bool

    static let noHazard = HeavyTrafficHazardOutcome(delayed: false, damaged: false)
    static let delayedOnly = HeavyTrafficHazardOutcome(delayed: true, damaged: false)
    static let delayedAndDamaged = HeavyTrafficHazardOutcome(delayed: true, damaged: true)
}

/// Why card resolution could not produce a valid outcome.
nonisolated enum CardResolutionRejection: Equatable, Sendable {
    /// Heavy Traffic was resolved without an injected hazard decision.
    case missingHeavyTrafficHazard
}

/// Timing and damage applied when one entered card resolves.
nonisolated struct CardResolutionOutcome: Equatable, Sendable {
    let cardType: CardType
    let rule: CardRuleDefinition
    let baseTravelMinutes: Int
    let delayMinutesApplied: Int
    let didDelay: Bool
    let didDamage: Bool

    var totalMinutesAdded: Int {
        baseTravelMinutes + delayMinutesApplied
    }
}

/// Result of resolving one card's gameplay behaviour.
nonisolated enum CardResolutionResult: Equatable, Sendable {
    case resolved(CardResolutionOutcome)
    case rejected(CardResolutionRejection)
}

/// Pure card-resolution rules used during execution.
///
/// Applies deterministic travel and fixed delays from `CardRules`. Probabilistic
/// Heavy Traffic outcomes are supplied by the caller (`HazardResolver`).
nonisolated enum CardResolver {
    static func resolve(
        cardType: CardType,
        heavyTrafficHazard: HeavyTrafficHazardOutcome? = nil
    ) -> CardResolutionResult {
        let rule = CardRules.definition(for: cardType)

        switch cardType {
        case .clearRoad, .fastLane:
            return .resolved(
                CardResolutionOutcome(
                    cardType: cardType,
                    rule: rule,
                    baseTravelMinutes: rule.baseTravelTimeMinutes,
                    delayMinutesApplied: 0,
                    didDelay: false,
                    didDamage: false
                )
            )

        case .lightTraffic, .roadworks:
            return .resolved(
                CardResolutionOutcome(
                    cardType: cardType,
                    rule: rule,
                    baseTravelMinutes: rule.baseTravelTimeMinutes,
                    delayMinutesApplied: rule.delayMinutes,
                    didDelay: true,
                    didDamage: false
                )
            )

        case .heavyTraffic:
            guard let hazard = heavyTrafficHazard else {
                return .rejected(.missingHeavyTrafficHazard)
            }
            let didDelay = hazard.delayed
            let didDamage = didDelay && hazard.damaged
            return .resolved(
                CardResolutionOutcome(
                    cardType: cardType,
                    rule: rule,
                    baseTravelMinutes: rule.baseTravelTimeMinutes,
                    delayMinutesApplied: didDelay ? rule.delayMinutes : 0,
                    didDelay: didDelay,
                    didDamage: didDamage
                )
            )
        }
    }
}
