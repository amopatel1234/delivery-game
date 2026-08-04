//
//  CardRuleDefinition.swift
//  delivery-game
//

import Foundation

/// Immutable timing and hazard metadata for one card type.
nonisolated struct CardRuleDefinition: Equatable, Sendable, Hashable {
    let type: CardType

    /// Base movement time in whole minutes when entering the card.
    let baseTravelTimeMinutes: Int

    /// Delay minutes applied when a delay occurs (always for fixed-delay cards;
    /// only after a successful delay roll for Heavy Traffic).
    let delayMinutes: Int

    /// Inclusive percentage chance (0...100) that the delay occurs.
    let delayProbabilityPercent: Int

    /// Inclusive percentage chance (0...100) of damage, rolled only after delay.
    let conditionalDamageProbabilityPercent: Int

    var canDelay: Bool {
        delayProbabilityPercent > 0 && delayMinutes > 0
    }

    var canCauseDamage: Bool {
        delayProbabilityPercent > 0 && conditionalDamageProbabilityPercent > 0
    }

    /// Overall damage chance in tenths of a percent (75 == 7.5%).
    var overallDamageProbabilityPermille: Int {
        delayProbabilityPercent * conditionalDamageProbabilityPercent / 10
    }
}

/// Canonical MVP card rule catalogue.
nonisolated enum CardRules {
    static let normalTravelTimeMinutes = 1
    static let lightTrafficDelayMinutes = 1
    static let heavyTrafficDelayMinutes = 2
    static let roadworksDelayMinutes = 2

    static let clearRoad = CardRuleDefinition(
        type: .clearRoad,
        baseTravelTimeMinutes: normalTravelTimeMinutes,
        delayMinutes: 0,
        delayProbabilityPercent: 0,
        conditionalDamageProbabilityPercent: 0
    )

    static let lightTraffic = CardRuleDefinition(
        type: .lightTraffic,
        baseTravelTimeMinutes: normalTravelTimeMinutes,
        delayMinutes: lightTrafficDelayMinutes,
        delayProbabilityPercent: 100,
        conditionalDamageProbabilityPercent: 0
    )

    static let heavyTraffic = CardRuleDefinition(
        type: .heavyTraffic,
        baseTravelTimeMinutes: normalTravelTimeMinutes,
        delayMinutes: heavyTrafficDelayMinutes,
        delayProbabilityPercent: 50,
        conditionalDamageProbabilityPercent: 15
    )

    static let roadworks = CardRuleDefinition(
        type: .roadworks,
        baseTravelTimeMinutes: normalTravelTimeMinutes,
        delayMinutes: roadworksDelayMinutes,
        delayProbabilityPercent: 100,
        conditionalDamageProbabilityPercent: 0
    )

    static let fastLane = CardRuleDefinition(
        type: .fastLane,
        baseTravelTimeMinutes: 0,
        delayMinutes: 0,
        delayProbabilityPercent: 0,
        conditionalDamageProbabilityPercent: 0
    )

    static let all: [CardRuleDefinition] = [
        clearRoad,
        lightTraffic,
        heavyTraffic,
        roadworks,
        fastLane,
    ]

    static func definition(for type: CardType) -> CardRuleDefinition {
        switch type {
        case .clearRoad: clearRoad
        case .lightTraffic: lightTraffic
        case .heavyTraffic: heavyTraffic
        case .roadworks: roadworks
        case .fastLane: fastLane
        }
    }
}
