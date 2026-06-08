# 004 — Construct: large-objective container above the page

## Context

Grimoire's unit of work is the **page** — a single feature/change tracked through Spec → Plan → Execute. Some objectives are too large to fit one page: greenfield projects starting from zero, or very large features that would otherwise sprawl across an unmanageable spec. Today the only response is "split it yourself into many `/grimoire-spec` runs" with no connective tissue between them and no record of the larger arc.

This page introduces the **construct**: a path toward a larger objective, decomposed into an *ordered list of reference-seeds*, where each reference is later expanded — through the normal full spec interview — into one real page. The construct is the roadmap-of-record; the pages it spawns are the actual work.

Research confirms this is the established shape for the "too big for one unit" case. Kiro, GitHub Spec Kit, and BMAD all favor a flat ordered sequence of specs over deep epic→story→task trees, and the GSD skill family (present in this environment) implements the same idea as `ROADMAP.md` → ordered phases. The construct deliberately stays a **flat, ordered, self-contained** container rather than growing nested sub-structures.

> Note on this page's own size: adding the construct concept touches several skills and docs, so it is a large page that `grimoire-plan` will break into multiple step files. It is *not itself* promoted to a construct — it is one coherent feature with a fixed definition, which is exactly the boundary a page is meant to hold.

## Goals

- Introduce **construct** as a first-class Grimoire artifact: a larger-than-a-page objective decomposed into ordered reference-seeds.
- Add a **new skill `grimoire-construct`** that researches, interviews the user, and generates a construct: a `constructs/NNN-<name>/` folder containing `CONSTRUCT.md` and a `references/` folder of detail files in execution order.
- Add a **size-evaluation pause-point to `grimoire-spec`**: after analyzing the request, if it is judged too large for a single page, recommend creating a construct. On user approval, write a handoff brief (the best possible prompt to feed `grimoire-construct`) and STOP — instructing the user to start a fresh, clean-context session and run `/grimoire-construct` with it.
- Add a **construct-consumption mode to `grimoire-spec`**: when the skill's input is *only a number*, resolve it against `constructs/`, take the next `[pending]` reference in execution order, run the **full spec interview** seeded by that reference, and produce a normal page — then flip that reference's status to `[specced]` in `CONSTRUCT.md` (with a backlink to the new page's `NNN`).
- Keep the construct **self-contained**: the construct itself never gets a `HISTORIC.md` entry; only the real pages it spawns do, each noting its parent construct.
- Add a single source-of-truth **`§ Construct`** to `GRIMOIRE-CONVENTIONS.md` and wire every affected skill/doc to it.

## Non-goals

- **No nested or hierarchical constructs.** A construct is a flat ordered list of reference-seeds. No construct-of-constructs, no sub-references.
- **No re-evaluation of a reference's size at consumption time.** References are authored page-sized by `grimoire-construct`; `grimoire-spec` does not re-run the size gatekeeper when consuming a reference.
- **No out-of-order or user-pick consumption in v1.** Consumption is strictly the next `[pending]` reference. (Recorded in Open questions as a possible future extension.)
- **No automatic session handoff.** `grimoire-spec` cannot launch a clean session itself; it writes the brief and instructs the user. The actual `/grimoire-construct` run is a separate, user-initiated session.
- **No editing of construct content by `grimoire-spec`** beyond the single in-place reference-status flip. Authoring/rewriting construct files belongs to `grimoire-construct` only.
- **No migration of existing pages** into constructs. Existing pages are unaffected.
- **No `PROJECT.md` writes** by either the new skill or the new spec paths.

## Scope

**New file:**
- `skills/grimoire-construct/SKILL.md` — the new skill (frontmatter `name`, `description`, `argument-hint`; body following the established skill phase structure with `[Required Reading]` → research → clarifying questions → NNN resolution → draft review → finalize → commit).

**Modified — skill bodies:**
- `skills/grimoire-spec/SKILL.md`:
  - New input-mode detection step at the top: input that is *only digits* (e.g. `42` / `042`) → construct-consumption mode; any other input → new-page mode (existing behavior).
  - New size-evaluation pause-point in the new-page path (after codebase analysis): recommend a construct when the request is too large; on approval write the handoff brief and STOP without creating a page; on decline proceed as a normal large page.
  - New construct-consumption path: resolve construct `NNN`; hard-stop errors when the construct does not exist or all references are already `[specced]` ("finished"); otherwise seed the full spec interview with the next `[pending]` reference, produce the page through the normal phases, then flip that reference to `[specced]` in `CONSTRUCT.md` and commit that change atomically.

**Modified — conventions (single source of truth):**
- `GRIMOIRE-CONVENTIONS.md`:
  - **New `§ Construct`**: folder layout (`.grimoire/constructs/NNN-<name>/` with `CONSTRUCT.md` + `references/N-<name>.md`); `CONSTRUCT.md` format including the ordered reference checklist with `[pending]`/`[specced]` statuses and per-reference page backlinks; consumption rules (strictly-next-in-order; not-found and all-specced error semantics); the writer contract (only `grimoire-construct` creates/authors construct files; `grimoire-spec` may only flip a reference's status in place — analogous to the in-place HISTORIC status flips done by plan/execute); self-containment (no HISTORIC entry for the construct); the size-evaluation trigger and handoff-brief contract.
  - **Amend `§ .grimoire/ layout`**: document `constructs/` alongside `pages/`, and the construct folder's internal structure.
  - **Amend `§ Commits`**: construct-creation commit (`docs(grimoire): construct <name>`); the reference-status-flip commit done by spec on consumption (e.g. `chore: mark reference N specced in construct <name>`).
  - **Amend `§ Pause-point pattern`**: `grimoire-spec` size-evaluation pause + the two construct-consumption hard-stops (not-found, finished); `grimoire-construct` clarifying-questions and draft-review pauses.
  - **Amend `§ Project context`** writer note: add `grimoire-construct` to the list of skills that never write `PROJECT.md`.
  - **Amend `§ Sub-agent spawning`** if `grimoire-construct` uses research sub-agents (orchestrator stays lucid; research runs in sub-agents).

**Modified — project docs:**
- `CLAUDE.md` — update the skill count ("nine skills" → "ten skills"), add the `grimoire-construct` bullet to the skills list, extend the "page" vocabulary section to introduce "construct", and note `constructs/` in the layout summary.
- README(s) — add `grimoire-construct` to the documented skill set and describe the construct flow.
- `CHANGELOG.md` + `.claude-plugin/plugin.json` — version bump (minor) and changelog entry; update the manifest description if it enumerates skills.

## Acceptance criteria

- A new `skills/grimoire-construct/SKILL.md` exists with valid frontmatter and a body that: reads required conventions + `PROJECT.md`/`HISTORIC.md` (read-only), performs research, interviews the user with pause-points, resolves the construct `NNN` by scanning `constructs/`, writes `CONSTRUCT.md` + ordered `references/N-<name>.md` files, presents them for IDE-aware draft review, and commits with `docs(grimoire): construct <name>`. It never writes `HISTORIC.md` or `PROJECT.md`.
- `CONSTRUCT.md` contains an ordered reference list where each entry carries a status (`[pending]`/`[specced]`), a short description, and a path to its `references/N-<name>.md` detail file.
- `grimoire-spec` with an input that is **only a number** enters consumption mode:
  - Non-existent construct → clear error, no page created.
  - All references `[specced]` (finished) → clear error, no page created.
  - Otherwise → the next `[pending]` reference seeds a **full** spec interview, a normal page is produced through the existing Spec phases (folder, `SPEC.md`, two commits, `HISTORIC.md` entry that names the parent construct), and that reference is flipped to `[specced]` in `CONSTRUCT.md` with a backlink to the new page `NNN`, in its own atomic commit.
- `grimoire-spec` with **free-text** input behaves exactly as before, plus the new size-evaluation step: a too-large request triggers a recommendation; on approval a handoff brief is written to `.grimoire/bag/drafts/construct-brief-<epoch>.md` and the run STOPS without creating a page; on decline the run proceeds as a normal page.
- The construct never appears in `HISTORIC.md`; its progress is readable solely from `CONSTRUCT.md`.
- `GRIMOIRE-CONVENTIONS.md` has a new `§ Construct`, and all dependent `[Required Reading]` blocks reference it. No construct rules are duplicated inside SKILL.md bodies.
- `CLAUDE.md`, README(s), `CHANGELOG.md`, and `plugin.json` are updated consistently (skill count, skill list, vocabulary, layout, version).

## Constraints

- Conventions are the single source of truth — the new `§ Construct` holds the load-bearing rules; SKILL.md bodies reference it via `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md` and must not restate them.
- Preserve skill-invocation substitutions verbatim (`$ARGUMENTS`, `$1`, `${CLAUDE_PLUGIN_ROOT}`) and the frontmatter contract (`name`, `description`, `argument-hint`, leading `---`).
- Construct `NNN` is an independent counter scanned from `constructs/`; it does not share or collide with the `pages/` counter.
- Bare-number detection must be unambiguous: input matching only digits (with optional leading zeros) is consumption mode; everything else is a new-page request.
- Commits are atomic, Conventional Commits in English, per `§ Commits`.
- IDE-aware review (VSCode extension detected) for all draft surfaces; terminal-only inline fallback preserved.
- The handoff brief persists (not auto-deleted) because a *different, clean-context session* must consume it.

## Open questions

- **Handoff brief lifecycle:** confirm the brief at `.grimoire/bag/drafts/construct-brief-<epoch>.md` is never auto-deleted, and whether `grimoire-construct` should delete it after successfully creating the construct (recommend: yes, clean up on success).
- **Reference status vocabulary:** `[pending]`/`[specced]` proposed. Should there be a third state for "page finished" (would require construct to observe page completion, which breaks self-containment — recommend NO; keep it binary at the construct level).
- **Out-of-order / user-pick consumption:** explicitly deferred to a future page; confirm it is acceptable to ship v1 as strictly-next-in-order.
- **Reference file naming:** `references/N-<short-name>.md` mirroring step-file numbering — confirm.

## References

- `GRIMOIRE-CONVENTIONS.md` — `§ .grimoire/ layout`, `§ Commits`, `§ Historic`, `§ Project context`, `§ Pause-point pattern`, `§ IDE-aware review`, `§ Sub-agent spawning` (all amended or extended by this page).
- `skills/grimoire-spec/SKILL.md` — the skill gaining input-mode detection, size-evaluation, and construct-consumption.
- `skills/grimoire-init/SKILL.md`, `skills/grimoire-note/SKILL.md`, `skills/grimoire-deps/SKILL.md` — sibling orthogonal skills whose structure `grimoire-construct` should mirror (research/interview/draft-review/commit, no pipeline-state writes).
- `CLAUDE.md` — skill roster, "page" vocabulary, layout summary.
- Prior art: [Kiro specs](https://kiro.dev/docs/specs/), [Spec Kit / Kiro / BMAD comparison](https://medium.com/@visrow/comprehensive-guide-to-spec-driven-development-kiro-github-spec-kit-and-bmad-method-5d28ff61b9b1), [Martin Fowler — Exploring SDD tools](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html); in-environment precedent: the GSD `ROADMAP.md` → ordered-phases model.
