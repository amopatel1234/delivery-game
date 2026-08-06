//
//  SeededJobCatalogueTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct SeededJobCatalogueTests {

    @Test func definesAllFiveAuthoredJobs() {
        let ids = SeededJobCatalogue.definitions.map(\.id)
        #expect(ids == SeededJobID.allCases)
        #expect(Set(ids).count == 5)
        #expect(SeededJobCatalogue.sequentialOrder == ids)

        let names = SeededJobCatalogue.definitions.map(\.displayName)
        #expect(names == [
            "Direct but Risky",
            "Predictable Detour",
            "Fast Lane Temptation",
            "Deadline Pressure",
            "Close Decision",
        ])
    }

    @Test func everyJobHasStableSeedAndTiming() {
        for definition in SeededJobCatalogue.definitions {
            #expect(!definition.id.rawValue.isEmpty)
            #expect(!definition.displayName.isEmpty)
            #expect(definition.deadlineMinutes > definition.targetTimeMinutes)
            #expect(definition.targetTimeMinutes > 0)
        }

        let seeds = Set(SeededJobCatalogue.definitions.map(\.seed))
        #expect(seeds.count == 5)
    }

    @Test func allJobsShareTheSameEconomyConfiguration() throws {
        let jobs = try SeededJobID.allCases.map { try SeededJobCatalogue.load(id: $0) }
        #expect(jobs.allSatisfy { $0.economy == EconomyConfiguration.mvp })
        #expect(Set(jobs.map(\.economy)).count == 1)
    }

    @Test func loadDefaultReturnsJobOne() throws {
        let job = try SeededJobCatalogue.loadDefault()
        #expect(job.id == .directButRisky)
        #expect(job.displayName == "Direct but Risky")
    }

    @Test func loadingAnyJobDirectlyIsSupported() throws {
        for id in SeededJobID.allCases {
            let job = try SeededJobCatalogue.load(id: id)
            #expect(job.id == id)
            #expect(job.board.seed == job.definition.seed)
            #expect(job.board.generatorVersion == BoardGenerator.version)
            try BoardValidator.validate(job.board)
        }
    }

    @Test func repeatedLoadsProduceIdenticalJobData() throws {
        for id in SeededJobID.allCases {
            let first = try SeededJobCatalogue.load(id: id)
            let second = try SeededJobCatalogue.load(id: id)
            #expect(first == second)
        }
    }

    @Test func acceptedSeededBoardsMatchStructuralRegressionSnapshots() throws {
        let expectedCardsByJob: [SeededJobID: [CardType]] = [
            .directButRisky: [
                .clearRoad, .roadworks, .lightTraffic, .lightTraffic, .clearRoad,
                .lightTraffic, .roadworks, .heavyTraffic, .heavyTraffic, .clearRoad,
                .fastLane, .lightTraffic, .lightTraffic, .lightTraffic, .clearRoad,
                .clearRoad, .clearRoad, .clearRoad, .heavyTraffic, .heavyTraffic,
                .heavyTraffic, .lightTraffic, .clearRoad, .clearRoad, .clearRoad,
            ],
            .predictableDetour: [
                .clearRoad, .lightTraffic, .clearRoad, .roadworks, .lightTraffic,
                .clearRoad, .clearRoad, .clearRoad, .clearRoad, .heavyTraffic,
                .lightTraffic, .clearRoad, .clearRoad, .lightTraffic, .heavyTraffic,
                .clearRoad, .heavyTraffic, .heavyTraffic, .lightTraffic, .heavyTraffic,
                .fastLane, .lightTraffic, .roadworks, .lightTraffic, .clearRoad,
            ],
            .fastLaneTemptation: [
                .clearRoad, .roadworks, .heavyTraffic, .clearRoad, .lightTraffic,
                .clearRoad, .lightTraffic, .clearRoad, .fastLane, .clearRoad,
                .roadworks, .clearRoad, .lightTraffic, .lightTraffic, .heavyTraffic,
                .lightTraffic, .heavyTraffic, .clearRoad, .clearRoad, .heavyTraffic,
                .clearRoad, .lightTraffic, .heavyTraffic, .lightTraffic, .clearRoad,
            ],
            .deadlinePressure: [
                .clearRoad, .clearRoad, .clearRoad, .heavyTraffic, .clearRoad,
                .clearRoad, .clearRoad, .lightTraffic, .lightTraffic, .heavyTraffic,
                .lightTraffic, .heavyTraffic, .fastLane, .heavyTraffic, .roadworks,
                .clearRoad, .heavyTraffic, .lightTraffic, .roadworks, .clearRoad,
                .clearRoad, .lightTraffic, .lightTraffic, .lightTraffic, .clearRoad,
            ],
            .closeDecision: [
                .clearRoad, .clearRoad, .lightTraffic, .clearRoad, .clearRoad,
                .lightTraffic, .clearRoad, .fastLane, .roadworks, .clearRoad,
                .heavyTraffic, .lightTraffic, .lightTraffic, .lightTraffic, .clearRoad,
                .lightTraffic, .heavyTraffic, .roadworks, .clearRoad, .heavyTraffic,
                .heavyTraffic, .lightTraffic, .clearRoad, .heavyTraffic, .clearRoad,
            ],
        ]

        for id in SeededJobID.allCases {
            let job = try SeededJobCatalogue.load(id: id)
            let actualCards = job.board.cells
                .sorted { $0.coordinate < $1.coordinate }
                .map(\.cardType)

            #expect(actualCards == expectedCardsByJob[id])
            #expect(job.board.cardType(at: .depot) == .clearRoad)
            #expect(job.board.cardType(at: .destination) == .clearRoad)
            try BoardValidator.validate(job.board, recipe: .mvp)
        }
    }
}
