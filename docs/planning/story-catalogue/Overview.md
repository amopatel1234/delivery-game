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

This document decomposes the approved implementation epics into implementation-sized stories for the Delivery Game MVP.

It is the canonical implementation planning document that bridges the gap between high-level requirements and executable implementation work. GitHub Issues, Project items and implementation workstreams are derived from this catalogue; they are not the source of truth.

## Scope

This document defines:

- implementation stories;
- story dependencies;
- acceptance criteria;
- ownership boundaries;
- parallel work opportunities;
- recommended implementation order.

This document does not redefine gameplay behaviour. If a conflict exists, precedence is:

1. Product Requirements Document;
2. Gameplay Rules;
3. Decision Log;
4. Implementation Epics;
5. Story Catalogue;
6. GitHub Issues;
7. Code.

## Story Principles

### Deliver one capability

Each story produces one coherent, meaningful capability and avoids combining unrelated concerns.

### Independently testable

Every story has objective acceptance criteria and includes the automated tests required to prove completion.

### Vertically sliced

Stories deliver working software where practical rather than fragmenting work by technical layer without user or architectural value.

### Domain before UI

Domain models and business logic are implemented before presentation. SwiftUI views consume behaviour rather than own it.

### Small but valuable

Stories should normally be implementable within a small, focused workstream. Large stories are decomposed; tiny stories with no independent value are combined.

### Stable interfaces

Stories should expose interfaces that minimise downstream changes. Later stories extend behaviour rather than rewrite completed work.

### Minimise dependencies

Stories depend only on completed lower-level capabilities. Circular dependencies are prohibited.

### Canonical documents

Stories reference the PRD, Gameplay Rules, Decision Log and Epics without redefining them.

## Story Identifier Format

Every story receives a stable identifier in the format `E<epic>-S<story>`.

Examples:

- `E5-S01`
- `E1-S04`
- `E3-S07`

Identifiers do not change after publication, although titles may evolve.

## Story Template

Each story uses this structure:

- Identifier and title
- Goal
- Deliverable
- Scope
- Out of Scope
- Dependencies
- Acceptance Criteria
- References

## Story Lifecycle

`Draft → Ready → In Progress → In Review → Done`

A story may enter **Ready** only when all required dependencies are complete or their interfaces are stable and explicitly agreed.
