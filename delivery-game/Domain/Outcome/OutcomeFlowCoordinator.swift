//
//  OutcomeFlowCoordinator.swift
//  delivery-game
//

import Foundation

/// Navigation destination after an outcome / progression transition.
nonisolated enum OutcomeFlowDestination: Equatable, Sendable {
    case planning(SeededJobID)
    case replaySelection(availableJobs: [SeededJobID])
}

/// Integrates results hand-off with job progression for the MVP gameplay loop.
nonisolated enum OutcomeFlowCoordinator {
    /// Starts a fresh session at Job 1.
    static func startNewSession() -> (JobProgressionState, OutcomeFlowDestination) {
        let (state, step) = JobProgressionCoordinator.initialStep()
        return (state, destination(for: step))
    }

    /// Advances progression after the player continues from the results screen.
    static func continueFromResults(
        completedJobID: SeededJobID,
        progression: JobProgressionState
    ) -> Result<(JobProgressionState, OutcomeFlowDestination), JobProgressionRejection> {
        JobProgressionCoordinator.completeJob(completedJobID, state: progression)
            .map { state, step in (state, destination(for: step)) }
    }

    /// Begins a replay run from the job-selection screen.
    static func beginReplay(
        jobID: SeededJobID,
        progression: JobProgressionState
    ) -> Result<(JobProgressionState, OutcomeFlowDestination), JobProgressionRejection> {
        JobProgressionCoordinator.selectReplayJob(jobID, state: progression)
            .map { state, step in (state, destination(for: step)) }
    }

    private static func destination(for step: JobProgressionStep) -> OutcomeFlowDestination {
        switch step {
        case .beginSequentialJob(let jobID), .beginReplayJob(let jobID):
            return .planning(jobID)
        case .showReplaySelection(let availableJobs):
            return .replaySelection(availableJobs: availableJobs)
        }
    }
}
