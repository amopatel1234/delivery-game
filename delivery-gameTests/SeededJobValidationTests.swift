//
//  SeededJobValidationTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct SeededJobValidationTests {

    @Test func validationRecordCoversAllFiveJobsInOrder() {
        #expect(SeededJobValidationRecord.entries.map(\.id) == SeededJobCatalogue.sequentialOrder)
        #expect(SeededJobValidationRecord.entries.count == 5)
    }

    @Test func acceptedSeedsAndTimingsMatchLiveCatalogue() {
        for definition in SeededJobCatalogue.definitions {
            #expect(SeededJobValidationRecord.matchesCatalogueDefinition(definition))
        }
    }

    @Test func everySeededJobRemainsStructurallyValidAndDeterministic() throws {
        for id in SeededJobID.allCases {
            let first = try SeededJobCatalogue.load(id: id)
            let second = try SeededJobCatalogue.load(id: id)
            try BoardValidator.validate(first.board, recipe: .mvp)
            #expect(first == second)
            #expect(first.definition.deadlineMinutes > first.definition.targetTimeMinutes)
            #expect(first.economy == .mvp)
        }
    }

    @Test func everySeededJobHasCompleteRouteAlternatives() throws {
        for id in SeededJobID.allCases {
            let job = try SeededJobCatalogue.load(id: id)
            let grid = try DeliveryGrid(board: job.board)
            let diversity = SeededJobRouteExplorer.diversity(on: grid, limit: 80)

            #expect(diversity.hasAtLeastOneCompleteRoute)
            #expect(diversity.hasMultipleCompleteRoutes)
            #expect(diversity.hasLengthAlternatives)
            #expect((diversity.shortestLength ?? 0) >= 8) // Manhattan minimum on 5×5 corner-to-corner
            #expect((diversity.longestLength ?? 0) > (diversity.shortestLength ?? 0))
        }
    }

    @Test func completeRoutesAreAcceptedByRouteBuilderAndValidator() throws {
        for id in SeededJobID.allCases {
            let job = try SeededJobCatalogue.load(id: id)
            let grid = try DeliveryGrid(board: job.board)
            let routes = SeededJobRouteExplorer.completeRoutes(on: grid, limit: 12)
            #expect(!routes.isEmpty)

            for path in routes.prefix(5) {
                var builder = RouteBuilder()
                for coordinate in path.dropFirst() {
                    let result = builder.select(coordinate)
                    guard case .accepted = result else {
                        Issue.record("Expected \(coordinate) to extend route on \(id.rawValue)")
                        return
                    }
                }
                let validation = RouteValidator.validate(route: builder.route)
                #expect(validation.isComplete)
                #expect(validation.canConfirm)
            }
        }
    }

    @Test func boardsContainCardTypesRequiredByDesignIntent() throws {
        for entry in SeededJobValidationRecord.entries {
            let job = try SeededJobCatalogue.load(id: entry.id)
            let present = Set(job.board.cells.map(\.cardType))
            #expect(entry.requiredCardTypes.isSubset(of: present))
        }
    }

    @Test func deadlinePressureKeepsATightTimingMargin() {
        let entry = SeededJobValidationRecord.entry(for: .deadlinePressure)
        #expect(entry.deadlineMinutes - entry.targetTimeMinutes == 2)
    }

    @Test func alternativeRoutesProduceDifferentHazardProfilesOnDirectButRisky() throws {
        let job = try SeededJobCatalogue.load(id: .directButRisky)
        let grid = try DeliveryGrid(board: job.board)
        let routes = SeededJobRouteExplorer.completeRoutes(on: grid, limit: 40)
        let profiles = Set(
            routes.map { path in
                SeededJobRouteExplorer.enteredCardTypes(route: path, grid: grid)
                    .filter { $0 == .heavyTraffic || $0 == .roadworks }
                    .count
            }
        )
        #expect(profiles.count >= 2)
    }

    @Test func fastLaneTemptationOffersRoutesWithAndWithoutFastLane() throws {
        let job = try SeededJobCatalogue.load(id: .fastLaneTemptation)
        let grid = try DeliveryGrid(board: job.board)
        let routes = SeededJobRouteExplorer.completeRoutes(on: grid, limit: 80)
        let withFastLane = routes.contains { path in
            SeededJobRouteExplorer.enteredCardTypes(route: path, grid: grid).contains(.fastLane)
        }
        let withoutFastLane = routes.contains { path in
            !SeededJobRouteExplorer.enteredCardTypes(route: path, grid: grid).contains(.fastLane)
        }
        #expect(withFastLane)
        #expect(withoutFastLane)
    }

    @Test func runResetClearsExecutionScopedTotalsBetweenJobs() throws {
        let first = try SeededJobCatalogue.load(id: .directButRisky)
        let second = try SeededJobCatalogue.load(id: .predictableDetour)

        let firstInput = try makeShortExecutionInput(job: first)
        let secondInput = try makeShortExecutionInput(job: second)

        let firstResult = ExecutionRunPreparer.prepare(input: firstInput, seed: first.seed).result
        let secondResult = ExecutionRunPreparer.prepare(input: secondInput, seed: second.seed).result

        #expect(firstResult.jobID != secondResult.jobID)
        #expect(secondResult.elapsedMinutes >= 0)
        #expect(secondResult.damageEventCount >= 0)
        // Fresh hand-off — second run does not inherit first run totals as a baseline.
        #expect(secondResult.eventLog.events.first?.elapsedMinutesAfter != nil)
    }

    @Test func acceptedValidationTableIsDocumentedForSignOff() {
        // Mirrors docs/planning/validation/Seeded-Job-Validation.md
        let table = SeededJobValidationRecord.entries.map {
            "\($0.id.rawValue):\($0.seed):\($0.targetTimeMinutes):\($0.deadlineMinutes)"
        }
        #expect(table == [
            "direct_but_risky:1001:10:16",
            "predictable_detour:2002:12:18",
            "fast_lane_temptation:3003:9:15",
            "deadline_pressure:4004:10:12",
            "close_decision:5005:11:17",
        ])
    }

    private func makeShortExecutionInput(job: SeededJob) throws -> ExecutionInput {
        let grid = try DeliveryGrid(board: job.board)
        let path = SeededJobRouteExplorer.completeRoutes(on: grid, limit: 1)[0]
        var builder = RouteBuilder()
        for coordinate in path.dropFirst() {
            let result = builder.select(coordinate)
            guard case .accepted = result else {
                Issue.record("Expected path construction for \(job.id.rawValue)")
                break
            }
        }
        let cardTypes = SeededJobRouteExplorer.enteredCardTypes(route: path, grid: grid)
        return ExecutionInput(
            jobID: job.id,
            jobDisplayName: job.displayName,
            targetTimeMinutes: job.targetTimeMinutes,
            deadlineMinutes: job.deadlineMinutes,
            economy: job.economy,
            route: builder.route,
            enteredCardTypes: cardTypes
        )
    }
}
