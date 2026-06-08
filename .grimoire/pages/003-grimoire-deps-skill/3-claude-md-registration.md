---
depends-on: [1]
touches:
  - CLAUDE.md
---

# Step 3 — Describe `grimoire-deps` in `CLAUDE.md`

Add the new skill to the maintainer-facing `CLAUDE.md` so the repo's own documentation reflects it. `CLAUDE.md` is **not** loaded for end users, but it is the maintainer's map of the plugin.

## Edits to make

1. **"What this repo is" / skill-count line.** The intro says the plugin bundles "**eight** skills" and lists the `skills/<name>/SKILL.md` paths. Increment the count and add [skills/grimoire-deps/SKILL.md](skills/grimoire-deps/SKILL.md) to that path list. (Verify the current count in the file and bump it by one rather than assuming the number.)
2. **"The skills and how they connect" section.** Add a bullet for **`grimoire-deps`** modeled on the existing `grimoire-know` / `grimoire-update` / `grimoire-note` bullets: describe it as an **orthogonal** skill (outside Spec → Plan → Execute) that audits the consuming project's dependencies across four axes (security/CVEs, semver risk, maturity/"baking time" ≈14 days, reputation/supply-chain), produces a ranked IDE-aware report for interactive selection, applies safe updates as **one atomic commit per dependency** gated by the project's broader test/build (reverting that dependency on failure), and routes breaking upgrades to `/grimoire-spec` via an ephemeral upgrade brief. State plainly: **never creates pages, never writes `HISTORIC.md` or `PROJECT.md`.**

## Process

Markdown-only; no tests. After editing, re-read the changed sections to confirm the skill count is consistent and the new bullet matches the orthogonal-skill framing of its neighbors.

## Commit

One atomic commit per `§ Commits`: `docs(grimoire): describe grimoire-deps in CLAUDE.md`. Commit only `CLAUDE.md`.
