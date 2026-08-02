# Cross-Epic Dependencies

## Purpose

This document defines the implementation dependencies between stories across all epics.

Its purpose is to:

- identify implementation order;
- highlight opportunities for parallel development;
- prevent circular dependencies;
- provide the dependency information used when creating GitHub Issues.

The dependency graph is intentionally capability-driven rather than document-driven. Epic numbering reflects product organisation, not implementation order.

---

# Foundation Layer

The foundation layer provides the shared domain models, deterministic behaviour and configuration required by every other epic.

```text
E5-S01 Card Rule Definitions
        │
        ▼
E5-S04 Deck Recipe
        │
        ▼
E5-S05 Board Generator ◄── E5-S03 Seeded RNG
        │                         │
        ▼                         └──────────────► E3-S03
E5-S06 Job Catalogue ◄── E5-S02 Economy Configuration
```

Dependencies:

- E5-S01 → E5-S04
- E5-S03 → E5-S05
- E5-S04 → E5-S05
- E5-S02 → E5-S06
- E5-S05 → E5-S06
- E5-S03 → E3-S03

E5-S02 does not depend on E5-S01.

---

# Grid Layer

The grid layer introduces the player's first interaction with the game.

```text
E5-S05
    │
    ▼
E1-S01 Grid Domain
    │
    ▼
E1-S02 Grid Presentation
    │
    ▼
E1-S03 Route Construction
    │
    ├──────────────┐
    │              │
    ▼              ▼
E1-S04        E1-S05
Route Editing Route Validation
    │              │
    └──────┐  ┌────┘
           ▼  ▼
      E1-S06 Planning Screen
```

Dependencies:

- E1-S01 → E1-S02 → E1-S03
- E1-S03 → E1-S04
- E1-S03 → E1-S05
- E1-S04 + E1-S05 → E1-S06

Route Editing and Route Validation may proceed in parallel after Route Construction.

---

# Planning Layer

Planning analyses a completed route without consuming randomness.

```text
E1-S06 + E5-S02
        │
        ▼
E2-S01 Planning Analysis Engine
        │
        ├──────────────┬──────────────┐
        │              │              │
        ▼              ▼              ▼
   E2-S03         E2-S04         E2-S05
   Delay          Damage         Maximum
   Exposure       Risk           Reward
        │              │              │
        └──────────────┼──────────────┘
                       ▼
                E2-S02 Planning Summary
                       │
                       ▼
                E2-S06 Route Confirmation
```

Dependencies:

- E1-S06 + E5-S02 → E2-S01
- E2-S01 → E2-S03
- E2-S01 → E2-S04
- E2-S01 → E2-S05
- E2-S03 + E2-S04 + E2-S05 → E2-S02
- E2-S02 → E2-S06

Delay Exposure, Damage Risk and Maximum Reward may proceed in parallel after the Planning Analysis Engine.

---

# Execution Layer

Execution consumes the immutable confirmed route produced by planning.

```text
E2-S06
    │
    ▼
E3-S01 Execution Engine
    │
    ▼
E3-S02 Card Resolution ◄── E5-S01
    │
    ▼
E3-S03 Hazard Resolution ◄── E5-S03
    │
    ▼
E3-S04 Event History
    │
    ├──────────────┐
    │              │
    ▼              ▼
E3-S05        E3-S06
Presentation  Route Recap
                   │
                   ▼
              E3-S07 Execution Completion
```

Dependencies:

- E2-S06 → E3-S01 → E3-S02 → E3-S03 → E3-S04
- E3-S04 → E3-S05
- E3-S04 → E3-S06
- E3-S06 → E3-S07

The domain execution result does not depend on the presentation story.

---

# Outcome Layer

Outcome consumes the immutable execution result.

```text
E3-S07
    │
    ▼
E4-S01 Outcome Evaluation
    │
    ▼
E4-S02 Reward Settlement ◄── E5-S02
    │
    ▼
E4-S03 Outcome Breakdown
    │
    ▼
E4-S04 Results Screen ◄── E3-S06
    │
    ▼
E4-S05 Job Progression ◄── E5-S06
    │
    ▼
E4-S06 Outcome Integration
```

Dependencies:

- E3-S07 → E4-S01 → E4-S02 → E4-S03 → E4-S04 → E4-S05 → E4-S06
- E5-S02 → E4-S02
- E3-S06 → E4-S04
- E5-S06 → E4-S05

---

# Polish Layer

Polish begins only after the gameplay loop is functionally complete.

```text
E4-S06
    │
    ▼
E6-S01 Onboarding
    │
    ▼
E6-S02 Gameplay Polish
    │
    ▼
E6-S03 Accessibility
    │
    ▼
E6-S04 MVP Validation ◄── E5-S06
    │
    ▼
E6-S05 TestFlight Release
    │
    ▼
E6-S06 MVP Evaluation
```

Dependencies:

- E4-S06 → E6-S01 → E6-S02 → E6-S03
- E6-S03 + E5-S06 → E6-S04
- E6-S04 → E6-S05 → E6-S06

---

# Cross-Epic Dependencies

| Story | Depends On |
|--------|------------|
| E1-S01 | E5-S05 |
| E2-S01 | E1-S06, E5-S02 |
| E3-S02 | E3-S01, E5-S01 |
| E3-S03 | E3-S02, E5-S03 |
| E4-S02 | E4-S01, E5-S02 |
| E4-S04 | E4-S03, E3-S06 |
| E4-S05 | E4-S04, E5-S06 |
| E6-S04 | E6-S03, E5-S06 |

---

# Parallel Work Opportunities

## Foundation

The following stories may be implemented in parallel:

- E5-S02 — Shared Economy Configuration
- E5-S03 — Seeded Random Number Generator
- E5-S04 — Deck Recipe (after E5-S01)

---

## Grid

After **E1-S03** completes:

- E1-S04 — Route Editing
- E1-S05 — Route Validation

These stories are independent and may proceed concurrently.

---

## Planning

After **E2-S01** completes:

- E2-S03 — Delay Exposure Classification
- E2-S04 — Damage Risk Classification
- E2-S05 — Maximum Reward Estimation

These stories are independent and may proceed concurrently.

---

## Execution

After **E3-S04** completes:

- E3-S05 — Execution Presentation
- E3-S06 — Route Recap

Both consume the immutable execution event history. Presentation does not gate the domain execution result.

---

# Dependency Rules

The Story Catalogue follows these rules:

1. Dependencies always point towards lower-level capabilities.
2. Circular dependencies are prohibited.
3. Stories should depend on as few other stories as possible.
4. Domain stories never depend on presentation.
5. Presentation stories consume domain services but never provide them.
6. Shared behaviour belongs in foundation stories rather than duplicated across epics.
7. Every story must be independently testable once its dependencies are complete.
8. Parallel stories must avoid conflicting ownership of the same domain models or files.
