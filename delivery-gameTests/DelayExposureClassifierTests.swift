//
//  DelayExposureClassifierTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct DelayExposureClassifierTests {

    @Test func classifiesBelowTwentyFivePercentAsLow() {
        #expect(DelayExposureClassifier.classify(delayProbabilityPermille: 0) == .low)
        #expect(DelayExposureClassifier.classify(delayProbabilityPermille: 249) == .low)
    }

    @Test func classifiesTwentyFiveToBelowFiftyPercentAsMedium() {
        #expect(DelayExposureClassifier.classify(delayProbabilityPermille: 250) == .medium)
        #expect(DelayExposureClassifier.classify(delayProbabilityPermille: 499) == .medium)
    }

    @Test func classifiesFiftyPercentOrAboveAsHigh() {
        #expect(DelayExposureClassifier.classify(delayProbabilityPermille: 500) == .high)
        #expect(DelayExposureClassifier.classify(delayProbabilityPermille: 1000) == .high)
    }

    @Test func usesCanonicalIndependentProbabilityForMultipleCards() throws {
        let segments = [
            RouteSegment(
                coordinate: GridCoordinate(row: 0, column: 1),
                cardType: .heavyTraffic,
                rule: CardRules.heavyTraffic
            ),
            RouteSegment(
                coordinate: GridCoordinate(row: 0, column: 2),
                cardType: .heavyTraffic,
                rule: CardRules.heavyTraffic
            ),
        ]

        #expect(DelayExposureClassifier.classify(segments: segments) == .high)
    }

    @Test func clearRouteHasLowDelayExposure() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .clearRoad]
        )
        let analysis = PlanningAnalyzer.analyze(request)

        #expect(DelayExposureClassifier.classify(analysis: analysis) == .low)
    }

    @Test func singleHeavyTrafficCardIsHighExposure() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .heavyTraffic]
        )
        let analysis = PlanningAnalyzer.analyze(request)

        #expect(analysis.delayProbabilityPermille == 500)
        #expect(DelayExposureClassifier.classify(analysis: analysis) == .high)
    }

    @Test func guaranteedDelayCardIsHighExposure() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .lightTraffic]
        )
        let analysis = PlanningAnalyzer.analyze(request)

        #expect(analysis.delayProbabilityPermille == 1000)
        #expect(DelayExposureClassifier.classify(analysis: analysis) == .high)
    }

    @Test func classificationIsDeterministicForIdenticalInputs() throws {
        let request = try makeRequest(
            routeCoordinates: [
                .depot,
                GridCoordinate(row: 0, column: 1),
                GridCoordinate(row: 0, column: 2),
            ],
            cardTypes: [
                GridCoordinate(row: 0, column: 1): .heavyTraffic,
                GridCoordinate(row: 0, column: 2): .clearRoad,
            ]
        )
        let analysis = PlanningAnalyzer.analyze(request)

        let first = DelayExposureClassifier.classify(analysis: analysis)
        let second = DelayExposureClassifier.classify(analysis: analysis)

        #expect(first == second)
        #expect(first == .high)
    }

    @Test func customThresholdsCanBeInjected() {
        let thresholds = DelayExposureThresholds(
            mediumMinimumPermille: 100,
            highMinimumPermille: 300
        )

        #expect(
            DelayExposureClassifier.classify(
                delayProbabilityPermille: 99,
                thresholds: thresholds
            ) == .low
        )
        #expect(
            DelayExposureClassifier.classify(
                delayProbabilityPermille: 100,
                thresholds: thresholds
            ) == .medium
        )
        #expect(
            DelayExposureClassifier.classify(
                delayProbabilityPermille: 300,
                thresholds: thresholds
            ) == .high
        )
    }

    private func makeRequest(
        routeCoordinates: [GridCoordinate],
        cardTypes: [GridCoordinate: CardType]
    ) throws -> PlanningAnalysisRequest {
        var cells = GridCoordinate.allInRowMajorOrder.map {
            GridCell(coordinate: $0, cardType: .clearRoad)
        }

        for (coordinate, cardType) in cardTypes {
            if let index = cells.firstIndex(where: { $0.coordinate == coordinate }) {
                cells[index] = GridCell(coordinate: coordinate, cardType: cardType)
            }
        }

        let grid = try DeliveryGrid(cells: cells)
        return PlanningAnalysisRequest(
            route: Route(coordinates: routeCoordinates),
            grid: grid,
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            economy: .mvp
        )
    }
}
