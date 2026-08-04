//
//  BoardGenerator.swift
//  delivery-game
//

import Foundation

/// Zero-based coordinate on the fixed MVP delivery grid.
nonisolated struct GridCoordinate: Equatable, Sendable, Hashable, Comparable {
    static let boardSize = 5

    let row: Int
    let column: Int

    static let depot = GridCoordinate(row: 0, column: 0)
    static let destination = GridCoordinate(
        row: boardSize - 1,
        column: boardSize - 1
    )

    var isOnBoard: Bool {
        (0 ..< Self.boardSize).contains(row) && (0 ..< Self.boardSize).contains(column)
    }

    /// All board coordinates in stable row-major order.
    static var allInRowMajorOrder: [GridCoordinate] {
        (0 ..< boardSize).flatMap { row in
            (0 ..< boardSize).map { column in
                GridCoordinate(row: row, column: column)
            }
        }
    }

    static func < (lhs: GridCoordinate, rhs: GridCoordinate) -> Bool {
        if lhs.row != rhs.row {
            return lhs.row < rhs.row
        }
        return lhs.column < rhs.column
    }
}

/// One immutable cell on a generated board.
nonisolated struct BoardCell: Equatable, Sendable, Hashable {
    let coordinate: GridCoordinate
    let cardType: CardType
}

/// Immutable deterministic board produced by `BoardGenerator`.
nonisolated struct GeneratedBoard: Equatable, Sendable, Hashable {
    /// Bump intentionally when shuffle/placement semantics change.
    let generatorVersion: Int
    let seed: UInt64
    let cells: [BoardCell]

    var depotCoordinate: GridCoordinate { .depot }
    var destinationCoordinate: GridCoordinate { .destination }

    func cardType(at coordinate: GridCoordinate) -> CardType? {
        cells.first { $0.coordinate == coordinate }?.cardType
    }
}

/// Why a generated board fails structural checks.
nonisolated enum BoardValidationError: Error, Equatable, Sendable {
    case invalidCellCount(expected: Int, actual: Int)
    case duplicateCoordinate(GridCoordinate)
    case missingCoordinate(GridCoordinate)
    case outOfBoundsCoordinate(GridCoordinate)
    case depotNotClearRoad(CardType)
    case destinationNotClearRoad(CardType)
    case invalidComposition(type: CardType, expected: Int, actual: Int)
}

/// Validates generated boards against MVP structural rules.
nonisolated enum BoardValidator {
    static func validate(_ board: GeneratedBoard, recipe: DeckRecipe = .mvp) throws {
        let expectedCount = GridCoordinate.boardSize * GridCoordinate.boardSize
        if board.cells.count != expectedCount {
            throw BoardValidationError.invalidCellCount(
                expected: expectedCount,
                actual: board.cells.count
            )
        }

        var seen: Set<GridCoordinate> = []
        for cell in board.cells {
            if !cell.coordinate.isOnBoard {
                throw BoardValidationError.outOfBoundsCoordinate(cell.coordinate)
            }
            if !seen.insert(cell.coordinate).inserted {
                throw BoardValidationError.duplicateCoordinate(cell.coordinate)
            }
        }

        for coordinate in GridCoordinate.allInRowMajorOrder where !seen.contains(coordinate) {
            throw BoardValidationError.missingCoordinate(coordinate)
        }

        guard let depotCell = board.cells.first(where: { $0.coordinate == .depot }) else {
            throw BoardValidationError.missingCoordinate(.depot)
        }
        if depotCell.cardType != .clearRoad {
            throw BoardValidationError.depotNotClearRoad(depotCell.cardType)
        }

        guard let destinationCell = board.cells.first(where: { $0.coordinate == .destination }) else {
            throw BoardValidationError.missingCoordinate(.destination)
        }
        if destinationCell.cardType != .clearRoad {
            throw BoardValidationError.destinationNotClearRoad(destinationCell.cardType)
        }

        let counts = Dictionary(grouping: board.cells, by: \.cardType).mapValues(\.count)
        for type in CardType.allCases {
            let expected = recipe.count(for: type)
            let actual = counts[type] ?? 0
            if actual != expected {
                throw BoardValidationError.invalidComposition(
                    type: type,
                    expected: expected,
                    actual: actual
                )
            }
        }
    }
}

/// Deterministically places a validated deck onto the 5×5 grid.
nonisolated enum BoardGenerator {
    /// Version of the placement algorithm. Changing this is a product-data change.
    static let version = 1

    static func generate(
        seed: UInt64,
        recipe: DeckRecipe = .mvp
    ) throws -> GeneratedBoard {
        var rng = SeededRandomNumberGenerator(seed: seed)
        return try generate(seed: seed, recipe: recipe, rng: &rng)
    }

    static func generate<RNG: RandomNumberGenerating>(
        seed: UInt64,
        recipe: DeckRecipe = .mvp,
        rng: inout RNG
    ) throws -> GeneratedBoard {
        let deck = try DeckBuilder.build(from: recipe)
        var placeableCards = deck.placeableCards
        shuffle(&placeableCards, using: &rng)

        let placeableCoordinates = GridCoordinate.allInRowMajorOrder.filter {
            $0 != .depot && $0 != .destination
        }
        precondition(
            placeableCoordinates.count == placeableCards.count,
            "Placeable coordinate count must match placeable card count"
        )

        var cells: [BoardCell] = [
            BoardCell(coordinate: .depot, cardType: .clearRoad),
            BoardCell(coordinate: .destination, cardType: .clearRoad),
        ]

        for (coordinate, cardType) in zip(placeableCoordinates, placeableCards) {
            cells.append(BoardCell(coordinate: coordinate, cardType: cardType))
        }

        cells.sort { $0.coordinate < $1.coordinate }

        let board = GeneratedBoard(
            generatorVersion: version,
            seed: seed,
            cells: cells
        )
        try BoardValidator.validate(board, recipe: recipe)
        return board
    }

    /// Fisher–Yates shuffle driven by an injectable RNG.
    private static func shuffle<RNG: RandomNumberGenerating>(
        _ cards: inout [CardType],
        using rng: inout RNG
    ) {
        guard cards.count > 1 else { return }
        for index in stride(from: cards.count - 1, through: 1, by: -1) {
            let swapIndex = rng.nextInt(in: 0 ... index)
            cards.swapAt(index, swapIndex)
        }
    }
}
