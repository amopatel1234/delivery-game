# Epic 4 – Economy and Outcome

## E4-S01 — Outcome Evaluation

### Goal

Evaluate the completed execution and determine the final outcome of the delivery run.

This story applies the canonical Target Time and Deadline rules to produce either a completed or failed result.

### Deliverable

Outcome Evaluation Service.

### Scope

- Completed determination.
- Failed determination.
- Target Time evaluation.
- Deadline evaluation.
- Outcome status.

### Out of Scope

- Reward calculation.
- Presentation.

### Dependencies

- E3-S07.

### Acceptance Criteria

- Runs finishing before Target Time are marked as completed.
- Runs finishing exactly at Target Time are completed.
- Runs finishing after Target Time but before Deadline are completed.
- Runs finishing at or after Deadline fail.
- Outcome evaluation is deterministic.
- Includes every timing-boundary unit test.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)

## E4-S02 — Reward Settlement

### Goal

Calculate the final payout using the shared economy configuration and execution outcome.

### Deliverable

Reward Settlement Service.

### Scope

- Base reward.
- Early bonus.
- Late penalty.
- Damage penalty.
- Final reward clamping.

### Out of Scope

- UI.
- Progression.

### Dependencies

- E4-S01.
- E5-S02.

### Acceptance Criteria

- Uses the shared economy configuration.
- Applies bonuses and penalties correctly.
- Failed runs always return zero reward.
- Final reward is never negative.
- Settlement consumes only immutable execution data.
- Consumes no randomness.
- Includes timing, damage and clamping unit tests.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)

## E4-S03 — Outcome Breakdown

### Goal

Produce a presentation-neutral explanation of how the final reward was calculated.

### Deliverable

Outcome Breakdown Model.

### Scope

- Base reward.
- Early bonus.
- Late penalty.
- Damage penalty.
- Final reward.
- Timing summary.

### Out of Scope

- SwiftUI.

### Dependencies

- E4-S02.

### Acceptance Criteria

- Every calculation component is available.
- Zero-value components remain available to consumers.
- Breakdown matches settlement exactly.
- Output is immutable.
- Includes mapping and consistency unit tests.

### References

- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)

## E4-S04 — Results Screen

### Goal

Present the completed outcome to the player.

### Deliverable

Results Screen.

### Scope

- Outcome heading.
- Reward display.
- Timing comparison.
- Breakdown presentation.
- Route recap integration.
- Continue action.

### Out of Scope

- Animation polish.
- Audio.
- Haptics.

### Dependencies

- E4-S03.
- E3-S06.

### Acceptance Criteria

- Completed and failed outcomes are visually distinct.
- Reward matches settlement.
- Timing information is visible.
- Breakdown is readable.
- Route recap is accessible.
- Includes completed and failed UI tests.

### References

- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)

## E4-S05 — Job Progression

### Goal

Manage progression through the five authored MVP jobs.

### Deliverable

Job Progression Coordinator.

### Scope

- Sequential progression.
- Replay unlock.
- Run reset.
- Job loading.

### Out of Scope

- Random jobs.
- Persistent progression.

### Dependencies

- E4-S04.
- E5-S06.

### Acceptance Criteria

- Jobs progress from 1 to 5.
- Completing Job 5 unlocks replay.
- Replaying resets run state.
- Random jobs remain unavailable.
- Includes progression and reset unit tests.

### References

- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)
- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)

## E4-S06 — Outcome Integration

### Goal

Integrate execution, settlement and progression into one completed gameplay loop.

### Deliverable

Complete Outcome Flow.

### Scope

- Execution → Outcome transition.
- Settlement.
- Results.
- Progression.
- Replay hand-off.

### Out of Scope

- TestFlight.
- Analytics.

### Dependencies

- E4-S05.

### Acceptance Criteria

- Complete gameplay loop functions end-to-end.
- Outcome is shown exactly once.
- Progression follows the canonical MVP flow.
- All state transitions are deterministic.
- Includes an end-to-end functional MVP UI test.

### References

- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)
- [Epic 6](../../epics/Epic-6-Polish-and-TestFlight.md)

---
