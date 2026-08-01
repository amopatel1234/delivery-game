# Epic 5 – Deck and Seeded Job Generation

## Goal

Create the deterministic job-generation foundation that produces the five authored MVP scenarios, guarantees the accepted card distribution, and supplies reproducible job data to the planning and execution systems.

This epic ensures every seeded job can be regenerated exactly for balancing, testing and bug reproduction.

## Scope

This epic includes:

- Canonical card definitions.
- Fixed 25-card deck composition.
- Deterministic shuffling and placement.
- Fixed depot and destination placement.
- Seeded job model.
- Five authored MVP job definitions.
- Shared economy configuration.
- Per-job Target Time and Deadline values.
- Seed validation tooling and tests.
- Test overrides for selecting a job directly.

Random standalone jobs are out of scope until the seeded MVP has been validated.

## Player Experience

The player should experience five distinct planning scenarios while the underlying system remains fully reproducible.

Each seeded job must:

- present the same grid every time;
- preserve the same card distribution;
- preserve the same Target Time and Deadline;
- remain suitable for comparing alternative routes;
- avoid introducing hidden variation between playtests.

The generation system itself is not visible to the player.

## Functional Requirements

### Canonical Card Definitions

Define the five MVP card types in one domain-owned rules source:

- Clear Road.
- Light Traffic.
- Heavy Traffic.
- Roadworks.
- Fast Lane.

Each card definition must expose the data required by planning and execution without embedding behaviour in SwiftUI views.

### Deck Composition

Every generated MVP board contains exactly 25 cards:

| Card | Count |
|---|---:|
| Clear Road | 10 |
| Light Traffic | 7 |
| Heavy Traffic | 5 |
| Roadworks | 2 |
| Fast Lane | 1 |

The depot and destination are two of the ten Clear Road cards.

Deck construction must reject or fail tests for any composition that does not total 25 cards.

### Fixed Positions

- Place the depot at the top-left grid position.
- Place the destination at the bottom-right grid position.
- Keep both positions as Clear Road.
- Do not allow shuffling to move or replace either fixed position.

### Deterministic Generation

- Accept an explicit seed.
- Use a seeded random-number source for shuffle and placement.
- Produce the same ordered grid for the same seed and generator version.
- Produce different grids for suitably different seeds.
- Avoid use of global or implicit randomness.
- Make the generator independently testable from UI and run execution.

### Seeded Job Model

Represent each MVP job with at least:

- stable job identifier;
- display name;
- seed;
- Target Time;
- Deadline;
- shared economy configuration reference;
- optional design notes for balancing and test intent.

The five jobs are:

1. Direct but Risky.
2. Predictable Detour.
3. Fast Lane Temptation.
4. Deadline Pressure.
5. Close Decision.

### Authored Job Intent

Each selected seed must support its intended validation purpose:

- **Direct but Risky:** a short route with meaningful Heavy Traffic exposure and a safer alternative.
- **Predictable Detour:** a longer deterministic route that competes with a shorter uncertain route.
- **Fast Lane Temptation:** a route choice where Fast Lane materially changes timing or reward potential.
- **Deadline Pressure:** limited timing margin that makes route composition matter.
- **Close Decision:** at least two routes with comparable trade-offs and no obviously dominant option.

These are balancing criteria, not runtime hints shown to the player.

### Shared Economy Configuration

- All five initial jobs use one economy configuration.
- Store economy values centrally.
- Do not duplicate economy constants in each job definition.
- Allow Target Time and Deadline to vary per job.

### Seed Selection and Validation

Provide a repeatable developer workflow to:

- generate candidate boards from seed values;
- inspect card positions and viable route characteristics;
- reject boards that do not support the intended scenario;
- record the selected seed in the authored job definition;
- verify selected seeds remain stable after code changes.

Any intentional generator change that alters an accepted seeded board must be treated as a product-data change and reviewed explicitly.

### Job Loading

- Load Job 1 as the default first MVP job.
- Allow tests and development builds to request a specific seeded job directly.
- Return a complete immutable job instance containing the generated grid and authored configuration.
- Ensure loading a job resets any previous run-specific state through the owning session flow.

## Out of Scope

- Unlimited random job mode.
- Procedural city or road-network generation.
- Dynamic card-count balancing.
- Difficulty scaling.
- Daily challenges.
- Remote job definitions.
- Player-created seeds.
- Persistent campaign progression.
- Economy spending.
- Final visual presentation of card art.

## Dependencies

This epic provides foundational data required by Epics 1–4 and should be implemented early despite retaining its original epic number.

It depends on:

- canonical gameplay rules;
- grid-coordinate model;
- injected seeded random-number abstraction.

## User Stories

### Replay the same job

As a tester, I want a seeded job to generate the same board every time so that I can compare routes and reproduce issues.

### Experience distinct scenarios

As a player, I want each MVP job to create a different planning challenge so that the validation build tests more than one route pattern.

### Select a job during development

As a developer or tester, I want to load a specific seeded job directly so that I can validate a scenario without replaying the full sequence.

## Acceptance Criteria

- Every board contains exactly 25 cards.
- Every board contains the accepted count of each card type.
- Depot is always top-left and Clear Road.
- Destination is always bottom-right and Clear Road.
- The same seed produces the same ordered grid.
- Generation does not use implicit global randomness.
- Each authored job has a stable identifier, seed, Target Time and Deadline.
- All five jobs reference the same economy configuration.
- The five named seeded jobs can be loaded directly in tests and development builds.
- Selected seeds are covered by snapshot or equivalent structural regression tests.
- Random standalone job generation is not exposed in the MVP flow.
- SwiftUI views contain no deck-construction or shuffle logic.

## Technical Notes

Keep these concerns separate:

- card-rule definitions;
- deck recipe;
- seeded shuffle or placement algorithm;
- authored job catalogue;
- job loader.

Use an explicit seeded random-number protocol or equivalent abstraction shared with hazard resolution where appropriate. Generator output should be value-based and immutable after job creation.

Because generator changes can invalidate accepted seeds, include a generator-version strategy or structural regression tests that make board changes obvious during review.

## Definition of Done

- All acceptance criteria are met.
- Unit tests verify exact deck composition.
- Tests verify fixed depot and destination positions.
- Tests verify deterministic output for repeated seeds.
- Tests verify different candidate seeds can produce different arrangements.
- Regression tests lock the final selected layout for all five authored jobs.
- Tests verify all jobs share one economy configuration.
- Development or test tooling can load any seeded job directly.
- The selected seeds, Target Times and Deadlines are documented in the authored job catalogue.

## References

- [Product Requirements Document](../PRD.md)
- [Gameplay Rules](../Gameplay-Rules.md)
- [Decision Log](../Decision-Log.md)
- [Epic 1 – The Grid](Epic-1-The-Grid.md)
- [Epic 2 – Route Planning](Epic-2-Route-Planning.md)
- [Epic 3 – Execution and Hazard Resolution](Epic-3-Hazard-System.md)
- [Epic 4 – Economy and Outcome](Epic-4-Economy-and-Outcome.md)
