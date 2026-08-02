# Epic 3 – Execution and Hazard Resolution

## E3-S01 — Execution Engine

### Goal

Create the domain engine responsible for executing a confirmed route from start to finish.

The execution engine owns the lifecycle of a delivery run and coordinates the resolution of every card in order.

### Deliverable

Execution Engine.

### Scope

- Execution lifecycle.
- Route traversal.
- Immutable execution input.
- Execution state machine.
- Completion detection.

### Out of Scope

- Card-specific behaviour.
- Reward calculation.
- UI animation.

### Dependencies

- E2-S06.

### Acceptance Criteria

- Executes one confirmed route.
- Never mutates the confirmed route.
- Resolves cards sequentially.
- Prevents concurrent or duplicate execution.
- Produces deterministic execution state.
- Includes lifecycle unit tests.

### References

- [Epic 3](../../epics/Epic-3-Execution-and-Hazard-Resolution.md)

## E3-S02 — Card Resolution Engine

### Goal

Resolve the gameplay behaviour of every card entered during execution.

### Deliverable

Card Resolution Service.

### Scope

- Clear Road.
- Light Traffic.
- Heavy Traffic.
- Roadworks.
- Fast Lane.
- Time accumulation.

### Out of Scope

- Reward settlement.
- Presentation.

### Dependencies

- E3-S01.
- E5-S01.

### Acceptance Criteria

- Every card resolves according to Gameplay Rules.
- Fast Lane consumes zero travel time.
- Never damages from non-Heavy-Traffic cards.
- Heavy Traffic delegates probability checks.
- Resolution order matches the confirmed route.
- Includes unit tests for every card type.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 3](../../epics/Epic-3-Execution-and-Hazard-Resolution.md)

## E3-S03 — Hazard Resolution

### Goal

Resolve probabilistic gameplay events using deterministic random-number generation.

### Deliverable

Hazard Resolution Service.

### Scope

- Delay rolls.
- Damage rolls.
- Heavy Traffic conditional logic.
- Random-number consumption.

### Out of Scope

- Card traversal.
- Settlement.

### Dependencies

- E3-S02.
- E5-S03.

### Acceptance Criteria

- Uses injected RNG.
- Damage rolls occur only after successful delay rolls.
- Does not consume unnecessary random values.
- Produces deterministic results for identical seeds.
- Uses inclusive 1–100 thresholds.
- Includes threshold and consumption unit tests.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 3](../../epics/Epic-3-Execution-and-Hazard-Resolution.md)

## E3-S04 — Execution Event History

### Goal

Record every execution event for replay, analysis and settlement.

### Deliverable

Execution Event Log.

### Scope

- Resolution events.
- Elapsed time.
- Damage events.
- Route index.
- Roll results.

### Out of Scope

- UI recap.
- Reward calculation.

### Dependencies

- E3-S03.

### Acceptance Criteria

- One event recorded per resolved card.
- Events preserve execution order.
- Records only consumed rolls.
- Event history is immutable after completion.
- Settlement can consume the event history alone.
- Includes event-integrity unit tests.

### References

- [Epic 3](../../epics/Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)

## E3-S05 — Execution Presentation

### Goal

Present execution progress to the player without influencing gameplay behaviour.

### Deliverable

Execution Presentation Layer.

### Scope

- Player movement.
- Active card highlighting.
- Time display.
- Damage display.
- Execution progress.

### Out of Scope

- Animation polish.
- Audio.
- Haptics.

### Dependencies

- E3-S04.

### Acceptance Criteria

- Player position matches execution state.
- Time updates after each resolution.
- Damage count updates immediately.
- Presentation never changes execution results.
- Includes progression and control-locking UI tests.

### References

- [Epic 3](../../epics/Epic-3-Execution-and-Hazard-Resolution.md)

## E3-S06 — Route Recap

### Goal

Produce a complete summary of the executed journey.

### Deliverable

Execution Recap Model.

### Scope

- Card history.
- Delay summary.
- Damage summary.
- Total elapsed time.
- Route recap.

### Out of Scope

- Final reward.
- Completed/failed determination.

### Dependencies

- E3-S04.

### Acceptance Criteria

- Every resolved card appears once.
- Recap matches recorded event history.
- Totals match execution state.
- Output is presentation-independent.
- Includes model consistency unit tests.

### References

- [Epic 3](../../epics/Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)

## E3-S07 — Execution Completion

### Goal

Complete the execution phase and hand control to the outcome system.

### Deliverable

Execution Result.

### Scope

- Completion state.
- Final elapsed time.
- Damage totals.
- Event history.
- Transition object.

### Out of Scope

- Reward settlement.
- UI.

### Dependencies

- E3-S06.

### Acceptance Criteria

- Produces an immutable execution result.
- Contains everything required by Epic 4.
- Execution cannot continue after completion.
- Transition occurs exactly once.
- Does not depend on presentation.
- Includes completion and duplicate-transition unit tests.

### References

- [Epic 3](../../epics/Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)

---
