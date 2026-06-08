---
depends-on: [1]
touches:
  - README.md
  - README.pt-BR.md
---

# Step 4 — Document `grimoire-deps` in both READMEs (bilingual)

Document the new skill in the user-facing docs. Docs are bilingual: `README.md` (English) and `README.pt-BR.md` (Portuguese — Brazil). Both must be kept in parity.

## Edits to make

1. Read both `README.md` and `README.pt-BR.md` first to learn the existing format for documenting a skill (table row, section, command list — match whatever pattern the other orthogonal skills like `grimoire-know` / `grimoire-update` / `grimoire-note` use).
2. Add `grimoire-deps` to **`README.md`** in the same place/format the other skills are listed and described. Describe it as the dependency-audit-and-update skill: detects ecosystems, scores security (CVEs)/semver/maturity/reputation, ranked report for interactive selection, per-dependency atomic commits gated by the project's build/test (revert on failure), and breaking-upgrade handoff to `/grimoire-spec`. Note it is orthogonal (writes no pages, no `HISTORIC.md`, no `PROJECT.md`).
3. Mirror the exact same addition in **`README.pt-BR.md`**, translated to PT-BR, in the corresponding location. Keep the two files structurally in parity — same sections, same order.

## Process

Markdown-only; no tests. After editing, diff the two files mentally: the new skill must appear in both, in the same structural slot, English vs PT-BR.

## Commit

One atomic commit per `§ Commits`: `docs(grimoire): document grimoire-deps in READMEs`. Commit only `README.md` and `README.pt-BR.md`.
