//
//  DamageRiskClassifierTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct DamageRiskClassifierTests {

    @Test func classifiesBelowTenPercentAsLow() {
        #expect(DamageRiskClassifier.classify(damageProbabilityPermille: 0) == .low)
        #expect(DamageRiskClassifier.classify(damageProbabilityPermille: 99) == .low)
    }

    @Test func classifiesTenToBelowTwentyFivePercentAsMedium() {
        #expect(DamageRiskClassifier.classify(damageProbabilityPermille: 100) == .medium)
        #expect(DamageRiskClassifier.classify(damageProbabilityPermille: 249) == .medium)
    }

    @Test func classifiesTwentyFivePercentOrAboveAsHigh() {
        #expect(DamageRiskClassifier.classify(damageProbabilityPermille: 250) == .high)
        #expect(DamageRiskClassifier.classify(damageProbabilityPermille: 1000) == .high)
    }

    @Test func usesSevenPointFivePercentOverallDamagePerHeavyTrafficCard() throws {
        let segments = [
            RouteSegment(
                coordinate: GridCoordinate(row: 0, column: 1),
                cardType: .heavyTraffic,
                rule: CardRules.heavyTraffic
            )
        ]

        #expect(CardRules.heavyTraffic.overallDamageProbabilityPermille == 75)
        #expect(DamageRiskClassifier.classify(segments: segments) == .low)
    }

    @Test func usesCanonicalIndependentProbabilityForMultipleCards() throws {
        let twoCards = [
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
        // 1 - (1 - 0.075)^2 ≈ 14.5% → Medium
        #expect(DamageRiskClassifier.classify(segments: twoCards) == .medium)

        let fourCards = (1 ... 4).map { column in
            RouteSegment(
                coordinate: GridCoordinate(row: 0, column: column),
                cardType: .heavyTraffic,
                rule: CardRules.heavyTraffic
            )
        }
        // 1 - (1 - 0.075)^4 ≈ 26.8% → High
        #expect(DamageRiskClassifier.classify(segments: fourCards) == .high)
    }

    @Test func clearRouteHasLowDamageRisk() throws {
        let request = try makeRequest(
            routeCoordinates: [.depot, GridCoordinate(row: 0, column: 1)],
            cardTypes: [GridCoordinate(row: 0, column: 1): .clearRoad]
        )
        let analysis = PlanningAnalyzer.analyze(request)

        #expect(DamageRiskClassifier.classify(analysis: analysis) == .low)
    }

    @Test func nonHeavyTrafficCardsContributeNoDamageRisk() throws {
        let request = try makeRequest(
            routeCoordinates: [
                .depot,
                GridCoordinate(row: 0, column: 1),
                GridCoordinate(row: 0, column: 2),
                GridCoordinate(row: 0, column: 3),
            ],
            cardTypes: [
                GridCoordinate(row: 0, column: 1): .lightTraffic,
                GridCoordinate(row: 0, column: 2): .roadworks,
                GridCoordinate(row: 0, column: 3): .fastLane,
            ]
        )
        let analysis = PlanningAnalyzer.analyze(request)

        #expect(analysis.damageProbabilityPermille == 0)
        #expect(DamageRiskClassifier.classify(analysis: analysis) == .low)
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
                GridCoordinate(row: 0, column: 2): .heavyTraffic,
            ]
        )
        let analysis = PlanningAnalyzer.analyze(request)

        let first = DamageRiskClassifier.classify(analysis: analysis)
        let second = DamageRiskClassifier.classify(analysis: analysis)

        #expect(first == second)
        #expect(analysis.damageProbabilityPermille == 145)
        #expect(first == .medium)
    }

    @Test func customThresholdsCanBeInjected() {
        let thresholds = DamageRiskThresholds(
            mediumMinimumPermille: 50,
            highMinimumPermille: 150
        )

        #expect(
            DamageRiskClassifier.classify(
                damageProbabilityPermille: 49,
                thresholds: thresholds
            ) == .low
        )
        #expect(
            DamageRiskClassifier.classify(
                damageProbabilityPermille: 50,
                thresholds: thresholds
            ) == .medium
        )
        #expect(
            DamageRiskClassifier.classify(
                damageProbabilityPermille: 150,
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
