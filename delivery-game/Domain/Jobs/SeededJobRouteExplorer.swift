//
//  SeededJobRouteExplorer.swift
//  delivery-game
//

import Foundation

/// Summary of complete depot→destination routes found on a job board.
nonisolated struct SeededJobRouteDiversity: Equatable, Sendable {
    let sampleLimit: Int
    let completeRouteCount: Int
    let distinctLengths: Set<Int>
    let shortestLength: Int?
    let longestLength: Int?

    var hasAtLeastOneCompleteRoute: Bool { completeRouteCount > 0 }
    var hasMultipleCompleteRoutes: Bool { completeRouteCount >= 2 }
    var hasLengthAlternatives: Bool { distinctLengths.count >= 2 }
}

/// Enumerates simple orthogonal routes for seeded-job balance validation.
nonisolated enum SeededJobRouteExplorer {
    /// Finds up to `limit` simple paths from depot to destination.
    static func completeRoutes(
        on grid: DeliveryGrid,
        limit: Int = 64
    ) -> [[GridCoordinate]] {
        precondition(limit > 0)
        var found: [[GridCoordinate]] = []
        var path: [GridCoordinate] = [.depot]
        var visited: Set<GridCoordinate> = [.depot]

        func neighbours(of coordinate: GridCoordinate) -> [GridCoordinate] {
            [
                GridCoordinate(row: coordinate.row - 1, column: coordinate.column),
                GridCoordinate(row: coordinate.row + 1, column: coordinate.column),
                GridCoordinate(row: coordinate.row, column: coordinate.column - 1),
                GridCoordinate(row: coordinate.row, column: coordinate.column + 1),
            ]
            .filter { grid.containsCoordinate($0) && !visited.contains($0) }
        }

        func search() {
            guard found.count < limit else { return }
            let endpoint = path[path.count - 1]
            if endpoint == .destination {
                found.append(path)
                return
            }
            for next in neighbours(of: endpoint) {
                path.append(next)
                visited.insert(next)
                search()
                path.removeLast()
                visited.remove(next)
                if found.count >= limit { return }
            }
        }

        search()
        return found
    }

    static func diversity(
        on grid: DeliveryGrid,
        limit: Int = 64
    ) -> SeededJobRouteDiversity {
        let routes = completeRoutes(on: grid, limit: limit)
        // Length counts entered cards after depot (matches player step wording).
        let lengths = Set(routes.map { max($0.count - 1, 0) })
        return SeededJobRouteDiversity(
            sampleLimit: limit,
            completeRouteCount: routes.count,
            distinctLengths: lengths,
            shortestLength: lengths.min(),
            longestLength: lengths.max()
        )
    }

    /// Card types encountered after leaving the depot on a complete route.
    static func enteredCardTypes(
        route: [GridCoordinate],
        grid: DeliveryGrid
    ) -> [CardType] {
        precondition(route.first == .depot)
        precondition(route.last == .destination)
        return route.dropFirst().map { grid.cell(at: $0).cardType }
    }
}
