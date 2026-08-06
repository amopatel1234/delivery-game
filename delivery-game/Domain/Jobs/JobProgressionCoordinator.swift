//
//  JobProgressionCoordinator.swift
//  delivery-game
//

import Foundation

/// How the session is advancing through authored jobs.
nonisolated enum JobProgressionMode: Equatable, Sendable {
    /// Playing jobs 1…5 in catalogue order. Index is the next job to start.
    case sequential(nextJobIndex: Int)
    /// Job 5 is complete; player may choose any authored job to replay.
    case replaySelection
    /// A replay job is active until the run finishes.
    case replaying(SeededJobID)
}

/// Run-scoped progression through the five seeded MVP jobs.
///
/// Not persisted across app launches. E4-S06 wires this into navigation.
nonisolated struct JobProgressionState: Equatable, Sendable {
    let mode: JobProgressionMode
    /// Jobs completed in canonical sequential order during this session.
    let completedSequentialJobs: [SeededJobID]

    static let initial = JobProgressionState(
        mode: .sequential(nextJobIndex: 0),
        completedSequentialJobs: []
    )

    var isReplayUnlocked: Bool {
        completedSequentialJobs.count >= SeededJobCatalogue.sequentialOrder.count
    }
}

/// What the presentation layer should do after a progression transition.
nonisolated enum JobProgressionStep: Equatable, Sendable {
    case beginSequentialJob(SeededJobID)
    case showReplaySelection(availableJobs: [SeededJobID])
    case beginReplayJob(SeededJobID)
}

/// Why a progression action was rejected.
nonisolated enum JobProgressionRejection: Error, Equatable, Sendable {
    case replayLocked
    case notInReplaySelection
    case unknownJob
    case unexpectedCompletedJob
    case noActiveJob
}

/// Pure coordinator for sequential job progression and replay unlock.
nonisolated enum JobProgressionCoordinator {
    /// Fresh MVP session begins at Job 1.
    static func initialStep() -> (JobProgressionState, JobProgressionStep) {
        let firstJob = SeededJobCatalogue.sequentialOrder[0]
        return (.initial, .beginSequentialJob(firstJob))
    }

    /// Job ID for the active sequential or replay run, if any.
    static func activeJobID(for state: JobProgressionState) -> SeededJobID? {
        switch state.mode {
        case .sequential(let index):
            guard index < SeededJobCatalogue.sequentialOrder.count else { return nil }
            return SeededJobCatalogue.sequentialOrder[index]
        case .replaying(let jobID):
            return jobID
        case .replaySelection:
            return nil
        }
    }

    /// Records a finished job and returns the next progression step.
    static func completeJob(
        _ completedJobID: SeededJobID,
        state: JobProgressionState
    ) -> Result<(JobProgressionState, JobProgressionStep), JobProgressionRejection> {
        guard isAuthoredJob(completedJobID) else {
            return .failure(.unknownJob)
        }

        switch state.mode {
        case .sequential(let index):
            guard index < SeededJobCatalogue.sequentialOrder.count else {
                return .failure(.noActiveJob)
            }
            guard SeededJobCatalogue.sequentialOrder[index] == completedJobID else {
                return .failure(.unexpectedCompletedJob)
            }

            let completed = state.completedSequentialJobs + [completedJobID]
            let nextIndex = index + 1
            if nextIndex >= SeededJobCatalogue.sequentialOrder.count {
                let nextState = JobProgressionState(
                    mode: .replaySelection,
                    completedSequentialJobs: completed
                )
                return .success((
                    nextState,
                    .showReplaySelection(availableJobs: SeededJobCatalogue.sequentialOrder)
                ))
            }

            let nextJob = SeededJobCatalogue.sequentialOrder[nextIndex]
            let nextState = JobProgressionState(
                mode: .sequential(nextJobIndex: nextIndex),
                completedSequentialJobs: completed
            )
            return .success((nextState, .beginSequentialJob(nextJob)))

        case .replaying(let activeJobID):
            guard activeJobID == completedJobID else {
                return .failure(.unexpectedCompletedJob)
            }
            let nextState = JobProgressionState(
                mode: .replaySelection,
                completedSequentialJobs: state.completedSequentialJobs
            )
            return .success((
                nextState,
                .showReplaySelection(availableJobs: SeededJobCatalogue.sequentialOrder)
            ))

        case .replaySelection:
            return .failure(.noActiveJob)
        }
    }

    /// Chooses a replay job after Job 5 has unlocked selection.
    static func selectReplayJob(
        _ jobID: SeededJobID,
        state: JobProgressionState
    ) -> Result<(JobProgressionState, JobProgressionStep), JobProgressionRejection> {
        guard state.isReplayUnlocked else {
            return .failure(.replayLocked)
        }
        guard case .replaySelection = state.mode else {
            return .failure(.notInReplaySelection)
        }
        guard isAuthoredJob(jobID) else {
            return .failure(.unknownJob)
        }

        let nextState = JobProgressionState(
            mode: .replaying(jobID),
            completedSequentialJobs: state.completedSequentialJobs
        )
        return .success((nextState, .beginReplayJob(jobID)))
    }

    /// Loads the authored job for a begin-job step.
    static func loadJob(
        for step: JobProgressionStep,
        economy: EconomyConfiguration = .mvp,
        recipe: DeckRecipe = .mvp
    ) throws -> SeededJob {
        switch step {
        case .beginSequentialJob(let jobID), .beginReplayJob(let jobID):
            return try SeededJobCatalogue.load(id: jobID, economy: economy, recipe: recipe)
        case .showReplaySelection:
            preconditionFailure("Replay selection does not load a job directly")
        }
    }

    /// Starting or replaying a job always requires clearing run-scoped state.
    static func requiresRunReset(for step: JobProgressionStep) -> Bool {
        switch step {
        case .beginSequentialJob, .beginReplayJob:
            return true
        case .showReplaySelection:
            return false
        }
    }

    private static func isAuthoredJob(_ jobID: SeededJobID) -> Bool {
        SeededJobCatalogue.sequentialOrder.contains(jobID)
    }
}
