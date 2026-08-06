//
//  JobProgressionCoordinatorTests.swift
//  delivery-gameTests
//

import Testing
@testable import delivery_game

struct JobProgressionCoordinatorTests {

    private let order = SeededJobCatalogue.sequentialOrder

    @Test func freshSessionBeginsAtJobOne() {
        let (state, step) = JobProgressionCoordinator.initialStep()

        #expect(state.completedSequentialJobs.isEmpty)
        #expect(state.isReplayUnlocked == false)
        #expect(state.mode == .sequential(nextJobIndex: 0))
        #expect(step == .beginSequentialJob(order[0]))
        #expect(JobProgressionCoordinator.activeJobID(for: state) == order[0])
    }

    @Test func jobsProgressSequentiallyFromOneThroughFive() {
        var state = JobProgressionState.initial

        for index in order.indices {
            #expect(JobProgressionCoordinator.activeJobID(for: state) == order[index])

            let result = JobProgressionCoordinator.completeJob(order[index], state: state)
            guard case .success(let transition) = result else {
                Issue.record("Expected completion for \(order[index])")
                return
            }
            let (nextState, step) = transition
            state = nextState

            #expect(nextState.completedSequentialJobs == Array(order.prefix(index + 1)))

            if index + 1 < order.count {
                #expect(step == .beginSequentialJob(order[index + 1]))
                #expect(nextState.mode == .sequential(nextJobIndex: index + 1))
                #expect(nextState.isReplayUnlocked == false)
            }
        }
    }

    @Test func completingJobFiveUnlocksReplaySelection() {
        var state = JobProgressionState.initial
        var lastStep: JobProgressionStep?
        for jobID in order {
            guard case .success(let transition) = JobProgressionCoordinator.completeJob(jobID, state: state) else {
                Issue.record("Expected completion for \(jobID)")
                return
            }
            state = transition.0
            lastStep = transition.1
        }

        #expect(state.isReplayUnlocked)
        #expect(state.mode == .replaySelection)
        #expect(state.completedSequentialJobs == order)
        #expect(JobProgressionCoordinator.activeJobID(for: state) == nil)

        guard case .showReplaySelection(let available) = lastStep else {
            Issue.record("Expected replay selection after Job 5")
            return
        }
        #expect(available == order)
    }

    @Test func replaySelectionAllowsAnyAuthoredJob() {
        let unlocked = unlockedReplayState()

        for jobID in order {
            guard case .success(let transition) = JobProgressionCoordinator.selectReplayJob(
                jobID,
                state: unlocked
            ) else {
                Issue.record("Expected replay selection for \(jobID)")
                continue
            }
            let (nextState, step) = transition
            #expect(nextState.mode == .replaying(jobID))
            #expect(step == .beginReplayJob(jobID))
            #expect(JobProgressionCoordinator.activeJobID(for: nextState) == jobID)
        }
    }

    @Test func replayLockedBeforeJobFiveCompletes() {
        var state = JobProgressionState.initial
        for jobID in order.dropLast() {
            guard case .success(let transition) = JobProgressionCoordinator.completeJob(jobID, state: state) else {
                Issue.record("Expected completion for \(jobID)")
                return
            }
            state = transition.0
        }

        #expect(state.isReplayUnlocked == false)

        let rejection = JobProgressionCoordinator.selectReplayJob(.closeDecision, state: state)
        guard case .failure(.replayLocked) = rejection else {
            Issue.record("Expected replay to remain locked before Job 5")
            return
        }
    }

    @Test func completingReplayJobReturnsToSelection() {
        let unlocked = unlockedReplayState()
        guard case .success(let startReplay) = JobProgressionCoordinator.selectReplayJob(
            .fastLaneTemptation,
            state: unlocked
        ) else {
            Issue.record("Expected replay start")
            return
        }

        guard case .success(let afterReplay) = JobProgressionCoordinator.completeJob(
            .fastLaneTemptation,
            state: startReplay.0
        ) else {
            Issue.record("Expected replay completion")
            return
        }

        #expect(afterReplay.0.mode == .replaySelection)
        #expect(afterReplay.0.isReplayUnlocked)
        guard case .showReplaySelection(let available) = afterReplay.1 else {
            Issue.record("Expected replay selection after replay run")
            return
        }
        #expect(available == order)
    }

    @Test func rejectsUnexpectedCompletedJobDuringSequence() {
        let state = JobProgressionState.initial
        let result = JobProgressionCoordinator.completeJob(.predictableDetour, state: state)
        guard case .failure(.unexpectedCompletedJob) = result else {
            Issue.record("Expected unexpected job rejection while on Job 1")
            return
        }
    }

    @Test func rejectsReplaySelectionWhileSequentialRunIsActive() {
        let state = JobProgressionState.initial
        let result = JobProgressionCoordinator.selectReplayJob(.directButRisky, state: state)
        guard case .failure(.replayLocked) = result else {
            Issue.record("Expected replay locked during sequential play")
            return
        }
    }

    @Test func loadJobSupportsSequentialAndReplaySteps() throws {
        for jobID in order {
            let sequential = try JobProgressionCoordinator.loadJob(for: .beginSequentialJob(jobID))
            let replay = try JobProgressionCoordinator.loadJob(for: .beginReplayJob(jobID))
            #expect(sequential == replay)
            #expect(sequential.id == jobID)
        }
    }

    @Test func beginningAJobRequiresRunReset() {
        #expect(JobProgressionCoordinator.requiresRunReset(for: .beginSequentialJob(.directButRisky)))
        #expect(JobProgressionCoordinator.requiresRunReset(for: .beginReplayJob(.closeDecision)))
        #expect(
            JobProgressionCoordinator.requiresRunReset(
                for: .showReplaySelection(availableJobs: order)
            ) == false
        )
    }

    @Test func onlyAuthoredJobsAreAvailable() {
        #expect(order == SeededJobID.allCases)
        #expect(order.count == 5)
        #expect(Set(order).count == 5)
    }

    private func unlockedReplayState() -> JobProgressionState {
        var state = JobProgressionState.initial
        for jobID in order {
            guard case .success(let transition) = JobProgressionCoordinator.completeJob(jobID, state: state) else {
                Issue.record("Expected completion for \(jobID)")
                break
            }
            state = transition.0
        }
        return state
    }
}
