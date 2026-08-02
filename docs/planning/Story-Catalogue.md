# Story Catalogue

**Version:** 1.0  
**Status:** Draft  
**Owner:** Product

## Related Documents

- [Product Requirements Document](../PRD.md)
- [Gameplay Rules](../Gameplay-Rules.md)
- [Decision Log](../Decision-Log.md)
- [Roadmap](../Roadmap.md)
- [Implementation Epics](../epics/)

## Purpose

This document decomposes the approved implementation epics into implementation-sized stories for the Delivery Game MVP. It is the canonical implementation planning document from which GitHub Issues, Project items and implementation workstreams are derived.

## Scope and Precedence

This catalogue defines stories, dependencies, acceptance criteria, parallel work opportunities and recommended implementation order. It does not redefine gameplay behaviour.

If a conflict exists, precedence is:

1. Product Requirements Document
2. Gameplay Rules
3. Decision Log
4. Implementation Epics
5. Story Catalogue
6. GitHub Issues
7. Code

## Story Principles

- **One capability:** each story delivers one coherent outcome.
- **Independently testable:** acceptance criteria and relevant tests are part of completion.
- **Vertical slices:** prefer useful capabilities over fragmented layer-only tasks.
- **Domain before UI:** SwiftUI consumes behaviour rather than owning it.
- **Small but valuable:** split oversized stories and combine valueless micro-tasks.
- **Stable interfaces:** minimise downstream rewrites.
- **Minimal dependencies:** circular dependencies are prohibited.
- **Canonical references:** stories reference but do not redefine approved documents.

## Story Format

Each story contains: Goal, Deliverable, Scope, Out of Scope, Dependencies, Acceptance Criteria and References.

Story IDs use `E<epic>-S<story>`, for example `E5-S01`. IDs remain stable after publication.

Story lifecycle: `Draft → Ready → In Progress → In Review → Done`.

---

# Epic 5 – Deck and Seeded Job Generation

## E5-S01 — Card Rule Definitions

### Goal
Create the canonical domain representation of every MVP card.

### Deliverable
Card rule definitions and `CardType` domain model.

### Scope
- Define Clear Road, Light Traffic, Heavy Traffic, Roadworks and Fast Lane.
- Define immutable timing and hazard metadata.
- Provide stable identifiers.
- Centralise inputs shared by planning and execution.

### Out of Scope
- Board generation.
- Route planning.
- Hazard execution.
- SwiftUI rendering.

### Dependencies
- None.

### Acceptance Criteria
- Defines all five canonical card types.
- Gives every type a stable identifier.
- Defines Fast Lane with zero time, no delay and no damage.
- Defines Heavy Traffic delay and conditional damage probabilities.
- Keeps definitions immutable and presentation-independent.
- Includes unit tests for every definition.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S02 — Shared Economy Configuration

### Goal
Create one configurable economy definition shared by every MVP job.

### Deliverable
Shared economy configuration model.

### Scope
- Base reward.
- Early bonus rate.
- Lateness penalty rate.
- Damage penalty rate.
- Reward clamping policy.

### Out of Scope
- Settlement.
- Results UI.
- Currency spending.

### Dependencies
- None.

### Acceptance Criteria
- Stores all economy values centrally.
- Prevents duplicated reward constants.
- Can be injected into planning and settlement.
- Supports the minimum-zero reward rule.
- Includes default and custom configuration tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S03 — Seeded Random Number Generator

### Goal
Provide deterministic randomness for generation and execution.

### Deliverable
Injectable seeded random-number abstraction with production and test implementations.

### Scope
- Random-number protocol or equivalent abstraction.
- Seeded production implementation.
- Deterministic test implementation.
- Inclusive percentage rolls.

### Out of Scope
- Board generation.
- Hazard rules.
- Seed-selection UI.

### Dependencies
- None.

### Acceptance Criteria
- Produces the same sequence for the same seed.
- Produces different sequences for suitably different seeds.
- Allows tests to provide exact values.
- Supports inclusive 1–100 rolls.
- Prevents implicit global randomness in gameplay code.
- Includes deterministic sequence and boundary tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S04 — Deck Recipe

### Goal
Create and validate the canonical 25-card deck recipe.

### Deliverable
Deck recipe and validation service.

### Scope
- Card counts.
- Deck construction.
- Composition validation.
- Clear Road reservation for depot and destination.

### Out of Scope
- Shuffling.
- Grid placement.
- Job timing.

### Dependencies
- E5-S01.

### Acceptance Criteria
- Creates exactly 25 cards.
- Creates 10 Clear Road, 7 Light Traffic, 5 Heavy Traffic, 2 Roadworks and 1 Fast Lane.
- Reserves two Clear Road cards for depot and destination.
- Rejects invalid totals or counts.
- Includes exact-composition and invalid-recipe tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S05 — Board Generator

### Goal
Generate an immutable deterministic 5×5 board from a deck recipe and seed.

### Deliverable
Seeded board generator.

### Scope
- Deterministic shuffle or placement.
- Fixed depot and destination positions.
- Grid population.
- Structural validation.

### Out of Scope
- Route planning.
- Hazard execution.
- Seed-balancing tools.

### Dependencies
- E5-S03.
- E5-S04.

### Acceptance Criteria
- Produces the same ordered board for the same seed and generator version.
- Places depot top-left and destination bottom-right.
- Keeps both fixed positions as Clear Road.
- Produces one card per coordinate.
- Returns immutable board data.
- Includes deterministic output and validation tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 1](../epics/Epic-1-The-Grid.md)
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S06 — Seeded Job Catalogue

### Goal
Create the five authored MVP jobs and a loader returning complete immutable job data.

### Deliverable
Seeded job catalogue and loader.

### Scope
- Stable IDs and names.
- Seeds.
- Target Time and Deadline.
- Shared economy reference.
- Direct development and test loading.

### Out of Scope
- Random jobs.
- Sequential progression.
- Campaign persistence.

### Dependencies
- E5-S02.
- E5-S05.

### Acceptance Criteria
- Defines all five named MVP jobs.
- Gives each job a stable ID, seed, Target Time and Deadline.
- Makes every job share one economy configuration.
- Loads any job directly for development and tests.
- Produces identical job data for repeated loads.
- Includes structural regression tests for all accepted boards.

### References
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)
- [Epic 6](../epics/Epic-6-Polish-and-TestFlight.md)

---

# Epic 1 – The Grid

## E1-S01 — Grid Domain Model

### Goal
Create the immutable domain model for the delivery grid and coordinates.

### Deliverable
Coordinate, position, grid-cell and grid models.

### Scope
- Fixed 5×5 dimensions.
- Coordinate representation and lookup.
- Depot and destination representation.
- Board validation.

### Out of Scope
- Rendering.
- Route construction.
- Planning analysis.

### Dependencies
- E5-S05.

### Acceptance Criteria
- Represents 25 unique coordinates.
- Maps every coordinate to one card.
- Identifies depot and destination.
- Rejects duplicate, missing or out-of-bounds coordinates.
- Remains immutable.
- Includes validation and lookup tests.

### References
- [Epic 1](../epics/Epic-1-The-Grid.md)
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)

## E1-S02 — Grid Presentation

### Goal
Display a generated board using SwiftUI.

### Deliverable
Responsive grid presentation.

### Scope
- 5×5 layout.
- Card presentation.
- Depot and destination distinction.
- Supported iPhone sizing.
- Basic accessibility identifiers.

### Out of Scope
- Route selection.
- Final visual polish.
- Planning calculations.

### Dependencies
- E1-S01.

### Acceptance Criteria
- Displays the entire board without scrolling on supported iPhones.
- Displays every card in its correct coordinate.
- Distinguishes depot and destination without colour alone.
- Adapts to supported widths.
- Exposes stable accessibility identifiers.
- Includes UI tests for structure and fixed positions.

### References
- [Epic 1](../epics/Epic-1-The-Grid.md)

## E1-S03 — Route Construction

### Goal
Allow the player to build an ordered route from the depot using valid orthogonal moves.

### Deliverable
Route builder integrated with the grid.

### Scope
- Automatic depot selection.
- Endpoint tracking.
- Orthogonal adjacency.
- Duplicate prevention.
- Ordered route state.

### Out of Scope
- Undo.
- Confirmation.
- Planning calculations.

### Dependencies
- E1-S02.

### Acceptance Criteria
- Starts every route at the depot.
- Adds only orthogonally adjacent cards.
- Rejects diagonal, non-adjacent and revisited cards.
- Preserves route order.
- Keeps validation logic outside SwiftUI.
- Includes adjacency and invalid-move tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 1](../epics/Epic-1-The-Grid.md)

## E1-S04 — Route Editing

### Goal
Allow repeated undo before confirmation.

### Deliverable
Route undo capability.

### Scope
- Remove the latest card.
- Update endpoint and selected state.
- Repeat undo to the depot.

### Out of Scope
- Arbitrary middle-route editing.
- Confirmation.
- Execution.

### Dependencies
- E1-S03.

### Acceptance Criteria
- Removes only the latest selected card.
- Allows undo until only the depot remains.
- Never removes the depot.
- Updates endpoint and UI state immediately.
- Preserves route validity.
- Includes unit and UI undo tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 1](../epics/Epic-1-The-Grid.md)

## E1-S05 — Route Validation

### Goal
Determine whether a route is complete and eligible for confirmation.

### Deliverable
Route-completion validator.

### Scope
- Destination endpoint detection.
- Complete and incomplete states.
- Confirmation eligibility.

### Out of Scope
- Confirmation transition.
- Timing and reward analysis.
- Execution.

### Dependencies
- E1-S03.

### Acceptance Criteria
- Marks a route complete only when destination is the endpoint.
- Marks all other routes incomplete.
- Updates after selection or undo.
- Produces a presentation-independent result.
- Includes depot-only, partial and destination-ending tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 1](../epics/Epic-1-The-Grid.md)

## E1-S06 — Planning Screen Foundation

### Goal
Integrate grid, route building, undo, confirmation state and planning-summary surface.

### Deliverable
Functional planning screen foundation.

### Scope
- Grid integration.
- Route-state presentation.
- Undo control.
- Confirmation-control state.
- Planning-summary input surface.

### Out of Scope
- Planning calculations.
- Confirmation transition.
- Final visual polish.

### Dependencies
- E1-S04.
- E1-S05.

### Acceptance Criteria
- Allows route building and editing from one screen.
- Shows selection state consistently.
- Enables confirmation only for a complete route.
- Provides a stable surface for planning metrics.
- Keeps domain logic outside views.
- Includes UI tests for construction, undo and enablement.

### References
- [Epic 1](../epics/Epic-1-The-Grid.md)
- [Epic 2](../epics/Epic-2-Route-Planning.md)

---

# Epic 2 – Route Planning

## E2-S01 — Planning Analysis Engine

### Goal
Analyse an immutable route and produce deterministic planning metrics without consuming randomness.

### Deliverable
Planning analysis service and result model.

### Scope
- Deterministic travel-time estimation.
- Route card aggregation.
- Timing, probability and reward inputs.

### Out of Scope
- SwiftUI presentation.
- Random resolution.
- Final settlement.

### Dependencies
- E1-S06.
- E5-S02.

### Acceptance Criteria
- Accepts immutable route and job configuration.
- Produces a presentation-independent result.
- Never consumes random numbers.
- Returns identical output for identical inputs.
- Keeps policies outside SwiftUI.
- Includes route-change and determinism tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 2](../epics/Epic-2-Route-Planning.md)

## E2-S02 — Planning Summary Presentation

### Goal
Present all route-analysis information while planning.

### Deliverable
Planning summary UI.

### Scope
- Estimated arrival.
- Target Time and Deadline.
- Delay exposure and damage risk.
- Maximum achievable reward.

### Out of Scope
- Calculations.
- Route recommendation.
- Execution.

### Dependencies
- E2-S03.
- E2-S04.
- E2-S05.

### Acceptance Criteria
- Displays every canonical planning metric.
- Updates immediately with route changes.
- Distinguishes Target Time and Deadline.
- Labels estimates clearly.
- Does not rank or recommend routes.
- Includes UI tests for live updates.

### References
- [Epic 2](../epics/Epic-2-Route-Planning.md)

## E2-S03 — Delay Exposure Classification

### Goal
Calculate and classify combined route-delay probability.

### Deliverable
Delay-exposure calculator and classifier.

### Scope
- Probability combination.
- Low, Medium and High classifications.
- Canonical thresholds.

### Out of Scope
- Damage risk.
- UI.
- Random delay resolution.

### Dependencies
- E2-S01.

### Acceptance Criteria
- Uses the canonical independent-probability formula.
- Classifies below 25% as Low.
- Classifies 25% to below 50% as Medium.
- Classifies 50% or above as High.
- Produces deterministic results.
- Includes boundary and multi-card tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 2](../epics/Epic-2-Route-Planning.md)

## E2-S04 — Damage Risk Classification

### Goal
Calculate and classify combined route-damage probability.

### Deliverable
Damage-risk calculator and classifier.

### Scope
- Heavy Traffic overall damage probability.
- Probability combination.
- Low, Medium and High classifications.

### Out of Scope
- Delay exposure.
- UI.
- Damage resolution.

### Dependencies
- E2-S01.

### Acceptance Criteria
- Uses 7.5% overall damage probability per Heavy Traffic card.
- Uses the canonical probability formula.
- Classifies below 10% as Low.
- Classifies 10% to below 25% as Medium.
- Classifies 25% or above as High.
- Includes boundary and multi-card tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 2](../epics/Epic-2-Route-Planning.md)

## E2-S05 — Maximum Reward Estimation

### Goal
Calculate maximum achievable reward for the planned route.

### Deliverable
Maximum reward estimator.

### Scope
- Deterministic arrival.
- Early bonus or lateness penalty.
- Deadline failure.
- Shared economy integration.

### Out of Scope
- Expected payout.
- Damage expectation.
- Final settlement.

### Dependencies
- E2-S01.
- E5-S02.

### Acceptance Criteria
- Uses shared economy configuration.
- Applies canonical timing boundaries.
- Excludes unresolved damage and random delay penalties.
- Returns zero when deterministic arrival is at or after Deadline.
- Matches settlement policy for equivalent inputs.
- Includes early, on-target, late and failure tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 2](../epics/Epic-2-Route-Planning.md)
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)

## E2-S06 — Route Confirmation

### Goal
Lock the analysed route and transition to execution with immutable input.

### Deliverable
Planning-to-execution transition and confirmed-route model.

### Scope
- Confirmation action.
- Immutable route snapshot.
- Planning-state finalisation.
- Execution hand-off.

### Out of Scope
- Execution.
- Outcome calculation.

### Dependencies
- E2-S02.

### Acceptance Criteria
- Confirms only complete routes.
- Creates an immutable snapshot.
- Prevents editing after confirmation.
- Starts execution with the confirmed route only.
- Prevents duplicate transitions.
- Includes transition and UI tests.

### References
- [Epic 2](../epics/Epic-2-Route-Planning.md)
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)

---

# Epic 3 – Execution and Hazard Resolution

## E3-S01 — Execution Engine

### Goal
Execute a confirmed route sequentially through the destination.

### Deliverable
Execution state machine and engine.

### Scope
- Idle, running and completed states.
- Immutable input.
- Sequential traversal.
- Current index and position.
- Single-run protection.

### Out of Scope
- Card-specific resolution.
- Settlement.
- Animation.

### Dependencies
- E2-S06.

### Acceptance Criteria
- Skips depot resolution.
- Resolves every subsequent position once and in order.
- Prevents concurrent or duplicate execution.
- Never mutates the confirmed route.
- Completes after destination resolution.
- Includes lifecycle tests.

### References
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)

## E3-S02 — Card Resolution Engine

### Goal
Resolve deterministic timing behaviour for every entered card.

### Deliverable
Card resolution service.

### Scope
- Clear Road, Light Traffic, Heavy Traffic base movement, Roadworks and Fast Lane.
- Elapsed-time accumulation.

### Out of Scope
- Probabilistic Heavy Traffic outcomes.
- Presentation.
- Settlement.

### Dependencies
- E3-S01.
- E5-S01.

### Acceptance Criteria
- Applies canonical base and fixed-delay rules.
- Applies zero time for Fast Lane.
- Never damages from non-Heavy-Traffic cards.
- Delegates Heavy Traffic probabilities.
- Resolves in route order.
- Includes tests for every card type.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)

## E3-S03 — Hazard Resolution

### Goal
Resolve Heavy Traffic delay and conditional damage with injected randomness.

### Deliverable
Hazard resolution service.

### Scope
- 50% delay roll.
- Conditional 15% damage roll.
- Roll recording and consumption order.

### Out of Scope
- Route traversal.
- Settlement.
- Presentation cadence.

### Dependencies
- E3-S02.
- E5-S03.

### Acceptance Criteria
- Uses injected RNG.
- Rolls delay before damage.
- Rolls damage only after a delay.
- Does not consume unnecessary damage rolls.
- Uses inclusive 1–100 thresholds.
- Includes threshold and consumption tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)

## E3-S04 — Execution Event History

### Goal
Record an authoritative event for every resolved card.

### Deliverable
Immutable execution event history.

### Scope
- Route index and position.
- Card type and movement time.
- Roll values.
- Delay and damage.
- Elapsed time and cumulative damage.

### Out of Scope
- Recap UI.
- Reward calculation.

### Dependencies
- E3-S03.

### Acceptance Criteria
- Records one event per entered card after depot.
- Preserves order.
- Records only consumed rolls.
- Stores cumulative totals.
- Becomes immutable on completion.
- Includes event-integrity tests.

### References
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)

## E3-S05 — Execution Presentation

### Goal
Present execution without influencing domain results.

### Deliverable
Execution presentation layer.

### Scope
- Current-card highlighting.
- Marker movement.
- Time and damage updates.
- Tunable visual cadence.

### Out of Scope
- Final polish.
- Audio and haptics.
- Outcome UI.

### Dependencies
- E3-S04.

### Acceptance Criteria
- Shows the current position accurately.
- Updates time and damage after each event.
- Locks planning controls.
- Keeps animation independent from domain execution.
- Includes progression and locking UI tests.

### References
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)

## E3-S06 — Route Recap

### Goal
Produce a complete summary of the executed journey.

### Deliverable
Execution recap model and basic presentation.

### Scope
- Per-card movement, delay and damage.
- Total time and damage.
- Long-route scrolling.

### Out of Scope
- Final reward.
- Outcome status.

### Dependencies
- E3-S04.

### Acceptance Criteria
- Includes every resolved card once.
- Separates movement, delay and damage.
- Matches event history and final totals.
- Remains available until the player proceeds.
- Includes model and UI tests.

### References
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)

## E3-S07 — Execution Completion

### Goal
Complete execution once and produce the immutable result needed by outcomes.

### Deliverable
Execution result and transition.

### Scope
- Final time and damage.
- Event history.
- Route and job identity.
- Outcome hand-off.

### Out of Scope
- Outcome evaluation.
- Settlement.
- Results UI.

### Dependencies
- E3-S05.
- E3-S06.

### Acceptance Criteria
- Produces an immutable result after destination resolution.
- Contains all data required by Epic 4.
- Prevents continued execution.
- Emits completion exactly once.
- Includes completion and duplicate-transition tests.

### References
- [Epic 3](../epics/Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)

---

# Epic 4 – Economy and Outcome

## E4-S01 — Outcome Evaluation

### Goal
Determine completed or failed status from execution time and job boundaries.

### Deliverable
Outcome evaluation service.

### Scope
- Early, exact-target, late-before-deadline and deadline-failure states.

### Out of Scope
- Reward calculation.
- Presentation.

### Dependencies
- E3-S07.

### Acceptance Criteria
- Completes before or at Target Time.
- Completes after Target Time but before Deadline.
- Fails at or after Deadline.
- Produces deterministic output.
- Includes every timing-boundary test.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)

## E4-S02 — Reward Settlement

### Goal
Calculate final payout from outcome, execution data and shared economy.

### Deliverable
Pure reward settlement service.

### Scope
- Base reward.
- Early bonus.
- Lateness and damage penalties.
- Failed-run zero payout.
- Minimum-zero clamping.

### Out of Scope
- UI.
- Spending.
- Progression.

### Dependencies
- E4-S01.
- E5-S02.

### Acceptance Criteria
- Uses shared economy configuration.
- Applies each component independently.
- Penalises each damage event once.
- Returns zero for failed runs.
- Never returns a negative reward.
- Consumes no randomness.
- Includes timing, damage and clamping tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)

## E4-S03 — Outcome Breakdown

### Goal
Explain the final outcome and payout with an immutable model.

### Deliverable
Outcome breakdown model.

### Scope
- Status, timing, base reward, bonuses, penalties and final reward.

### Out of Scope
- SwiftUI layout.
- Progression.

### Dependencies
- E4-S02.

### Acceptance Criteria
- Exposes every settlement component.
- Preserves zero-value components.
- Matches settlement exactly.
- Preserves details for failed runs.
- Includes mapping and consistency tests.

### References
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)

## E4-S04 — Results Screen

### Goal
Present outcome, payout breakdown and route recap.

### Deliverable
Functional results screen.

### Scope
- Outcome heading.
- Reward and timing.
- Damage count and itemised breakdown.
- Recap access and continue action.

### Out of Scope
- Final polish.
- Job-selection logic.

### Dependencies
- E4-S03.
- E3-S06.

### Acceptance Criteria
- Distinguishes completed and failed states.
- Displays settled reward exactly.
- Shows actual time, Target Time and Deadline.
- Shows itemised calculation and recap access.
- Includes completed and failed UI tests.

### References
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)

## E4-S05 — Job Progression

### Goal
Manage sequential progression and replay for the five seeded jobs.

### Deliverable
Job progression coordinator.

### Scope
- Fresh-session Job 1.
- Job 1–5 advancement.
- Replay selection after Job 5.
- Run-state reset.
- Test overrides.

### Out of Scope
- Random jobs.
- Campaign progression.
- Meta-economy.

### Dependencies
- E4-S04.
- E5-S06.

### Acceptance Criteria
- Starts at Job 1 unless test-overridden.
- Advances through Job 5.
- Unlocks replay selection after Job 5.
- Resets all run-scoped state.
- Never creates a random MVP job.
- Includes progression and reset tests.

### References
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)

## E4-S06 — Outcome Integration

### Goal
Integrate execution, outcome, settlement, results and progression into the functional MVP loop.

### Deliverable
End-to-end gameplay flow.

### Scope
- Execution-to-outcome transition.
- Settlement and results.
- Continue and replay hand-off.
- Phase state ownership.

### Out of Scope
- Onboarding.
- Final polish.
- TestFlight.

### Dependencies
- E4-S05.

### Acceptance Criteria
- Runs the complete flow from planning to next job or replay.
- Shows each outcome once.
- Preserves deterministic domain behaviour.
- Prevents stale state leaking between runs.
- Includes an end-to-end functional MVP UI test.

### References
- [Epic 4](../epics/Epic-4-Economy-and-Outcome.md)
- [Epic 6](../epics/Epic-6-Polish-and-TestFlight.md)

---

# Epic 6 – Polish, Validation and TestFlight

## E6-S01 — First-Time User Experience

### Goal
Guide a first-time player through the core loop without external explanation.

### Deliverable
Dismissible onboarding flow.

### Scope
- Objective, route building, undo, confirmation, timing, risk and reward explanation.
- Completion-state persistence and development reset.

### Out of Scope
- Tutorial levels.
- Gameplay changes.

### Dependencies
- E4-S06.

### Acceptance Criteria
- Enables a new player to complete the loop using in-app guidance.
- Explains canonical rules accurately.
- Can be skipped and does not repeat after completion.
- Can be reset in development and tests.
- Includes clean-state and completed-state UI tests.

### References
- [Gameplay Rules](../Gameplay-Rules.md)
- [Epic 6](../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S02 — Gameplay Polish

### Goal
Improve clarity and responsiveness without changing domain behaviour.

### Deliverable
Polished planning, execution and results presentation.

### Scope
- Card identity and route states.
- Depot, destination and current-position emphasis.
- Tunable motion, sound and haptics.
- Results presentation.

### Out of Scope
- New mechanics.
- New cards.
- iPad redesign.

### Dependencies
- E6-S01.

### Acceptance Criteria
- Distinguishes every card and route state without colour alone.
- Keeps layouts stable.
- Makes delay and damage noticeable.
- Keeps feedback independent from domain results.
- Does not change randomness or calculations.

### References
- [Epic 6](../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S03 — Accessibility

### Goal
Make the complete MVP usable with supported iOS accessibility features.

### Deliverable
VoiceOver, Dynamic Type and Reduce Motion support.

### Scope
- Labels, values, hints and announcements.
- Dynamic Type.
- Reduce Motion.
- Contrast and non-colour distinctions.
- Accessibility identifiers.

### Out of Scope
- Localisation.
- New gameplay modes.

### Dependencies
- E6-S02.

### Acceptance Criteria
- VoiceOver communicates cards, route state, metrics, execution and results.
- Announces invalid moves, route changes, delays, damage and outcomes.
- Keeps essential content usable with Dynamic Type.
- Provides an appropriate Reduce Motion experience.
- Passes manual accessibility validation and relevant UI tests.

### References
- [Epic 6](../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S04 — MVP Validation

### Goal
Validate the five seeded jobs and release candidate internally.

### Deliverable
Internally validated MVP release candidate.

### Scope
- Seed regression.
- Scenario and route review.
- Timing and economy balance.
- Deterministic outcome overrides.
- Full-loop and release-build validation.

### Out of Scope
- External feedback.
- Random jobs.

### Dependencies
- E6-S03.
- E5-S06.

### Acceptance Criteria
- Confirms a valid route for every job.
- Confirms each scenario's intended trade-offs.
- Records accepted seeds, Target Times and Deadlines.
- Finds no unintended dominant route that invalidates a scenario.
- Passes automated suites and manual accessibility checks.
- Confirms no state leaks or unintended release controls.

### References
- [Epic 5](../epics/Epic-5-Deck-and-Card-Generation.md)
- [Epic 6](../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S05 — TestFlight Release

### Goal
Produce and distribute a stable external TestFlight build.

### Deliverable
External TestFlight build and tester instructions.

### Scope
- Signing, versioning and archive.
- App Store Connect metadata.
- Internal and external TestFlight.
- Test instructions and known limitations.

### Out of Scope
- Public App Store release.
- Launch marketing.

### Dependencies
- E6-S04.

### Acceptance Criteria
- Archives with the supported Xcode and iOS 26 SDK.
- Uploads to App Store Connect.
- Installs and launches through internal TestFlight.
- Reaches the intended external group after required review.
- Includes validation-focused instructions and known limitations.

### References
- [Epic 6](../epics/Epic-6-Polish-and-TestFlight.md)

## E6-S06 — MVP Evaluation

### Goal
Collect structured feedback and decide whether the core route-planning loop is validated.

### Deliverable
MVP validation report and next-phase recommendation.

### Scope
- Player comprehension and route-choice reasoning.
- Risk and timing influence.
- Outcome fairness and replay interest.
- Strongest and weakest scenarios.
- Continue, revise or stop recommendation.

### Out of Scope
- Feature implementation.
- Random-job release.

### Dependencies
- E6-S05.

### Acceptance Criteria
- Collects structured external feedback.
- Evaluates every MVP success criterion.
- Documents strengths, weaknesses and recurring confusion.
- Identifies balancing or product changes.
- Produces a clear next-phase recommendation.
- Keeps random jobs disabled until the decision is accepted.

### References
- [Product Requirements Document](../PRD.md)
- [Roadmap](../Roadmap.md)
- [Epic 6](../epics/Epic-6-Polish-and-TestFlight.md)

---

# Cross-Epic Dependency Graph

```text
E5-S01 ─► E5-S04 ─┐
E5-S03 ───────────┼► E5-S05 ─► E1-S01 ─► E1-S02 ─► E1-S03
E5-S02 ───────────┘                              ├► E1-S04 ─┐
E5-S05 + E5-S02 ─► E5-S06                       └► E1-S05 ─┴► E1-S06

E1-S06 + E5-S02 ─► E2-S01
E2-S01 ─► E2-S03 ─┐
       ├► E2-S04 ─┼► E2-S02 ─► E2-S06
       └► E2-S05 ─┘

E2-S06 ─► E3-S01 ─► E3-S02 ◄─ E5-S01
                         └► E3-S03 ◄─ E5-S03
                                  └► E3-S04
                                      ├► E3-S05 ─┐
                                      └► E3-S06 ─┴► E3-S07

E3-S07 ─► E4-S01 ─► E4-S02 ◄─ E5-S02
                         └► E4-S03 ─► E4-S04 ◄─ E3-S06
                                          └► E4-S05 ◄─ E5-S06
                                                   └► E4-S06

E4-S06 ─► E6-S01 ─► E6-S02 ─► E6-S03 ─► E6-S04 ◄─ E5-S06
                                                   └► E6-S05 ─► E6-S06
```

## Parallel Work Opportunities

- E5-S02, E5-S03 and E5-S04.
- E1-S04 and E1-S05.
- E2-S03, E2-S04 and E2-S05.
- E3-S05 and E3-S06.

Parallel work must avoid competing ownership of core files and domain types.

---

# Recommended Implementation Order

## Workstream 1 — Core Foundation

1. E5-S01
2. E5-S03
3. E5-S04
4. E5-S02
5. E5-S05
6. E5-S06

**Checkpoint:** deterministic card, deck, board, job and economy foundations exist.

## Workstream 2 — Grid and Route Construction

1. E1-S01
2. E1-S02
3. E1-S03
4. E1-S04
5. E1-S05
6. E1-S06

**Checkpoint:** the player can inspect a board and build, edit and validate a route.

## Workstream 3 — Route Analysis and Confirmation

1. E2-S01
2. E2-S03
3. E2-S04
4. E2-S05
5. E2-S02
6. E2-S06

**Checkpoint:** the player can compare route consequences and confirm an immutable route.

## Workstream 4 — Route Execution

1. E3-S01
2. E3-S02
3. E3-S03
4. E3-S04
5. E3-S05
6. E3-S06
7. E3-S07

**Checkpoint:** the route resolves fully and produces an immutable execution result.

## Workstream 5 — Outcome and Progression

1. E4-S01
2. E4-S02
3. E4-S03
4. E4-S04
5. E4-S05
6. E4-S06

**Checkpoint:** the full functional MVP loop works across the five seeded jobs and replay.

## Workstream 6 — Polish and External Validation

1. E6-S01
2. E6-S02
3. E6-S03
4. E6-S04
5. E6-S05
6. E6-S06

**Checkpoint:** external testers can use the build and the project has evidence for a next-phase decision.

## Playable Milestones

| Milestone | Completed Through | Outcome |
|---|---|---|
| Board Prototype | E1-S02 | A deterministic seeded board is visible. |
| Route Builder | E1-S06 | The player can build, edit and validate a route. |
| Planning Prototype | E2-S06 | The player can analyse and confirm a route. |
| Executable Delivery | E3-S07 | The confirmed route resolves into an execution result. |
| Functional MVP | E4-S06 | The complete gameplay and progression loop works. |
| TestFlight MVP | E6-S05 | An externally distributable build is available. |
| MVP Decision | E6-S06 | Playtest evidence has produced a recommendation. |

## Implementation Rules

1. Dependencies must be complete or expose explicitly agreed stable interfaces.
2. Domain logic precedes consuming presentation.
3. A story is not Done until acceptance criteria and relevant tests pass.
4. Temporary fixtures must be removed before the dependent workstream completes.
5. Parallel work must avoid conflicting file and type ownership.
6. Refactoring must not silently change canonical gameplay behaviour.
7. Newly discovered scope is recorded separately rather than added informally.
8. Each workstream checkpoint is reviewed before the next major layer.

---

# Catalogue Summary

| Epic | Stories |
|---|---:|
| Epic 5 — Deck and Seeded Job Generation | 6 |
| Epic 1 — The Grid | 6 |
| Epic 2 — Route Planning | 6 |
| Epic 3 — Execution and Hazard Resolution | 7 |
| Epic 4 — Economy and Outcome | 6 |
| Epic 6 — Polish, Validation and TestFlight | 6 |
| **Total** | **37** |
