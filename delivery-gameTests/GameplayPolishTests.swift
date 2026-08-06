//
//  GameplayPolishTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct GameplayPolishTests {

    @Test func cardShortCodesAreDistinctAndNonEmpty() {
        let codes = CardType.allCases.map { CardTypePresentation.forType($0).shortCode }
        #expect(Set(codes).count == CardType.allCases.count)
        #expect(codes.allSatisfy { $0.count == 2 })
    }

    @Test func visualStateExposesNonColourMarkersForRouteAndExecution() {
        let selected = GridCellVisualState.make(
            position: .standard,
            cardType: .heavyTraffic,
            isSelected: true,
            isEndpoint: true,
            isPlayerPosition: false,
            isActiveResolution: false,
            isEditingLocked: false
        )
        #expect(selected.cardCode == "HT")
        #expect(selected.markerLabels.contains("Route"))
        #expect(selected.markerLabels.contains("End"))
        #expect(selected.showsRouteChrome)

        let resolving = GridCellVisualState.make(
            position: .standard,
            cardType: .roadworks,
            isSelected: true,
            isEndpoint: false,
            isPlayerPosition: true,
            isActiveResolution: true,
            isEditingLocked: true
        )
        #expect(resolving.markerLabels.contains("Here"))
        #expect(resolving.markerLabels.contains("Now"))
        #expect(resolving.isDimmed == false)
    }

    @Test func lockedUnselectedCellsDimWithoutChangingCardCode() {
        let locked = GridCellVisualState.make(
            position: .standard,
            cardType: .fastLane,
            isSelected: false,
            isEndpoint: false,
            isPlayerPosition: false,
            isActiveResolution: false,
            isEditingLocked: true
        )
        #expect(locked.isDimmed)
        #expect(locked.cardCode == "FL")
        #expect(locked.markerLabels.isEmpty)
    }

    @Test func depotAndDestinationRolesRemainDistinctForClearRoad() {
        let depot = GridCellVisualState.make(
            position: .depot,
            cardType: .clearRoad,
            isSelected: true,
            isEndpoint: false,
            isPlayerPosition: false,
            isActiveResolution: false,
            isEditingLocked: false
        )
        let destination = GridCellVisualState.make(
            position: .destination,
            cardType: .clearRoad,
            isSelected: true,
            isEndpoint: true,
            isPlayerPosition: false,
            isActiveResolution: false,
            isEditingLocked: false
        )
        #expect(depot.roleTitle == "Depot")
        #expect(destination.roleTitle == "Destination")
        #expect(depot.markerLabels.contains("Depot"))
        #expect(destination.markerLabels.contains("Dest"))
        #expect(depot.cardCode == destination.cardCode)
    }

    @Test func presentationMotionKeepsDomainPlaybackCadenceAligned() {
        #expect(PresentationMotion.executionStepNanoseconds == ExecutionRunPreparer.defaultStepDelayNanoseconds)
        #expect(PresentationMotion.executionStepNanoseconds(reduceMotion: true) == 0)
        #expect(PresentationMotion.routeChromeDuration(reduceMotion: true) < PresentationMotion.routeChromeSeconds)
    }

    @Test func consequenceKindsRemainIndependentOfRewardSettlement() {
        #expect(ExecutionConsequenceKind.movement.statusText == "Moved")
        #expect(ExecutionConsequenceKind.delay.statusText == "Delayed")
        #expect(ExecutionConsequenceKind.damage.statusText == "Damaged")
    }
}
