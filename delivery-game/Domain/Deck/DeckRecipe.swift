//
//  DeckRecipe.swift
//  delivery-game
//

import Foundation

/// Canonical card counts used to construct an MVP board deck.
nonisolated struct DeckRecipe: Equatable, Sendable, Hashable {
    static let expectedTotalCount = 25
    static let reservedClearRoadCount = 2

    let clearRoadCount: Int
    let lightTrafficCount: Int
    let heavyTrafficCount: Int
    let roadworksCount: Int
    let fastLaneCount: Int

    /// Fixed MVP composition: 10 / 7 / 5 / 2 / 1.
    static let mvp = DeckRecipe(
        clearRoadCount: 10,
        lightTrafficCount: 7,
        heavyTrafficCount: 5,
        roadworksCount: 2,
        fastLaneCount: 1
    )

    var totalCount: Int {
        clearRoadCount
            + lightTrafficCount
            + heavyTrafficCount
            + roadworksCount
            + fastLaneCount
    }

    /// Clear Road cards available for seeded shuffle after depot/destination reservation.
    var placeableClearRoadCount: Int {
        clearRoadCount - Self.reservedClearRoadCount
    }

    func count(for type: CardType) -> Int {
        switch type {
        case .clearRoad: clearRoadCount
        case .lightTraffic: lightTrafficCount
        case .heavyTraffic: heavyTrafficCount
        case .roadworks: roadworksCount
        case .fastLane: fastLaneCount
        }
    }
}

/// Why a deck recipe cannot be used to build a board deck.
nonisolated enum DeckRecipeValidationError: Error, Equatable, Sendable {
    case invalidTotal(expected: Int, actual: Int)
    case invalidCount(type: CardType, expected: Int, actual: Int)
    case negativeCount(type: CardType, actual: Int)
    case insufficientClearRoadsForReservation(required: Int, available: Int)
}

/// Validates deck recipes before construction.
nonisolated enum DeckRecipeValidator {
    /// Structural checks required by every recipe used for MVP boards.
    static func validate(_ recipe: DeckRecipe) throws {
        for type in CardType.allCases {
            let actual = recipe.count(for: type)
            if actual < 0 {
                throw DeckRecipeValidationError.negativeCount(type: type, actual: actual)
            }
        }

        if recipe.totalCount != DeckRecipe.expectedTotalCount {
            throw DeckRecipeValidationError.invalidTotal(
                expected: DeckRecipe.expectedTotalCount,
                actual: recipe.totalCount
            )
        }

        if recipe.clearRoadCount < DeckRecipe.reservedClearRoadCount {
            throw DeckRecipeValidationError.insufficientClearRoadsForReservation(
                required: DeckRecipe.reservedClearRoadCount,
                available: recipe.clearRoadCount
            )
        }
    }

    /// Ensures a recipe matches the accepted MVP composition exactly.
    static func validateCanonicalMVP(_ recipe: DeckRecipe) throws {
        try validate(recipe)

        for type in CardType.allCases {
            let expected = DeckRecipe.mvp.count(for: type)
            let actual = recipe.count(for: type)
            if actual != expected {
                throw DeckRecipeValidationError.invalidCount(
                    type: type,
                    expected: expected,
                    actual: actual
                )
            }
        }
    }
}

/// Immutable constructed deck with depot/destination Clear Roads reserved.
nonisolated struct ConstructedDeck: Equatable, Sendable, Hashable {
    /// Always two Clear Road cards reserved for depot and destination.
    let reservedClearRoads: [CardType]

    /// Remaining cards available for deterministic shuffle/placement.
    let placeableCards: [CardType]

    /// Full 25-card multiset (reserved first, then placeable).
    var allCards: [CardType] {
        reservedClearRoads + placeableCards
    }
}

/// Builds an immutable deck from a validated recipe.
nonisolated enum DeckBuilder {
    static func build(from recipe: DeckRecipe = .mvp) throws -> ConstructedDeck {
        try DeckRecipeValidator.validate(recipe)

        let reservedClearRoads = Array(
            repeating: CardType.clearRoad,
            count: DeckRecipe.reservedClearRoadCount
        )

        var placeableCards: [CardType] = []
        placeableCards.append(
            contentsOf: Array(
                repeating: .clearRoad,
                count: recipe.placeableClearRoadCount
            )
        )
        placeableCards.append(
            contentsOf: Array(repeating: .lightTraffic, count: recipe.lightTrafficCount)
        )
        placeableCards.append(
            contentsOf: Array(repeating: .heavyTraffic, count: recipe.heavyTrafficCount)
        )
        placeableCards.append(
            contentsOf: Array(repeating: .roadworks, count: recipe.roadworksCount)
        )
        placeableCards.append(
            contentsOf: Array(repeating: .fastLane, count: recipe.fastLaneCount)
        )

        return ConstructedDeck(
            reservedClearRoads: reservedClearRoads,
            placeableCards: placeableCards
        )
    }
}
