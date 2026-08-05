//
//  PlanningAnalyzerTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct PlanningAnalyzerTests {

    @Test func skipsDepotWhenTraversingRoute() throws {
        let grid = try makeUniformGrid(cardType: .clearRoad)
        let route = Route(coordinates: [.depot, GridCoordinate(row: 0, column: 1)])

        let segments = PlanningAnalyzer.enteredSegments(route: route, grid: grid)

        #expect(segments.count == 1)
        #expect(segments[0].coordinate == GridCoordinate(row: 0, column: 1))
        #expect(segments[0].cardType == .clearRoad)
    }

    @Test func depotOnlyRouteProducesZeroMetrics() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot],
            cardTypes: [:]
        )

        let result = PlanningAnalyzer.analyze(request)

        #expect(result.enteredSegments.isEmpty)
        #expect(result.estimatedArrivalMinutes == 0)
        #expect(result.delayProbabilityPermille == 0)
        #expect(result.damageProbabilityPermille == 0)
    }

    @Test func estimatesDeterministicTravelForClearRoad() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .clearRoad]
        )

        let result = PlanningAnalyzer.analyze(request)

        #expect(result.estimatedArrivalMinutes == 1)
    }

    @Test func includesGuaranteedDelaysButExcludesRandomDelays() throws {
        let request = try makeRequest(
            routeCoordinates: [
                .depot,
                GridCoordinate(row: 0, column: 1),
                GridCoordinate(row: 0, column: 2),
                GridCoordinate(row: 0, column: 3),
            ],
            cardTypes: [
                GridCoordinate(row: 0, column: 1): .lightTraffic,
                GridCoordinate(row: 0, column: 2): .heavyTraffic,
                GridCoordinate(row: 0, column: 3): .roadworks,
            ]
        )

        let result = PlanningAnalyzer.analyze(request)

        // Light Traffic: 1 + 1, Heavy Traffic: 1 only, Roadworks: 1 + 2
        #expect(result.estimatedArrivalMinutes == 6)
    }

    @Test func fastLaneContributesZeroTravelTime() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .fastLane]
        )

        let result = PlanningAnalyzer.analyze(request)

        #expect(result.estimatedArrivalMinutes == 0)
        #expect(result.delayProbabilityPermille == 0)
        #expect(result.damageProbabilityPermille == 0)
    }

    @Test func calculatesSingleCardDelayProbability() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .heavyTraffic]
        )

        let result = PlanningAnalyzer.analyze(request)

        #expect(result.delayProbabilityPermille == 500)
    }

    @Test func combinesDelayProbabilitiesAcrossCards() throws {
        let request = try makeRequest(
            routeCoordinates: [
                .depot,
                GridCoordinate(row: 0, column: 1),
                GridCoordinate(row: 0, column: 2),
            ],
            cardTypes: [
                GridCoordinate(row: 0, column: 1): .heavyTraffic,
                GridCoordinate(row: 0, column: 2): .heavyTraffic,
            ]
        )

        let result = PlanningAnalyzer.analyze(request)

        #expect(result.delayProbabilityPermille == 750)
    }

    @Test func calculatesHeavyTrafficDamageProbability() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .heavyTraffic]
        )

        let result = PlanningAnalyzer.analyze(request)

        #expect(result.damageProbabilityPermille == 75)
    }

    @Test func combinesDamageProbabilitiesAcrossCards() throws {
        let request = try makeRequest(
            routeCoordinates: [
                .depot,
                GridCoordinate(row: 0, column: 1),
                GridCoordinate(row: 0, column: 2),
            ],
            cardTypes: [
                GridCoordinate(row: 0, column: 1): .heavyTraffic,
                GridCoordinate(row: 0, column: 2): .heavyTraffic,
            ]
        )

        let result = PlanningAnalyzer.analyze(request)

        #expect(result.damageProbabilityPermille == 145)
    }

    @Test func routeChangesUpdateAnalysis() throws {
        let shortRequest = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .clearRoad]
        )
        let longRequest = try makeRequest(
            routeCoordinates: [
                .depot,
                GridCoordinate(row: 0, column: 1),
                GridCoordinate(row: 0, column: 2),
            ],
            cardTypes: [
                GridCoordinate(row: 0, column: 1): .clearRoad,
                GridCoordinate(row: 0, column: 2): .heavyTraffic,
            ]
        )

        let shortResult = PlanningAnalyzer.analyze(shortRequest)
        let longResult = PlanningAnalyzer.analyze(longRequest)

        #expect(shortResult.estimatedArrivalMinutes == 1)
        #expect(longResult.estimatedArrivalMinutes == 2)
        #expect(shortResult.delayProbabilityPermille == 0)
        #expect(longResult.delayProbabilityPermille == 500)
        #expect(shortResult.damageProbabilityPermille == 0)
        #expect(longResult.damageProbabilityPermille == 75)
    }

    @Test func analysisIsDeterministicForIdenticalInputs() throws {
        let request = try makeRequest(
            routeCoordinates: [
                .depot,
                GridCoordinate(row: 0, column: 1),
                GridCoordinate(row: 0, column: 2),
            ],
            cardTypes: [
                GridCoordinate(row: 0, column: 1): .lightTraffic,
                GridCoordinate(row: 0, column: 2): .heavyTraffic,
            ]
        )

        let first = PlanningAnalyzer.analyze(request)
        let second = PlanningAnalyzer.analyze(request)

        #expect(first == second)
    }

    @Test func exposesMaximumRewardEstimationInputs() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .lightTraffic],
            targetTimeMinutes: 10,
            deadlineMinutes: 16
        )

        let result = PlanningAnalyzer.analyze(request)

        #expect(result.maximumRewardEstimationInput.deterministicArrivalMinutes == 2)
        #expect(result.maximumRewardEstimationInput.targetTimeMinutes == 10)
        #expect(result.maximumRewardEstimationInput.deadlineMinutes == 16)
        #expect(result.maximumRewardEstimationInput.economy == .mvp)
    }

    @Test func requestInitializesFromSeededJob() throws {
        let job = try SeededJobCatalogue.loadDefault()
        var builder = RouteBuilder()
        _ = builder.select(GridCoordinate(row: 0, column: 1))

        let request = try PlanningAnalysisRequest(route: builder.route, job: job)
        let result = PlanningAnalyzer.analyze(request)

        #expect(result.maximumRewardEstimationInput.targetTimeMinutes == job.targetTimeMinutes)
        #expect(result.maximumRewardEstimationInput.deadlineMinutes == job.deadlineMinutes)
        #expect(result.maximumRewardEstimationInput.economy == job.economy)
        #expect(result.enteredSegments.count == 1)
    }

    private func makeUniformGrid(cardType: CardType) throws -> DeliveryGrid {
        let cells = GridCoordinate.allInRowMajorOrder.map {
            GridCell(coordinate: $0, cardType: cardType)
        }
        return try DeliveryGrid(cells: cells)
    }

    private func makeRequest(
        routeCoordinates: [GridCoordinate],
        cardTypes: [GridCoordinate: CardType],
        targetTimeMinutes: Int = 10,
        deadlineMinutes: Int = 16,
        economy: EconomyConfiguration = .mvp
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
            targetTimeMinutes: targetTimeMinutes,
            deadlineMinutes: deadlineMinutes,
            economy: economy
        )
    }
}

struct IndependentProbabilityTests {

    @Test func returnsZeroForNoEvents() {
        #expect(IndependentProbability.combinedPermille([]) == 0)
    }

    @Test func returnsSingleEventProbabilityUnchanged() {
        #expect(IndependentProbability.combinedPermille([500]) == 500)
        #expect(IndependentProbability.combinedPermille([1000]) == 1000)
    }

    @Test func combinesIndependentEventsUsingCanonicalFormula() {
        #expect(IndependentProbability.combinedPermille([500, 500]) == 750)
        #expect(IndependentProbability.combinedPermille([1000, 500]) == 1000)
        #expect(IndependentProbability.combinedPermille([75, 75]) == 145)
    }

    @Test func manyZeroProbabilityEventsDoNotOverflowAndStayZero() {
        let zeros = Array(repeating: 0, count: 25)
        #expect(IndependentProbability.combinedPermille(zeros) == 0)
    }

    @Test func longRouteOfClearRoadSurvivalFactorsDoesNotOverflow() {
        // Regression: previous product form multiplied 1000^n and trapped on device.
        let clearRoadDelays = Array(repeating: 0, count: 8)
        #expect(IndependentProbability.combinedPermille(clearRoadDelays) == 0)

        let manyHeavyTrafficDamage = Array(repeating: 75, count: 12)
        let combined = IndependentProbability.combinedPermille(manyHeavyTrafficDamage)
        #expect(combined > 75)
        #expect(combined < 1000)
    }

    @Test func clampsOutOfRangeInputs() {
        #expect(IndependentProbability.combinedPermille([-10]) == 0)
        #expect(IndependentProbability.combinedPermille([1500]) == 1000)
    }
}
