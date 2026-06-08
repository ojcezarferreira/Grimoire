---
depends-on: [1]
touches:
  - skills/grimoire-construct/SKILL.md
---

# Step 2 — Create the `grimoire-construct` skill

Create the new skill `skills/grimoire-construct/SKILL.md`: it researches a larger-than-a-page objective, interviews the user, and writes a **construct** — a `.grimoire/constructs/NNN-<name>/` folder with `CONSTRUCT.md` and an ordered `references/` folder. It is **orthogonal** to the Spec → Plan → Execute pipeline (same family as `grimoire-init`, `grimoire-note`, `grimoire-deps`): it never writes `HISTORIC.md` or `PROJECT.md`, and never creates a page.

> **Depends on Step 1.** The skill body references `§ Construct` (and the amended `§ .grimoire/ layout`, `§ Commits`, `§ Pause-point pattern`, `§ Project context`, `§ Sub-agent spawning`) from `GRIMOIRE-CONVENTIONS.md`. Do **not** restate those rules — reference them via `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`.

> **TDD note:** markdown-only artifact (no code, no tests — see `.grimoire/PROJECT.md` → Tech Stack). Verification is structural consistency with the sibling skills and the conventions. Follow `§ Commits`.

## Required reading before writing

- `GRIMOIRE-CONVENTIONS.md` — especially the new `§ Construct` and the amended sections from Step 1.
- `.grimoire/pages/004-construct-concept/SPEC.md`.
- Sibling orthogonal skills to mirror structure (research/interview/NNN-resolution/draft-review/commit, no pipeline-state writes):
  - `skills/grimoire-init/SKILL.md`
  - `skills/grimoire-note/SKILL.md`
  - `skills/grimoire-deps/SKILL.md`
  - `skills/grimoire-spec/SKILL.md` (for the `[Required Reading]` block style and NNN-resolution idioms).

## Locked decisions (adopt verbatim)

- Reference detail files are named `references/N-<short-name>.md`.
- Construct `NNN` is an independent counter scanned from `.grimoire/constructs/` (zero-padded 3 digits), not shared with `pages/`.
- Reference status is binary `[pending]` / `[specced]`; the skill authors all references as `[pending]`.
- After successfully creating the construct, **delete** the handoff brief at `.grimoire/bag/drafts/construct-brief-<epoch>.md` **if one was passed / present** (it is the brief that seeded this run). Do not fail if no brief is present (the skill can be invoked directly).

## Frontmatter (load-bearing — exact contract)

```
---
name: grimoire-construct
description: <one-line: research + interview → a construct (ordered reference-seeds toward a large objective) under .grimoire/constructs/NNN-<name>/>
argument-hint: <e.g. "[objective or path to a construct brief]">
---
```

Preserve the leading `---` delimiters. Use `${CLAUDE_PLUGIN_ROOT}` for sibling-file references and preserve `$ARGUMENTS` / `$1` verbatim where used.

## Body structure (mirror the established skill phase shape)

1. **`[Required Reading]`** block:
   - Read `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md` — call out `§ Construct`, `§ .grimoire/ layout`, `§ Commits`, `§ Pause-point pattern`, `§ Project context`, `§ Sub-agent spawning`, `§ IDE-aware review` as load-bearing.
   - Read `.grimoire/PROJECT.md` if present (project context); if missing, proceed and suggest `grimoire-init` at the end (per `§ Project context`).
   - Read `.grimoire/HISTORIC.md` if present (read-only recency context). Absence is non-blocking — this skill does not write or depend on HISTORIC.
   - **If invoked with a handoff brief** (path or pasted content from a prior `grimoire-spec` size-evaluation), read it as the seed of the objective.

2. **`[Objective]`** — turn the user's large objective (or the handoff brief) into a flat, ordered list of page-sized reference-seeds, and persist it as a construct.

3. **Phase: Research** — per `§ Sub-agent spawning`, run research in sub-agent(s) so the orchestrator stays lucid. Analyze the codebase and (when relevant) the web for the established shape of the objective; each reference must be sized to fit one normal page.

4. **Phase: Clarifying questions** (pause-point) — per `§ Pause-point pattern` (`grimoire-construct` clarifying questions): ask the user only what cannot be inferred (scope boundaries, ordering, what's in/out, the decomposition granularity). Iterate to consensus on the ordered reference list.

5. **Phase: NNN resolution** — scan `.grimoire/constructs/` for existing `NNN-*` folders; the new construct's `NNN` is `max(existing) + 1`, zero-padded to 3 digits, starting at `001` if none. Choose a kebab-case `<name>`.

6. **Phase: Compose & draft review** (pause-point) — compose:
   - `CONSTRUCT.md` per the format in `§ Construct`: intro/objective + the ordered reference checklist (every entry `[pending]`, short description, path to `references/N-<short-name>.md`, empty backlink).
   - one `references/N-<short-name>.md` per reference, each a focused seed describing what that future page must deliver (enough for `grimoire-spec` to run a full interview from it).
   Present them for review per `§ IDE-aware review` (write to the final paths so the IDE surfaces them; PAUSE for approval/edits). On abandonment, delete the unapproved files.

7. **Phase: Finalize & commit** — on approval, the files are already at their final paths. Commit per `§ Commits`: `docs(grimoire): construct <name>`. Then, if a handoff brief seeded this run, delete `.grimoire/bag/drafts/construct-brief-<epoch>.md`.

8. **Closing** — tell the user how to consume the construct: run `/grimoire-spec <NNN>` (bare number) to expand the next `[pending]` reference into a page. (Do not run it automatically.)

## Hard constraints (call out explicitly in the body)

- **Never** writes `HISTORIC.md`. **Never** writes `PROJECT.md`. **Never** creates a page folder under `.grimoire/pages/`.
- Authoring/rewriting construct files belongs to this skill only; `grimoire-spec` may only flip a reference status in place (per `§ Construct` writer contract).
- IDE-aware review for the draft surface; terminal-only inline fallback preserved.

## Acceptance for this step

- `skills/grimoire-construct/SKILL.md` exists with valid frontmatter (`name`, `description`, `argument-hint`, leading `---`).
- Body covers: required reading (incl. `§ Construct`), research-in-sub-agents, clarifying-questions pause, `NNN` resolution scanning `constructs/`, compose `CONSTRUCT.md` + ordered `references/N-<short-name>.md`, IDE-aware draft review pause, `docs(grimoire): construct <name>` commit, and handoff-brief cleanup on success.
- It explicitly states it never writes `HISTORIC.md`/`PROJECT.md` and never creates a page.
- No construct rules are restated — they are referenced from `GRIMOIRE-CONVENTIONS.md`.

## Commit

One commit for this step: `feat(grimoire): add grimoire-construct skill`.
