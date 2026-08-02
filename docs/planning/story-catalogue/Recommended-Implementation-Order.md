# Recommended Implementation Order

## Purpose

This document defines the recommended implementation sequence for the Delivery Game MVP.

The order is driven by technical dependencies and playable checkpoints rather than epic numbering.

---

# Workstream 1 — Core Foundation

## Objective

Establish the shared domain types, deterministic infrastructure and configuration used throughout the game.

## Stories

1. E5-S01 — Card Rule Definitions
2. E5-S03 — Seeded Random Number Generator
3. E5-S04 — Deck Recipe
4. E5-S02 — Shared Economy Configuration
5. E5-S05 — Board Generator
6. E5-S06 — Seeded Job Catalogue

## Completion Checkpoint

At the end of this workstream:

- all card types are defined;
- deterministic randomness is available;
- the canonical deck can be created;
- seeded boards can be generated;
- the five authored jobs can be loaded;
- economy values are centrally configured.

No player-facing gameplay is required yet.

---

# Workstream 2 — Grid and Route Construction

## Objective

Deliver the first player-facing vertical slice: viewing a board and building a valid route.

## Stories

1. E1-S01 — Grid Domain Model
2. E1-S02 — Grid Presentation
3. E1-S03 — Route Construction
4. E1-S04 — Route Editing
5. E1-S05 — Route Validation
6. E1-S06 — Planning Screen Foundation

## Parallel Work

After E1-S03 is complete:

- E1-S04 and E1-S05 may be implemented in parallel.

## Completion Checkpoint

At the end of this workstream, the player can:

- view a complete 5×5 seeded board;
- identify the depot and destination;
- construct an orthogonally connected route;
- undo route choices;
- reach the destination;
- see when the route is valid for confirmation.

Planning metrics may initially use an unavailable state until Workstream 3 is complete.

---

# Workstream 3 — Route Analysis and Confirmation

## Objective

Turn route construction into a complete planning experience.

## Stories

1. E2-S01 — Planning Analysis Engine
2. E2-S03 — Delay Exposure Classification
3. E2-S04 — Damage Risk Classification
4. E2-S05 — Maximum Reward Estimation
5. E2-S02 — Planning Summary Presentation
6. E2-S06 — Route Confirmation

## Parallel Work

After E2-S01 is complete:

- E2-S03, E2-S04 and E2-S05 may be implemented in parallel.

## Completion Checkpoint

At the end of this workstream, the player can:

- see estimated arrival;
- compare Target Time and Deadline;
- understand delay exposure;
- understand damage risk;
- see maximum achievable reward;
- confirm an analysed route;
- produce immutable execution input.

This is the first complete version of the planning phase.

---

# Workstream 4 — Route Execution

## Objective

Resolve the confirmed route and make the consequences of the player's plan visible.

## Stories

1. E3-S01 — Execution Engine
2. E3-S02 — Card Resolution Engine
3. E3-S03 — Hazard Resolution
4. E3-S04 — Execution Event History
5. E3-S05 — Execution Presentation
6. E3-S06 — Route Recap
7. E3-S07 — Execution Completion

## Parallel Work

After E3-S04 is complete:

- E3-S05 and E3-S06 may be implemented in parallel.

E3-S07 depends on E3-S06 only. Presentation does not gate the domain execution result.

## Completion Checkpoint

At the end of this workstream:

- every entered card resolves once and in order;
- time and damage outcomes are deterministic for a fixed random sequence;
- execution events are fully recorded;
- the player can follow the route visually;
- a complete route recap is available;
- an immutable execution result is produced.

The game now has a complete route-planning and execution loop, but no final payout or progression.

---

# Workstream 5 — Outcome and Progression

## Objective

Complete the end-to-end gameplay loop by evaluating the run, settling rewards and advancing through the seeded jobs.

## Stories

1. E4-S01 — Outcome Evaluation
2. E4-S02 — Reward Settlement
3. E4-S03 — Outcome Breakdown
4. E4-S04 — Results Screen
5. E4-S05 — Job Progression
6. E4-S06 — Outcome Integration

## Completion Checkpoint

At the end of this workstream, the player can:

- plan a route;
- confirm it;
- watch it execute;
- receive a completed or failed outcome;
- understand the reward calculation;
- continue through Jobs 1–5;
- replay seeded jobs after completing the sequence.

This is the first functionally complete MVP.

---

# Workstream 6 — Polish and External Validation

## Objective

Prepare the functionally complete MVP for TestFlight and structured playtesting.

## Stories

1. E6-S01 — First-Time User Experience
2. E6-S02 — Gameplay Polish
3. E6-S03 — Accessibility
4. E6-S04 — MVP Validation
5. E6-S05 — TestFlight Release
6. E6-S06 — MVP Evaluation

## Completion Checkpoint

At the end of this workstream:

- first-time players can understand the game;
- presentation is clear and responsive;
- supported accessibility features work;
- all five seeded jobs are internally validated;
- an external TestFlight build is available;
- structured feedback has been collected;
- a recommendation exists for the next product phase.

---

# Recommended Story Sequence

```text
E5-S01
E5-S03
E5-S04
E5-S02
E5-S05
E5-S06
E1-S01
E1-S02
E1-S03
E1-S04
E1-S05
E1-S06
E2-S01
E2-S03
E2-S04
E2-S05
E2-S02
E2-S06
E3-S01
E3-S02
E3-S03
E3-S04
E3-S05
E3-S06
E3-S07
E4-S01
E4-S02
E4-S03
E4-S04
E4-S05
E4-S06
E6-S01
E6-S02
E6-S03
E6-S04
E6-S05
E6-S06
```

This is a safe default rather than a rigid mandate. Stories identified as parallel opportunities may proceed concurrently once shared dependencies are complete.

---

# Playable Milestones

## Milestone 1 — Board Prototype

**Completed through:** E1-S02

**Outcome:** A deterministic seeded board is visible.

## Milestone 2 — Route Builder

**Completed through:** E1-S06

**Outcome:** The player can build, edit and validate a route.

## Milestone 3 — Planning Prototype

**Completed through:** E2-S06

**Outcome:** The player can compare route consequences and confirm a route.

## Milestone 4 — Executable Delivery

**Completed through:** E3-S07

**Outcome:** The confirmed route resolves completely and produces an execution result.

## Milestone 5 — Functional MVP

**Completed through:** E4-S06

**Outcome:** The full gameplay loop works from planning through results and progression.

## Milestone 6 — TestFlight MVP

**Completed through:** E6-S05

**Outcome:** An externally distributable MVP build is available.

## Milestone 7 — MVP Decision

**Completed through:** E6-S06

**Outcome:** Playtest evidence has been reviewed and a decision has been made about further development.

---

# Implementation Rules

1. A story must not begin until its required dependencies are complete or expose explicitly agreed stable interfaces.
2. Domain logic must be completed before the UI that consumes it.
3. A story is not complete until its acceptance criteria and relevant automated tests pass.
4. Temporary fixtures may be used to unblock presentation work but must be removed before the dependent workstream completes.
5. Parallel work must avoid competing ownership of the same files or domain types.
6. Refactoring may occur within a story but must not silently change canonical gameplay behaviour.
7. New scope discovered during implementation must be recorded separately rather than added informally to an active story.
8. Workstream completion checkpoints should be reviewed before starting the next major layer.
