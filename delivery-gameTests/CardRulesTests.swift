//
//  CardRulesTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct CardRulesTests {

    @Test func definesAllFiveMVPCardTypes() {
        let types = CardType.allCases
        #expect(types.count == 5)
        #expect(types.contains(.clearRoad))
        #expect(types.contains(.lightTraffic))
        #expect(types.contains(.heavyTraffic))
        #expect(types.contains(.roadworks))
        #expect(types.contains(.fastLane))
    }

    @Test func stableIdentifiersAreStable() {
        #expect(CardType.clearRoad.rawValue == "clear_road")
        #expect(CardType.lightTraffic.rawValue == "light_traffic")
        #expect(CardType.heavyTraffic.rawValue == "heavy_traffic")
        #expect(CardType.roadworks.rawValue == "roadworks")
        #expect(CardType.fastLane.rawValue == "fast_lane")
    }

    @Test func catalogueCoversEveryCardTypeExactlyOnce() {
        #expect(CardRules.all.count == CardType.allCases.count)
        #expect(Set(CardRules.all.map(\.type)) == Set(CardType.allCases))
    }

    @Test func definitionLookupMatchesCatalogue() {
        for type in CardType.allCases {
            #expect(CardRules.definition(for: type).type == type)
            #expect(CardRules.definition(for: type) == CardRules.all.first { $0.type == type })
        }
    }

    @Test func clearRoadUsesNormalTravelWithNoHazards() {
        let rule = CardRules.clearRoad
        #expect(rule.baseTravelTimeMinutes == CardRules.normalTravelTimeMinutes)
        #expect(rule.delayMinutes == 0)
        #expect(rule.delayProbabilityPercent == 0)
        #expect(rule.conditionalDamageProbabilityPercent == 0)
        #expect(rule.canDelay == false)
        #expect(rule.canCauseDamage == false)
    }

    @Test func lightTrafficAppliesFixedDelayWithoutDamage() {
        let rule = CardRules.lightTraffic
        #expect(rule.baseTravelTimeMinutes == CardRules.normalTravelTimeMinutes)
        #expect(rule.delayMinutes == CardRules.lightTrafficDelayMinutes)
        #expect(rule.delayProbabilityPercent == 100)
        #expect(rule.conditionalDamageProbabilityPercent == 0)
        #expect(rule.canDelay == true)
        #expect(rule.canCauseDamage == false)
    }

    @Test func heavyTrafficDefinesConditionalDelayAndDamage() {
        let rule = CardRules.heavyTraffic
        #expect(rule.baseTravelTimeMinutes == CardRules.normalTravelTimeMinutes)
        #expect(rule.delayMinutes == CardRules.heavyTrafficDelayMinutes)
        #expect(rule.delayProbabilityPercent == 50)
        #expect(rule.conditionalDamageProbabilityPercent == 15)
        #expect(rule.overallDamageProbabilityPermille == 75) // 7.5%
        #expect(rule.canDelay == true)
        #expect(rule.canCauseDamage == true)
    }

    @Test func roadworksAppliesFixedDelayWithoutDamage() {
        let rule = CardRules.roadworks
        #expect(rule.baseTravelTimeMinutes == CardRules.normalTravelTimeMinutes)
        #expect(rule.delayMinutes == CardRules.roadworksDelayMinutes)
        #expect(rule.delayProbabilityPercent == 100)
        #expect(rule.conditionalDamageProbabilityPercent == 0)
        #expect(rule.canDelay == true)
        #expect(rule.canCauseDamage == false)
    }

    @Test func fastLaneHasZeroTravelTimeAndNoHazards() {
        let rule = CardRules.fastLane
        #expect(rule.baseTravelTimeMinutes == 0)
        #expect(rule.delayMinutes == 0)
        #expect(rule.delayProbabilityPercent == 0)
        #expect(rule.conditionalDamageProbabilityPercent == 0)
        #expect(rule.canDelay == false)
        #expect(rule.canCauseDamage == false)
    }

    @Test func allDefinitionsAreValueEqualAcrossLookups() {
        #expect(CardRules.clearRoad == CardRules.definition(for: .clearRoad))
        #expect(CardRules.fastLane == CardRules.definition(for: .fastLane))
    }
}
