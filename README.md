# delivery-game

iOS delivery route-planning game (MVP). Product docs live under [`docs/`](docs/README.md).

## Local setup

```bash
# Story / CI Python tooling
pip install -r requirements-dev.txt

# Conventional Commit hook (once per clone)
git config core.hooksPath hooks

# Fastlane (CI + local deploy helpers)
bundle install
```

## Conventions

- **Commits and PR titles** use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
- Story PRs: `feat(E5-S01): short description` on branch `story/e5-s01-…`.
- Prefer squash merges into `main`.
- **Unit tests only** — no UI test target.
- Agent map: [`AGENTS.md`](AGENTS.md)
- See [`docs/planning/Delivery-Workflow.md`](docs/planning/Delivery-Workflow.md) for CI and TestFlight secrets.

## TestFlight

On merge to `main` (app/fastlane paths), `.github/workflows/merged.yml` builds and uploads to TestFlight via Fastlane. No GitHub Releases. Update [`fastlane/testing_notes.txt`](fastlane/testing_notes.txt) before shipping a playtest build.

Release readiness (signing, groups, tester instructions, known limitations): [`docs/planning/validation/TestFlight-Release.md`](docs/planning/validation/TestFlight-Release.md).
