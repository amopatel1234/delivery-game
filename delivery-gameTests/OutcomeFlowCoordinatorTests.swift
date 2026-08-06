//
//  OutcomeFlowCoordinatorTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct OutcomeFlowCoordinatorTests {

    private let order = SeededJobCatalogue.sequentialOrder

    @Test func newSessionStartsAtJobOnePlanning() {
        let (state, destination) = OutcomeFlowCoordinator.startNewSession()

        #expect(state == .initial)
        #expect(destination == .planning(order[0]))
        #expect(JobProgressionCoordinator.activeJobID(for: state) == order[0])
    }

    @Test func sequentialResultsContinueAdvancesThroughAllJobs() {
        var progression = JobProgressionState.initial

        for index in order.indices {
            let activeJob = JobProgressionCoordinator.activeJobID(for: progression)
            #expect(activeJob == order[index])

            guard case .success(let transition) = OutcomeFlowCoordinator.continueFromResults(
                completedJobID: order[index],
                progression: progression
            ) else {
                Issue.record("Expected continue transition for \(order[index])")
                return
            }

            progression = transition.0
            let destination = transition.1

            if index + 1 < order.count {
                #expect(destination == .planning(order[index + 1]))
                #expect(progression.mode == .sequential(nextJobIndex: index + 1))
            } else {
                #expect(destination == .replaySelection(availableJobs: order))
                #expect(progression.mode == .replaySelection)
                #expect(progression.isReplayUnlocked)
            }
        }
    }

    @Test func replaySelectionBeginsChosenJob() {
        var progression = progressionAfterSequentialCompletion()

        for jobID in order {
            guard case .success(let transition) = OutcomeFlowCoordinator.beginReplay(
                jobID: jobID,
                progression: progression
            ) else {
                Issue.record("Expected replay begin for \(jobID)")
                continue
            }

            #expect(transition.1 == .planning(jobID))
            #expect(transition.0.mode == .replaying(jobID))

            guard case .success(let afterRun) = OutcomeFlowCoordinator.continueFromResults(
                completedJobID: jobID,
                progression: transition.0
            ) else {
                Issue.record("Expected replay completion for \(jobID)")
                continue
            }

            #expect(afterRun.1 == .replaySelection(availableJobs: order))
            #expect(afterRun.0.mode == .replaySelection)
            progression = afterRun.0
        }
    }

    @Test func replayCannotBeginBeforeSequentialCompletion() {
        let result = OutcomeFlowCoordinator.beginReplay(
            jobID: .closeDecision,
            progression: .initial
        )
        guard case .failure(.replayLocked) = result else {
            Issue.record("Expected replay to remain locked before Job 5")
            return
        }
    }

    @Test func fullGameplayLoopIsDeterministic() {
        let firstSession = simulateSequentialSession()
        let secondSession = simulateSequentialSession()
        #expect(firstSession == secondSession)
    }

    @Test func resultsInputCarriesCompletedJobForProgression() throws {
        let input = try makeExecutionInput(
            targetTimeMinutes: 10,
            deadlineMinutes: 16,
            cardTypes: Array(repeating: .clearRoad, count: 8)
        )
        let prepared = ExecutionRunPreparer.prepare(input: input, seed: 1)
        let screenInput = ResultsScreenInput.from(result: prepared.result)

        #expect(screenInput.recap.jobID == input.jobID)
    }

    @Test func jobSelectionAccessibilityIdentifiersAreStable() {
        #expect(GridAccessibilityID.jobSelection == "job-selection")
        #expect(
            GridAccessibilityID.jobSelectionOption(.directButRisky)
                == "job-selection-direct_but_risky"
        )
    }

    private func simulateSequentialSession() -> [OutcomeFlowDestination] {
        var progression = JobProgressionState.initial
        var destinations: [OutcomeFlowDestination] = []

        let (startState, startDestination) = OutcomeFlowCoordinator.startNewSession()
        progression = startState
        destinations.append(startDestination)

        for jobID in order {
            guard case .success(let transition) = OutcomeFlowCoordinator.continueFromResults(
                completedJobID: jobID,
                progression: progression
            ) else {
                break
            }
            progression = transition.0
            destinations.append(transition.1)
        }

        return destinations
    }

    private func progressionAfterSequentialCompletion() -> JobProgressionState {
        var progression = JobProgressionState.initial
        for jobID in order {
            guard case .success(let transition) = OutcomeFlowCoordinator.continueFromResults(
                completedJobID: jobID,
                progression: progression
            ) else {
                break
            }
            progression = transition.0
        }
        return progression
    }

    private func makeExecutionInput(
        targetTimeMinutes: Int,
        deadlineMinutes: Int,
        cardTypes: [CardType]
    ) throws -> ExecutionInput {
        let job = try SeededJobCatalogue.loadDefault()
        let path: [GridCoordinate] = [
            GridCoordinate(row: 0, column: 1),
            GridCoordinate(row: 0, column: 2),
            GridCoordinate(row: 0, column: 3),
            GridCoordinate(row: 0, column: 4),
            GridCoordinate(row: 1, column: 4),
            GridCoordinate(row: 2, column: 4),
            GridCoordinate(row: 3, column: 4),
            .destination,
        ]
        precondition(cardTypes.count == path.count)

        var builder = RouteBuilder()
        for coordinate in path {
            let result = builder.select(coordinate)
            guard case .accepted = result else {
                Issue.record("Expected path step \(coordinate) to be accepted")
                break
            }
        }

        return ExecutionInput(
            jobID: job.id,
            jobDisplayName: job.displayName,
            targetTimeMinutes: targetTimeMinutes,
            deadlineMinutes: deadlineMinutes,
            economy: job.economy,
            route: builder.route,
            enteredCardTypes: cardTypes
        )
    }
}
