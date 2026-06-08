---
depends-on: [1]
touches:
  - .claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
  - CHANGELOG.md
---

# Step 5 — Version bump + CHANGELOG (release commit)

Cut the release that ships `grimoire-deps`. Bumping `.claude-plugin/plugin.json` on `main` is the release trigger, and CI **fails** unless `plugin.json` and `marketplace.json` versions match AND `CHANGELOG.md` already has a matching section. All three files go in **one commit**.

## Locked decisions

- **New version = `0.9.0`.** Current is `0.8.0`; adding a new skill is a backward-compatible feature → **minor** bump.
- **Versions must match** in `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (CI enforces). Update both.
- **CHANGELOG section is part of THIS commit**, not a follow-up (the release workflow extracts release notes from it).

## Edits to make

1. `.claude-plugin/plugin.json` — set `"version": "0.9.0"`.
2. `.claude-plugin/marketplace.json` — set the plugin entry's `"version": "0.9.0"` (keep it in sync with `plugin.json`).
3. `CHANGELOG.md` — read it first to match the existing section format (the page-002 / 0.8.0 entry is the template). Add a new `0.9.0` section dated **2026-06-08** summarizing: *adds the `grimoire-deps` skill — orthogonal dependency-audit-and-update (security/CVEs, semver risk, ~14-day maturity, supply-chain reputation), ranked IDE-aware report with interactive selection, per-dependency atomic commits gated by the project's build/test with revert-on-failure, and breaking-upgrade handoff to `/grimoire-spec`; never creates pages or touches `HISTORIC.md`.* Match the changelog's existing heading style and bullet voice.

## Process

No tests. After editing, confirm the two version strings are byte-identical (`0.9.0`) and the CHANGELOG has a `0.9.0` section. Do not push or tag — the user/CI owns that.

## Commit

One atomic release commit per `§ Commits`: `chore(release): 0.9.0 — grimoire-deps skill`. Commit `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, and `CHANGELOG.md` together.
