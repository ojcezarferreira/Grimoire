---
depends-on: [1]
touches:
  - GRIMOIRE-CONVENTIONS.md
---

# Step 2 — Register `grimoire-deps` in `GRIMOIRE-CONVENTIONS.md` enumerations

Add the new orthogonal skill to the enumerations in `GRIMOIRE-CONVENTIONS.md` so the conventions acknowledge it. This is **enumerations only** — no new load-bearing rule.

## Locked decision (do not deviate)

- **Do NOT touch `§ TDD`.** The dependency-bump exception to the filter-only rule is documented in the `grimoire-deps` skill body (Step 1), not here. The user explicitly chose "skill body only." Adding a `§ TDD` carve-out is out of scope for this step.

## Edits to make

1. **Intro paragraph (top of file).** The opening line enumerates the workflow skills (`grimoire-init`, `grimoire-spec`, `grimoire-plan`, `grimoire-execute`, `grimoire-quick`). `grimoire-deps` is **orthogonal** (not part of Spec → Plan → Execute), so add it to the enumeration the same way the other orthogonal skills are referenced — match how `grimoire-know` / `grimoire-note` / `grimoire-update` are listed in the surrounding prose, if present. Keep the edit minimal and consistent with the existing wording.
2. **`§ Project context` — dual-writer / "all other skills" list.** The bullet reading *"All other skills (`grimoire-spec`, `grimoire-plan`, `grimoire-execute`, `grimoire-quick`, `grimoire-know`, `grimoire-update`) never write `PROJECT.md` at all"* must include **`grimoire-deps`**. Add it to that parenthesized list.
3. Scan the rest of the file for any other closed enumeration of "all the skills" / "the orthogonal skills" and add `grimoire-deps` where it belongs, matching existing phrasing. Do **not** add `grimoire-deps` to any list that is specifically about pipeline skills or page-lifecycle writers (it writes no pages).

## Process

Markdown-only; no tests. After editing, re-read the changed lines to confirm `grimoire-deps` appears in the orthogonal/"all other skills" enumerations and that `§ TDD` is unchanged.

## Commit

One atomic commit per `§ Commits`: `docs(grimoire): register grimoire-deps in conventions enumerations`. Commit only `GRIMOIRE-CONVENTIONS.md`.
