//
//  BoardGeneratorTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct BoardGeneratorTests {

    @Test func sameSeedProducesIdenticalBoard() throws {
        let lhs = try BoardGenerator.generate(seed: 42)
        let rhs = try BoardGenerator.generate(seed: 42)

        #expect(lhs == rhs)
        #expect(lhs.generatorVersion == BoardGenerator.version)
        #expect(lhs.seed == 42)
    }

    @Test func differentSeedsProduceDifferentBoards() throws {
        let lhs = try BoardGenerator.generate(seed: 42)
        let rhs = try BoardGenerator.generate(seed: 4_242)

        #expect(lhs.cells.map(\.cardType) != rhs.cells.map(\.cardType))
    }

    @Test func placesDepotAndDestinationAsClearRoad() throws {
        let board = try BoardGenerator.generate(seed: 7)

        #expect(board.depotCoordinate == GridCoordinate(row: 0, column: 0))
        #expect(board.destinationCoordinate == GridCoordinate(row: 4, column: 4))
        #expect(board.cardType(at: .depot) == .clearRoad)
        #expect(board.cardType(at: .destination) == .clearRoad)
    }

    @Test func producesExactlyOneCardPerCoordinate() throws {
        let board = try BoardGenerator.generate(seed: 99)

        #expect(board.cells.count == 25)
        #expect(Set(board.cells.map(\.coordinate)).count == 25)
        #expect(Set(board.cells.map(\.coordinate)) == Set(GridCoordinate.allInRowMajorOrder))
    }

    @Test func generatedBoardMatchesMVPComposition() throws {
        let board = try BoardGenerator.generate(seed: 123)
        try BoardValidator.validate(board, recipe: .mvp)

        let counts = Dictionary(grouping: board.cells, by: \.cardType).mapValues(\.count)
        #expect(counts[.clearRoad] == 10)
        #expect(counts[.lightTraffic] == 7)
        #expect(counts[.heavyTraffic] == 5)
        #expect(counts[.roadworks] == 2)
        #expect(counts[.fastLane] == 1)
    }

    @Test func scriptedRNGControlsPlaceableOrder() throws {
        // For 23 placeable cards, Fisher-Yates requests swaps for indices 22...1.
        // Returning the current index each time leaves the array unchanged.
        var identityRNG = FixedSequenceRandomNumberGenerator(
            values: Array(stride(from: 22, through: 1, by: -1))
        )
        let board = try BoardGenerator.generate(seed: 1, rng: &identityRNG)

        let expectedPlaceable = try DeckBuilder.build(from: .mvp).placeableCards
        let actualPlaceable = board.cells
            .filter { $0.coordinate != .depot && $0.coordinate != .destination }
            .sorted { $0.coordinate < $1.coordinate }
            .map(\.cardType)

        #expect(actualPlaceable == expectedPlaceable)
        #expect(board.cardType(at: .depot) == .clearRoad)
        #expect(board.cardType(at: .destination) == .clearRoad)
    }

    @Test func validatorRejectsDuplicateCoordinates() throws {
        var cells = try BoardGenerator.generate(seed: 1).cells
        if let index = cells.firstIndex(where: { $0.coordinate == .destination }) {
            cells[index] = BoardCell(coordinate: .depot, cardType: .clearRoad)
        }
        let board = GeneratedBoard(generatorVersion: 1, seed: 1, cells: cells)

        #expect(throws: BoardValidationError.duplicateCoordinate(.depot)) {
            try BoardValidator.validate(board)
        }
    }

    @Test func validatorRejectsWrongCellCount() {
        let board = GeneratedBoard(
            generatorVersion: 1,
            seed: 0,
            cells: [
                BoardCell(coordinate: .depot, cardType: .clearRoad),
            ]
        )

        #expect(throws: BoardValidationError.invalidCellCount(expected: 25, actual: 1)) {
            try BoardValidator.validate(board)
        }
    }

    @Test func validatorRejectsNonClearRoadDepot() throws {
        var cells = try BoardGenerator.generate(seed: 1).cells
        if let index = cells.firstIndex(where: { $0.coordinate == .depot }) {
            cells[index] = BoardCell(coordinate: .depot, cardType: .heavyTraffic)
        }
        let board = GeneratedBoard(generatorVersion: 1, seed: 1, cells: cells)

        #expect(throws: BoardValidationError.depotNotClearRoad(.heavyTraffic)) {
            try BoardValidator.validate(board)
        }
    }
}
