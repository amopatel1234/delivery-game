//
//  RootNavigationView.swift
//  delivery-game
//

import SwiftUI

/// App shell: Main Menu → sequential jobs → results → progression / replay selection.
struct RootNavigationView: View {
    @State private var path = NavigationPath()
    @State private var progressionState = JobProgressionState.initial

    var body: some View {
        NavigationStack(path: $path) {
            MainMenuView {
                startNewSession()
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .planning(let jobID):
                    PlanningScreen(jobID: jobID) { input in
                        path.append(AppRoute.results(input))
                    }
                case .results(let input):
                    ResultsScreenView(input: input) {
                        handleResultsContinue(for: input)
                    }
                case .jobSelection(let availableJobs):
                    JobSelectionView(availableJobs: availableJobs) { jobID in
                        handleReplaySelection(jobID)
                    }
                }
            }
        }
        .tint(GridPalette.accent)
    }

    private func startNewSession() {
        let (state, destination) = OutcomeFlowCoordinator.startNewSession()
        progressionState = state
        navigate(to: destination)
    }

    private func handleResultsContinue(for input: ResultsScreenInput) {
        let completedJobID = input.recap.jobID
        switch OutcomeFlowCoordinator.continueFromResults(
            completedJobID: completedJobID,
            progression: progressionState
        ) {
        case .success(let transition):
            progressionState = transition.0
            navigate(to: transition.1)
        case .failure:
            path = NavigationPath()
        }
    }

    private func handleReplaySelection(_ jobID: SeededJobID) {
        switch OutcomeFlowCoordinator.beginReplay(jobID: jobID, progression: progressionState) {
        case .success(let transition):
            progressionState = transition.0
            navigate(to: transition.1)
        case .failure:
            break
        }
    }

    private func navigate(to destination: OutcomeFlowDestination) {
        switch destination {
        case .planning(let jobID):
            path = NavigationPath([AppRoute.planning(jobID)])
        case .replaySelection(let availableJobs):
            path = NavigationPath([AppRoute.jobSelection(availableJobs: availableJobs)])
        }
    }
}

#Preview {
    RootNavigationView()
}
