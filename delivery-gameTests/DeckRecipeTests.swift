//
//  DeckRecipeTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct DeckRecipeTests {

    @Test func mvpRecipeHasExactComposition() {
        let recipe = DeckRecipe.mvp

        #expect(recipe.clearRoadCount == 10)
        #expect(recipe.lightTrafficCount == 7)
        #expect(recipe.heavyTrafficCount == 5)
        #expect(recipe.roadworksCount == 2)
        #expect(recipe.fastLaneCount == 1)
        #expect(recipe.totalCount == 25)
        #expect(recipe.placeableClearRoadCount == 8)
    }

    @Test func mvpRecipePassesCanonicalValidation() throws {
        try DeckRecipeValidator.validateCanonicalMVP(.mvp)
    }

    @Test func buildCreatesExactlyTwentyFiveCards() throws {
        let deck = try DeckBuilder.build(from: .mvp)
        #expect(deck.allCards.count == 25)
        #expect(deck.reservedClearRoads.count + deck.placeableCards.count == 25)
    }

    @Test func buildMatchesCanonicalCardCounts() throws {
        let deck = try DeckBuilder.build(from: .mvp)
        let counts = Dictionary(grouping: deck.allCards, by: { $0 }).mapValues(\.count)

        #expect(counts[.clearRoad] == 10)
        #expect(counts[.lightTraffic] == 7)
        #expect(counts[.heavyTraffic] == 5)
        #expect(counts[.roadworks] == 2)
        #expect(counts[.fastLane] == 1)
    }

    @Test func buildReservesTwoClearRoadsForDepotAndDestination() throws {
        let deck = try DeckBuilder.build(from: .mvp)

        #expect(deck.reservedClearRoads == [.clearRoad, .clearRoad])
        #expect(deck.reservedClearRoads.count == DeckRecipe.reservedClearRoadCount)

        let placeableClearRoads = deck.placeableCards.filter { $0 == .clearRoad }
        #expect(placeableClearRoads.count == 8)
        #expect(deck.placeableCards.count == 23)
    }

    @Test func rejectsInvalidTotal() {
        let recipe = DeckRecipe(
            clearRoadCount: 9,
            lightTrafficCount: 7,
            heavyTrafficCount: 5,
            roadworksCount: 2,
            fastLaneCount: 1
        )

        #expect(throws: DeckRecipeValidationError.invalidTotal(expected: 25, actual: 24)) {
            try DeckRecipeValidator.validate(recipe)
        }
        #expect(throws: DeckRecipeValidationError.invalidTotal(expected: 25, actual: 24)) {
            try DeckBuilder.build(from: recipe)
        }
    }

    @Test func rejectsInsufficientClearRoadsForReservation() {
        let recipe = DeckRecipe(
            clearRoadCount: 1,
            lightTrafficCount: 10,
            heavyTrafficCount: 8,
            roadworksCount: 5,
            fastLaneCount: 1
        )

        #expect(
            throws: DeckRecipeValidationError.insufficientClearRoadsForReservation(
                required: 2,
                available: 1
            )
        ) {
            try DeckRecipeValidator.validate(recipe)
        }
    }

    @Test func rejectsNegativeCardCounts() {
        let recipe = DeckRecipe(
            clearRoadCount: 10,
            lightTrafficCount: -1,
            heavyTrafficCount: 5,
            roadworksCount: 2,
            fastLaneCount: 1
        )

        #expect(
            throws: DeckRecipeValidationError.negativeCount(type: .lightTraffic, actual: -1)
        ) {
            try DeckRecipeValidator.validate(recipe)
        }
    }

    @Test func rejectsNonCanonicalCardCounts() {
        let recipe = DeckRecipe(
            clearRoadCount: 11,
            lightTrafficCount: 6,
            heavyTrafficCount: 5,
            roadworksCount: 2,
            fastLaneCount: 1
        )

        #expect(
            throws: DeckRecipeValidationError.invalidCount(
                type: .clearRoad,
                expected: 10,
                actual: 11
            )
        ) {
            try DeckRecipeValidator.validateCanonicalMVP(recipe)
        }
    }
}
