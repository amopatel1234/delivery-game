# Epic 5 – Deck and Seeded Job Generation

## E5-S01 — Card Rule Definitions

### Goal

Create the canonical domain representation of every card used by the MVP.

### Deliverable

Card rule definitions and the `CardType` domain model.

### Scope

- Define the five MVP card types.
- Define immutable timing and hazard metadata.
- Provide stable identifiers for persistence, testing and presentation.
- Centralise card behaviour inputs used by planning and execution.

### Out of Scope

- Board generation.
- Route planning.
- Hazard execution.
- SwiftUI rendering.

### Dependencies

- None.

### Acceptance Criteria

- Defines Clear Road, Light Traffic, Heavy Traffic, Roadworks and Fast Lane.
- Gives every card type a stable identifier.
- Defines Fast Lane with zero travel time, no delay and no damage.
- Defines Heavy Traffic delay and conditional damage probabilities.
- Keeps all card definitions immutable.
- Contains no SwiftUI or presentation logic.
- Includes unit tests for every card definition.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S02 — Shared Economy Configuration

### Goal

Create one configurable economy definition shared by every MVP job and consumed by planning and settlement.

### Deliverable

Shared economy configuration model.

### Scope

- Base reward.
- Early bonus rate.
- Lateness penalty rate.
- Damage penalty rate.
- Reward clamping policy.

### Out of Scope

- Reward settlement.
- Results presentation.
- Persistent currency spending.

### Dependencies

- None.

### Acceptance Criteria

- Stores all MVP economy values centrally.
- Prevents reward constants being duplicated in views or services.
- Can be injected into planning and settlement services.
- Supports the canonical minimum reward rule.
- Includes unit tests for default and custom configurations.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 4](../../epics/Epic-4-Economy-and-Outcome.md)
- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S03 — Seeded Random Number Generator

### Goal

Provide deterministic random-number generation for board creation and gameplay simulation.

### Deliverable

Injectable seeded random-number abstraction with production and test implementations.

### Scope

- Random-number protocol or equivalent abstraction.
- Seeded production implementation.
- Deterministic test implementation.
- Inclusive percentage roll support.

### Out of Scope

- Board generation.
- Hazard rules.
- UI controls for seed selection.

### Dependencies

- None.

### Acceptance Criteria

- Produces the same sequence for the same seed.
- Produces different sequences for suitably different seeds.
- Allows tests to provide exact values.
- Supports inclusive percentage rolls from 1 through 100.
- Prevents gameplay code from using implicit global randomness.
- Includes deterministic sequence and boundary tests.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 3](../../epics/Epic-3-Execution-and-Hazard-Resolution.md)
- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S04 — Deck Recipe

### Goal

Create and validate the canonical 25-card MVP deck recipe.

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

- Creates a deck containing exactly 25 cards.
- Creates 10 Clear Road, 7 Light Traffic, 5 Heavy Traffic, 2 Roadworks and 1 Fast Lane cards.
- Reserves two Clear Road cards for depot and destination.
- Rejects invalid totals or card counts.
- Includes exact-composition and invalid-recipe tests.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S05 — Board Generator

### Goal

Generate an immutable deterministic 5×5 board from a deck recipe and seed.

### Deliverable

Seeded board generator.

### Scope

- Deterministic shuffle or placement.
- Fixed depot position.
- Fixed destination position.
- Grid population.
- Structural validation.

### Out of Scope

- Route planning.
- Hazard execution.
- Seed balancing tools.

### Dependencies

- E5-S03.
- E5-S04.

### Acceptance Criteria

- Produces the same ordered board for the same seed and generator version.
- Places the depot at the top-left coordinate.
- Places the destination at the bottom-right coordinate.
- Keeps depot and destination as Clear Road.
- Produces exactly one card per grid coordinate.
- Returns immutable generated board data.
- Includes deterministic output and structural validation tests.

### References

- [Gameplay Rules](../../Gameplay-Rules.md)
- [Epic 1](../../epics/Epic-1-The-Grid.md)
- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)

## E5-S06 — Seeded Job Catalogue

### Goal

Create the five authored MVP jobs and a loader that returns complete immutable job data.

### Deliverable

Seeded job catalogue and job loader.

### Scope

- Stable job identifiers.
- Display names.
- Seed values.
- Target Time and Deadline.
- Shared economy reference.
- Direct development and test loading.

### Out of Scope

- Random jobs.
- Sequential progression.
- Persistent campaign state.

### Dependencies

- E5-S02.
- E5-S05.

### Acceptance Criteria

- Defines Direct but Risky, Predictable Detour, Fast Lane Temptation, Deadline Pressure and Close Decision.
- Gives every job a stable identifier, seed, Target Time and Deadline.
- Makes all five jobs reference the same economy configuration.
- Loads any job directly for development and tests.
- Produces identical job data for repeated loads.
- Includes structural regression tests for all accepted seeded boards.

### References

- [Epic 5](../../epics/Epic-5-Deck-and-Card-Generation.md)
- [Epic 6](../../epics/Epic-6-Polish-and-TestFlight.md)

---
