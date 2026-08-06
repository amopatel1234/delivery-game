//
//  GridPresentationTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct GridPresentationTests {

    @Test func everyCardTypeHasPresentationMetadata() {
        for type in CardType.allCases {
            let presentation = CardTypePresentation.forType(type)
            #expect(!presentation.symbolName.isEmpty)
            #expect(!presentation.title.isEmpty)
            #expect(!presentation.shortCode.isEmpty)
            #expect(!presentation.accessibilityLabel.isEmpty)
        }
    }

    @Test func cardTypeSymbolsAreDistinct() {
        let symbols = Set(CardType.allCases.map { CardTypePresentation.forType($0).symbolName })
        #expect(symbols.count == CardType.allCases.count)
        let codes = Set(CardType.allCases.map { CardTypePresentation.forType($0).shortCode })
        #expect(codes.count == CardType.allCases.count)
    }

    @Test func accessibilityIdentifiersCoverBoardAndFixedPositions() {
        #expect(GridAccessibilityID.board == "grid-board")
        #expect(GridAccessibilityID.cell(row: 0, column: 0) == "grid-cell-r0-c0")
        #expect(GridAccessibilityID.cell(.depot) == "grid-cell-r0-c0")
        #expect(GridAccessibilityID.cell(.destination) == "grid-cell-r4-c4")
        #expect(GridAccessibilityID.startGameButton == "main-menu-start-game")
    }

    @Test func depotAndDestinationRemainIdentifiableBeyondCardType() throws {
        let grid = try DeliveryGrid(board: BoardGenerator.generate(seed: 1001))

        #expect(grid.depotCell.isDepot)
        #expect(grid.destinationCell.isDestination)
        #expect(grid.depotCell.cardType == .clearRoad)
        #expect(grid.destinationCell.cardType == .clearRoad)

        // Role labels used by the cell view must differ even when both are Clear Road.
        #expect(grid.depotCell.position != grid.destinationCell.position)
    }

    @Test func defaultJobBoardProvidesFullCoordinateCoverage() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let grid = try DeliveryGrid(board: job.board)
        #expect(grid.cells.count == 25)
        #expect(Set(grid.cells.map(\.coordinate)).count == 25)
    }
}
