//
//  DeliveryGrid.swift
//  delivery-game
//

import Foundation

/// Fixed role of a coordinate on the delivery grid.
nonisolated enum GridPosition: Equatable, Sendable, Hashable {
    case depot
    case destination
    case standard

    init(coordinate: GridCoordinate) {
        if coordinate == .depot {
            self = .depot
        } else if coordinate == .destination {
            self = .destination
        } else {
            self = .standard
        }
    }
}

/// One immutable occupied cell on the delivery grid.
nonisolated struct GridCell: Equatable, Sendable, Hashable {
    let coordinate: GridCoordinate
    let cardType: CardType

    var position: GridPosition {
        GridPosition(coordinate: coordinate)
    }

    var isDepot: Bool { position == .depot }
    var isDestination: Bool { position == .destination }
}

/// Why a delivery grid cannot be constructed.
nonisolated enum DeliveryGridError: Error, Equatable, Sendable {
    case invalidCellCount(expected: Int, actual: Int)
    case duplicateCoordinate(GridCoordinate)
    case missingCoordinate(GridCoordinate)
    case outOfBoundsCoordinate(GridCoordinate)
}

/// Immutable 5×5 delivery grid with constant-time cell lookup.
nonisolated struct DeliveryGrid: Equatable, Sendable {
    static let size = GridCoordinate.boardSize
    static let cellCount = size * size

    private let cellsByCoordinate: [GridCoordinate: GridCell]

    var depotCoordinate: GridCoordinate { .depot }
    var destinationCoordinate: GridCoordinate { .destination }

    var depotCell: GridCell {
        cell(at: depotCoordinate)
    }

    var destinationCell: GridCell {
        cell(at: destinationCoordinate)
    }

    /// All cells in stable row-major order.
    var cells: [GridCell] {
        GridCoordinate.allInRowMajorOrder.map(cell(at:))
    }

    /// Builds a validated grid from explicit cells.
    init(cells: [GridCell]) throws {
        self.cellsByCoordinate = try Self.makeLookup(from: cells)
    }

    /// Builds a validated grid from a generated board.
    init(board: GeneratedBoard) throws {
        let cells = board.cells.map {
            GridCell(coordinate: $0.coordinate, cardType: $0.cardType)
        }
        try self.init(cells: cells)
    }

    func cell(at coordinate: GridCoordinate) -> GridCell {
        guard let cell = cellsByCoordinate[coordinate] else {
            preconditionFailure("DeliveryGrid missing coordinate \(coordinate)")
        }
        return cell
    }

    func cardType(at coordinate: GridCoordinate) -> CardType {
        cell(at: coordinate).cardType
    }

    func containsCoordinate(_ coordinate: GridCoordinate) -> Bool {
        cellsByCoordinate[coordinate] != nil
    }

    private static func makeLookup(
        from cells: [GridCell]
    ) throws -> [GridCoordinate: GridCell] {
        if cells.count != cellCount {
            throw DeliveryGridError.invalidCellCount(
                expected: cellCount,
                actual: cells.count
            )
        }

        var lookup: [GridCoordinate: GridCell] = [:]
        lookup.reserveCapacity(cellCount)

        for cell in cells {
            if !cell.coordinate.isOnBoard {
                throw DeliveryGridError.outOfBoundsCoordinate(cell.coordinate)
            }
            if lookup[cell.coordinate] != nil {
                throw DeliveryGridError.duplicateCoordinate(cell.coordinate)
            }
            lookup[cell.coordinate] = cell
        }

        for coordinate in GridCoordinate.allInRowMajorOrder where lookup[coordinate] == nil {
            throw DeliveryGridError.missingCoordinate(coordinate)
        }

        return lookup
    }
}
