# Delivery Game Documentation

This folder contains the canonical product and delivery documentation for the Delivery Game MVP.

## Canonical Documents

- [Product Requirements Document](PRD.md) — product goals, MVP scope, player experience, and validation criteria.
- [Gameplay Rules](Gameplay-Rules.md) — authoritative mechanics, calculations, card effects, timing, and reward rules.
- [Decision Log](Decision-Log.md) — accepted product decisions and their rationale.
- [Roadmap](Roadmap.md) — delivery order, MVP gates, and post-MVP direction.
- [Backlog](Backlog.md) — deferred ideas and follow-up work.
- [Epics](epics/) — implementation-focused acceptance criteria.
- [Story Catalogue](planning/story-catalogue/) — implementation stories, dependencies, and recommended delivery order. GitHub Issues are derived from this catalogue; they are not the source of truth.
- [Story Catalogue README](planning/story-catalogue/README.md) — catalogue contents and story counts.
- [Delivery Workflow](planning/Delivery-Workflow.md) — issue/PR/CI harness for story traceability and completion.
- [GitHub Tracking Bootstrap](planning/GitHub-Tracking-Bootstrap.md) — manual label, issue and Project seeding when the agent token cannot write.

## Document Precedence

When documents disagree, use this order:

1. `Gameplay-Rules.md` for exact mechanics.
2. `PRD.md` for scope and player experience.
3. `Decision-Log.md` for rationale and superseded choices.
4. `Roadmap.md` and `epics/` for delivery planning.
5. `planning/story-catalogue/` for implementation stories and sequencing.

A contradiction should be corrected rather than preserved in downstream documents.
