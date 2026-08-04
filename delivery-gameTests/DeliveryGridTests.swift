//
//  DeliveryGridTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct DeliveryGridTests {

    @Test func representsExactlyTwentyFiveUniqueCoordinates() throws {
        let grid = try DeliveryGrid(board: BoardGenerator.generate(seed: 42))

        #expect(grid.cells.count == DeliveryGrid.cellCount)
        #expect(Set(grid.cells.map(\.coordinate)).count == 25)
        #expect(Set(grid.cells.map(\.coordinate)) == Set(GridCoordinate.allInRowMajorOrder))
    }

    @Test func mapsEveryCoordinateToOneCard() throws {
        let board = try BoardGenerator.generate(seed: 7)
        let grid = try DeliveryGrid(board: board)

        for coordinate in GridCoordinate.allInRowMajorOrder {
            #expect(grid.containsCoordinate(coordinate))
            #expect(grid.cardType(at: coordinate) == board.cardType(at: coordinate))
            #expect(grid.cell(at: coordinate).coordinate == coordinate)
        }
    }

    @Test func identifiesDepotAndDestinationPositions() throws {
        let grid = try DeliveryGrid(board: BoardGenerator.generate(seed: 11))

        #expect(grid.depotCoordinate == GridCoordinate(row: 0, column: 0))
        #expect(grid.destinationCoordinate == GridCoordinate(row: 4, column: 4))
        #expect(grid.depotCell.isDepot)
        #expect(grid.destinationCell.isDestination)
        #expect(grid.depotCell.position == .depot)
        #expect(grid.destinationCell.position == .destination)
        #expect(grid.cell(at: GridCoordinate(row: 1, column: 1)).position == .standard)
    }

    @Test func remainsImmutableAfterCreationFromSeededBoard() throws {
        let first = try DeliveryGrid(board: BoardGenerator.generate(seed: 99))
        let second = try DeliveryGrid(board: BoardGenerator.generate(seed: 99))
        #expect(first == second)
        #expect(first.cells == second.cells)
    }

    @Test func rejectsDuplicateCoordinates() throws {
        var cells = try validCells(seed: 1)
        if let index = cells.firstIndex(where: { $0.coordinate == .destination }) {
            cells[index] = GridCell(coordinate: .depot, cardType: .lightTraffic)
        }

        #expect(throws: DeliveryGridError.duplicateCoordinate(.depot)) {
            try DeliveryGrid(cells: cells)
        }
    }

    @Test func rejectsMissingCoordinatesViaIncompleteCellCount() throws {
        let cells = try validCells(seed: 1).filter {
            $0.coordinate != GridCoordinate(row: 3, column: 3)
        }

        #expect(throws: DeliveryGridError.invalidCellCount(expected: 25, actual: 24)) {
            try DeliveryGrid(cells: cells)
        }
    }

    @Test func rejectsOutOfBoundsCoordinates() throws {
        var cells = try validCells(seed: 1).filter {
            $0.coordinate != GridCoordinate(row: 1, column: 1)
        }
        cells.append(
            GridCell(
                coordinate: GridCoordinate(row: 5, column: 0),
                cardType: .clearRoad
            )
        )

        #expect(throws: DeliveryGridError.outOfBoundsCoordinate(GridCoordinate(row: 5, column: 0))) {
            try DeliveryGrid(cells: cells)
        }
    }

    @Test func rejectsInvalidCellCount() {
        #expect(throws: DeliveryGridError.invalidCellCount(expected: 25, actual: 0)) {
            try DeliveryGrid(cells: [])
        }
    }

    @Test func lookupMatchesGeneratedBoardAndSeededJob() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let grid = try DeliveryGrid(board: job.board)

        for cell in job.board.cells {
            #expect(grid.cardType(at: cell.coordinate) == cell.cardType)
            #expect(grid.cell(at: cell.coordinate).cardType == cell.cardType)
        }
    }

    private func validCells(seed: UInt64) throws -> [GridCell] {
        let board = try BoardGenerator.generate(seed: seed)
        return board.cells.map {
            GridCell(coordinate: $0.coordinate, cardType: $0.cardType)
        }
    }
}
