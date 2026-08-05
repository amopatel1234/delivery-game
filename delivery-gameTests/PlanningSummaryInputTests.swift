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

    @Test func analysisMetricsStartUnavailableWithoutRouteAnalysis() throws {
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

    @Test func distinguishesTargetTimeAndDeadlineAsSeparateRows() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let metrics = PlanningSummaryInput.from(job: job).metrics
        let target = metrics.first { $0.id == "target_time" }
        let deadline = metrics.first { $0.id == "deadline" }

        #expect(target?.title == "Target time")
        #expect(deadline?.title == "Deadline")
        #expect(target?.value == "\(job.targetTimeMinutes) min")
        #expect(deadline?.value == "\(job.deadlineMinutes) min")
        #expect(target?.value != deadline?.value || job.targetTimeMinutes != job.deadlineMinutes)
    }

    @Test func liveSummaryFillsEveryCanonicalMetric() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let grid = try DeliveryGrid(board: job.board)
        let summary = PlanningSummaryInput.from(
            job: job,
            route: RouteBuilder().route,
            grid: grid
        )

        #expect(summary.estimatedArrivalMinutes == 0)
        #expect(summary.delayExposure == DelayExposureLevel.low.displayName)
        #expect(summary.damageRisk == DamageRiskLevel.low.displayName)
        #expect(summary.maximumReward != nil)
        #expect(summary.metrics.allSatisfy { $0.isAvailable })
    }

    @Test func estimatedArrivalIsLabeledAsApproximate() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let grid = try DeliveryGrid(board: job.board)
        var builder = RouteBuilder()
        _ = builder.select(GridCoordinate(row: 0, column: 1))

        let summary = PlanningSummaryInput.from(
            job: job,
            route: builder.route,
            grid: grid
        )
        let arrival = summary.metrics.first { $0.id == "estimated_arrival" }

        #expect(arrival?.value.hasPrefix("~") == true)
        #expect(arrival?.value.hasSuffix(" min") == true)
    }

    @Test func summaryUpdatesImmediatelyWhenRouteChanges() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let cells = GridCoordinate.allInRowMajorOrder.map { coordinate in
            let cardType: CardType =
                coordinate == GridCoordinate(row: 0, column: 1) ? .heavyTraffic : .clearRoad
            return GridCell(coordinate: coordinate, cardType: cardType)
        }
        let grid = try DeliveryGrid(cells: cells)
        var builder = RouteBuilder()

        let depotOnly = PlanningSummaryInput.from(
            job: job,
            route: builder.route,
            grid: grid
        )

        _ = builder.select(GridCoordinate(row: 0, column: 1))
        let afterStep = PlanningSummaryInput.from(
            job: job,
            route: builder.route,
            grid: grid
        )

        #expect(depotOnly.estimatedArrivalMinutes == 0)
        #expect(depotOnly.delayExposure == "Low")
        #expect(depotOnly.damageRisk == "Low")

        #expect(afterStep.estimatedArrivalMinutes == 1)
        #expect(afterStep.delayExposure == "High")
        #expect(afterStep.damageRisk == "Low")
        #expect(afterStep.maximumReward != depotOnly.maximumReward)

        let again = PlanningSummaryInput.from(
            job: job,
            route: builder.route,
            grid: grid
        )
        #expect(again == afterStep)

        _ = builder.undo()
        let afterUndo = PlanningSummaryInput.from(
            job: job,
            route: builder.route,
            grid: grid
        )
        #expect(afterUndo == depotOnly)
    }

    @Test func liveSummaryMatchesDomainClassifiersAndEstimator() throws {
        let job = try SeededJobCatalogue.loadDefault()
        var builder = RouteBuilder()
        _ = builder.select(GridCoordinate(row: 0, column: 1))
        _ = builder.select(GridCoordinate(row: 0, column: 2))

        let request = try PlanningAnalysisRequest(route: builder.route, job: job)
        let analysis = PlanningAnalyzer.analyze(request)
        let summary = PlanningSummaryInput.from(job: job, analysis: analysis)

        #expect(summary.estimatedArrivalMinutes == analysis.estimatedArrivalMinutes)
        #expect(
            summary.delayExposure
                == DelayExposureClassifier.classify(analysis: analysis).displayName
        )
        #expect(
            summary.damageRisk
                == DamageRiskClassifier.classify(analysis: analysis).displayName
        )
        #expect(
            summary.maximumReward
                == MaximumRewardEstimator.estimate(analysis: analysis)
        )
    }

    @Test func accessibilityLabelsDescribeEachPlanningValue() throws {
        let job = try SeededJobCatalogue.loadDefault()
        let grid = try DeliveryGrid(board: job.board)
        let summary = PlanningSummaryInput.from(
            job: job,
            route: RouteBuilder().route,
            grid: grid
        )

        for metric in summary.metrics {
            #expect(metric.accessibilityLabel.contains(metric.title))
            #expect(metric.accessibilityLabel.contains(metric.value))
        }
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
