//
//  PlanningSummaryInputTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct PlanningSummaryInputTests {

    @Test func fromJobExposesTargetTimeAndDeadline() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let summary = PlanningSummaryInput.from(job: job)

        #expect(summary.targetTimeMinutes == job.targetTimeMinutes)
        #expect(summary.deadlineMinutes == job.deadlineMinutes)
    }

    @Test func analysisMetricsStartUnavailable() throws {
        let summary = PlanningSummaryInput.from(job: try SeededJobCatalogue.loadDefault())

        #expect(summary.estimatedArrivalMinutes == nil)
        #expect(summary.delayExposure == nil)
        #expect(summary.damageRisk == nil)
        #expect(summary.maximumReward == nil)
    }

    @Test func metricsSurfaceIncludesAllCanonicalRows() throws {
        let metrics = PlanningSummaryInput.from(job: try SeededJobCatalogue.loadDefault()).metrics
        let ids = Set(metrics.map(\.id))

        #expect(ids == [
            "estimated_arrival",
            "target_time",
            "deadline",
            "delay_exposure",
            "damage_risk",
            "maximum_reward",
        ])
        #expect(metrics.filter(\.isAvailable).map(\.id) == ["target_time", "deadline"])
    }

    @Test func confirmationEnabledOnlyForCompleteRoute() {
        var builder = RouteBuilder()
        var validation = RouteValidator.validate(route: builder.route)
        #expect(!validation.canConfirm)

        _ = builder.select(GridCoordinate(row: 0, column: 1))
        validation = RouteValidator.validate(route: builder.route)
        #expect(!validation.canConfirm)

        let completePath: [GridCoordinate] = [
            GridCoordinate(row: 0, column: 1),
            GridCoordinate(row: 0, column: 2),
            GridCoordinate(row: 0, column: 3),
            GridCoordinate(row: 0, column: 4),
            GridCoordinate(row: 1, column: 4),
            GridCoordinate(row: 2, column: 4),
            GridCoordinate(row: 3, column: 4),
            .destination,
        ]
        for coordinate in completePath {
            _ = builder.select(coordinate)
        }

        validation = RouteValidator.validate(route: builder.route)
        #expect(validation.canConfirm)

        _ = builder.undo()
        validation = RouteValidator.validate(route: builder.route)
        #expect(!validation.canConfirm)
    }
}
