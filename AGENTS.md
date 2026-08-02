# Agent instructions

This file is a **map**. Read only what the task needs; do not treat it as the full rulebook.

## Start here

1. **Product goals / MVP scope:** [`docs/PRD.md`](docs/PRD.md)
2. **Authoritative mechanics:** [`docs/Gameplay-Rules.md`](docs/Gameplay-Rules.md)
3. **Accepted product decisions:** [`docs/Decision-Log.md`](docs/Decision-Log.md)
4. **Implementation epics:** [`docs/epics/`](docs/epics/)
5. **Story catalogue (delivery scope):** [`docs/planning/story-catalogue/`](docs/planning/story-catalogue/)
6. **Issues / PRs / CI workflow:** [`docs/planning/Delivery-Workflow.md`](docs/planning/Delivery-Workflow.md)
7. **Project board sync:** when starting a story / opening a PR / merging, update **Delivery Game MVP** Status (In Progress → In Review → Done). Details: [`docs/planning/Delivery-Workflow.md`](docs/planning/Delivery-Workflow.md#project-board-sync-agents) and [`.cursor/rules/github-project-board.mdc`](.cursor/rules/github-project-board.mdc).

When documents disagree, follow the precedence in [`docs/README.md`](docs/README.md).

## Product identity

- Internal repo / project name: **delivery-game**
- Player-facing app / ASC name: **Couriers Gambit**
- Bundle ID: `com.amishpatel.couriesgambit.game`
- Xcode project: `delivery-game.xcodeproj`
- Scheme / app target: `delivery-game`
- Unit test target: `delivery-gameTests`
- Team ID: `24CTGGM78R`

## Build & verify

Open `delivery-game.xcodeproj`. Prefer unit tests for acceptance evidence.

```bash
# Unit tests only (pinned simulator used by CI)
xcodebuild \
  -project delivery-game.xcodeproj \
  -scheme delivery-game \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:delivery-gameTests \
  test

# CI-equivalent
PROJECT_FILENAME="delivery-game.xcodeproj" SCHEME="delivery-game" \
  bundle exec fastlane runUnitTests
```

Do **not** add or revive UI test targets. UI tests are out of scope; rely on unit tests for gameplay/domain behaviour.

Story / harness Python checks:

```bash
pip install -r requirements-dev.txt
python3 -m unittest discover -s tests -v
python3 scripts/validate_story_catalogue.py
```

## Architecture principles (lightweight)

- Domain rules (routing, hazards, economy, seeded jobs) stay **pure and unit-testable** — no SwiftUI, no wall-clock time, no unseeded randomness unless injected.
- SwiftUI views **consume** behaviour; they should not own core game rules.
- Prefer small, story-sized PRs that land tests with the behaviour they prove.
- Do not invent architecture sensors/harness unless the same mistake repeats twice.

## Local hooks

```bash
git config core.hooksPath hooks
```

- `hooks/commit-msg` — Conventional Commits subject lines

## Commits & PRs

```text
<type>[optional scope][optional !]: <description>
```

Allowed types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`.

Story implementation:

- Branch: `story/e5-s01-short-slug`
- PR title: `feat(E5-S01): short description`
- PR body must include story ID, `Closes #N`, acceptance/validation/deviations sections, and a catalogue source reference.

Planning / tooling PRs omit story scope, e.g. `ci: tighten TestFlight env vars`.

Prefer **squash merge** into `main`.

**TestFlight What to Test:** before merging work that should ship to testers, update [`fastlane/testing_notes.txt`](fastlane/testing_notes.txt). The `deploy` lane uploads that text as the TestFlight changelog.

## CI map

| Workflow | Purpose |
|---|---|
| `pr-traceability.yml` | Conventional Commit PR titles; story traceability on `story/*` |
| `story-catalogue-validation.yml` | `stories.yml` integrity |
| `pull-request.yml` | Unit tests on ready PRs |
| `merged.yml` | Sign + upload to TestFlight on `main` (app/fastlane paths) |

No GitHub Releases / Versioning action. Marketing version lives in Xcode; build numbers come from TestFlight.

## Secrets (human-managed)

Repository secrets expected by `merged.yml`:

- `DISTRIBUTION_CERTIFICATE` — base64 Apple Distribution `.p12`
- `DISTRIBUTION_PASSWORD` — password for that `.p12`
- `KEY_VALUE` — App Store Connect API `.p8` key contents

Fastlane CI jobs set `LC_ALL=en_US.UTF-8` and `LANG=en_US.UTF-8` (required by Fastlane). Deploy also sets official ASC env vars (`APP_STORE_CONNECT_API_KEY_*`) with `IN_HOUSE=false`.

Provisioning profile name: **Couriers Gambit App Store Profile**.

TestFlight internal group: **`Internal`** (Fastlane `deploy` assigns builds after processing). Prefer also enabling **Automatic distribution** on that group in App Store Connect.
