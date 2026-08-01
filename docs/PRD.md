# Delivery Game — Product Requirements Document

## 1. Product Summary

Delivery Game is a single-player iOS route-planning game. The player studies a fully revealed 5×5 grid, chooses a route from a fixed depot to a fixed destination, compares potential reward against delay and damage risk, confirms the route, and watches the journey resolve.

The MVP is a vertical slice whose primary purpose is to answer one question:

> Is planning a delivery route for the best reward intrinsically fun?

The internal project name is **Delivery Game**. The player-facing release name remains undecided.

## 2. MVP Goals

- Validate that route planning creates meaningful choices.
- Validate that players understand and weigh deterministic time, delay exposure, and damage risk.
- Validate that reward maximisation is more interesting than simply choosing the shortest or safest route.
- Validate the core loop using five reproducible seeded jobs.
- Ship a playable TestFlight build for external feedback.

## 3. Non-Goals

The MVP does not include:

- Multiple vehicles or vehicle selection.
- Cargo capacity or job restrictions.
- Vehicle upgrades or persistent condition.
- Repairs, breakdowns, or maintenance.
- Business management, drivers, contracts, or company progression.
- Reputation, long-term progression, or saved run state.
- Procedural city generation.
- Multiplayer, leaderboards, or a cross-platform version.
- An intervention or dodge mechanic during execution.

## 4. Target Platform

- Platform: iOS.
- Language: Swift.
- UI: SwiftUI.
- Minimum OS: iOS 26.
- Visual assets: SF Symbols and simple native shapes are acceptable for the MVP.

## 5. Core Player Loop

1. Load one of the five seeded jobs.
2. Inspect the fully revealed grid and job information.
3. Build a route from the depot to the destination.
4. Compare estimated arrival, target time, deadline, risk, and maximum reward.
5. Confirm the route.
6. Watch each entered card resolve in sequence.
7. Review the completed or failed result and itemised payout.
8. Continue to the next seeded job; after Job 5, select any seeded job to replay.

## 6. Player Experience Requirements

### 6.1 Grid

- The board is a fixed 5×5 grid.
- The depot is fixed at the top-left.
- The destination is fixed at the bottom-right.
- All cards and their behaviour are visible before planning.
- Movement is orthogonal only.

### 6.2 Route Planning

- The depot is selected automatically.
- A card can be added only when it is orthogonally adjacent to the current route endpoint.
- Routed cards cannot be reused; loops are not allowed.
- Undo removes the most recently added card and can be repeated back to the depot.
- The player may create a temporary dead end; Undo is the recovery mechanism.
- Confirm Route is enabled only when the destination is the route endpoint.

### 6.3 Planning Information

Before confirming, the player can see:

- Estimated arrival time, clearly labelled as approximate.
- Target time.
- Final deadline.
- Delay exposure: Low, Medium, or High.
- Damage risk: Low, Medium, or High.
- Maximum achievable reward for the selected route.

The game must not calculate or recommend an optimal route.

### 6.4 Execution

- The route locks after confirmation.
- Cards resolve in route order.
- Time and damage update as each card resolves.
- The player cannot alter the route during execution.

### 6.5 Outcome

The result screen shows:

- Completed or failed state.
- Actual time, target time, and deadline.
- Damage-event count.
- Base reward.
- Early bonus, lateness penalty, and damage penalty where applicable.
- Final currency earned.

The MVP does not use star ratings.

## 7. MVP Content

### 7.1 Cards

The board always contains 25 cards:

| Card | Count |
|---|---:|
| Clear Road | 10 |
| Light Traffic | 7 |
| Heavy Traffic | 5 |
| Roadworks | 2 |
| Fast Lane | 1 |

The depot and destination are two of the ten Clear Road cards. Exact behaviour is owned by `Gameplay-Rules.md`.

### 7.2 Seeded Jobs

The first TestFlight build includes five fixed jobs:

1. Direct but Risky.
2. Predictable Detour.
3. Fast Lane Temptation.
4. Deadline Pressure.
5. Close Decision.

All five initially share one economy configuration. Only seed, target time, and final deadline vary. Exact seeds and timing values remain balancing work until the deterministic generator exists.

Random standalone jobs are a gated MVP follow-up. They do not block the first external TestFlight build.

## 8. Economy

Initial shared values:

| Value | Initial setting |
|---|---:|
| Base reward | 100 coins |
| Early bonus | 5 coins per minute early |
| Late penalty | 20 coins per minute late |
| Damage penalty | 20 coins per event |

These are balancing values and may change through playtesting without changing the product scope.

## 9. Technical Constraints

- Random behaviour must be driven by an injected deterministic random-number source.
- A seeded job must reproduce the same grid and authored job values.
- Card effects belong in a rules or resolution layer, not in card views.
- Grid positions use a coordinate-based model with constant-time orthogonal adjacency checks.
- No persistent gameplay progression or saved run state is required; lightweight preferences such as onboarding completion may persist.

## 10. Validation and Success Criteria

The MVP succeeds when external playtesting provides evidence that:

- Players understand how to create, undo, and confirm a route.
- Players recognise meaningful alternatives rather than one obvious route.
- Delay exposure and damage risk affect route choice.
- Target time, deadline, and maximum reward are understandable.
- Players can explain why they chose a route.
- Players want to retry a job or compare another route.

Implementation alone is not sufficient; each core mechanic must be exercised through the seeded jobs.

## 11. Documentation Ownership

- `PRD.md`: product goals, scope, and player experience.
- `Gameplay-Rules.md`: exact mechanics and calculations.
- `Decision-Log.md`: accepted decisions and rationale.
- `Roadmap.md`: delivery order, epic scope, and post-MVP direction.
- `epics/`: implementation-focused acceptance criteria.
