# Step 2 — Write skills/grimoire-construct-update/SKILL.md

**Goal:** Author the new skill body `skills/grimoire-construct-update/SKILL.md`. This step creates **one new file** only. No code, no TDD — this is skill prose. The conventions amendments from Step 1 are already committed; this body **references** them via `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md` and **never restates** any `§ Construct` / Alteration rule.

**Template to mirror:** `skills/grimoire-construct/SKILL.md` is the closest structural analog (the authoring counterpart). `skills/grimoire-note/SKILL.md` is the precedent for a surgical, incremental editor of an artifact another skill authored — borrow its hard-stop + IDE-aware-review + single-commit shape. Read both before writing.

## Frontmatter (load-bearing — keep `---` delimiters intact)

```
---
name: grimoire-construct-update
description: <one-line: alter an existing construct in place — add/remove/reorder references, edit a reference's detail, edit the construct intro, or rename it; the locked-[specced]-prefix is immutable. Never creates a construct or page, never touches HISTORIC.md/PROJECT.md.>
argument-hint: <e.g. A construct number or <name>, plus the alteration to make>
---
```

Write a real, polished `description` and `argument-hint` in that spirit (match the tone/length of the other skills' frontmatter). Do not leave placeholders.

## Body — phased, mirroring grimoire-construct's structure

Compose a phased body. Suggested phases (adapt names, keep the flow):

1. **[Required Reading]** — Read `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`; name the sections that apply: `§ Construct` (definition, folder layout, `CONSTRUCT.md` format, writer contract, **Alteration rules** — all authored in Step 1), `§ .grimoire/ layout`, `§ Sub-agent spawning` (research for add/edit in sub-agents; orchestrator interviews/resolves/writes), `§ Commits` (`docs(grimoire): update construct <name>`), `§ Pause-point pattern` (resolution hard-stop, locked-`[specced]` refusal, clarifying-questions/operation-selection pause, draft-review pause), `§ Project context` (read `PROJECT.md`; never write it), `§ IDE-aware review`. Mark **not applicable:** `§ TDD`, `§ Historic`, and the Spec → Plan → Execute page lifecycle. State explicitly: **do not restate any `§ Construct` rule — reference it.** Read `.grimoire/PROJECT.md` if present (non-blocking) and `.grimoire/HISTORIC.md` read-only for recency.

2. **[Objective]** — Alter an **existing** construct in place per `§ Construct` Alteration rules. Include the `$ARGUMENTS` substitution verbatim for the user's input (target + requested alteration).

3. **[Hard constraints — orthogonal skill]** — Never write `HISTORIC.md`, never write `PROJECT.md`, never create a page folder, **never create a construct** (that's `grimoire-construct`). The `[specced]` prefix is immutable. Keep the construct flat/self-contained. (Reference `§ Construct`; don't restate the rules.)

4. **[Phase 1: Target Resolution & Precondition Check (HARD STOP)]** — Resolve the input to `.grimoire/constructs/NNN-<name>/` by `NNN` or `<name>`. If it does not exist → hard-stop with the canonical message from `§ Pause-point pattern` (`❌ Construct NNN não existe. Rode /grimoire-construct primeiro.`) and change nothing. Read `CONSTRUCT.md` and identify the `[specced]` prefix vs the `[pending]` tail.

5. **[Phase 2: Research (conditional)]** — For add/edit operations that need codebase or external grounding, spawn research sub-agent(s) per `§ Sub-agent spawning` (equip with `Read`/`Grep`/`Glob`/read-only `Bash`, and `WebSearch`/`WebFetch` when the objective's shape depends on facts outside the repo). For pure structural ops (remove/reorder/rename) that need no research, skip. Orchestrator stays lucid.

6. **[Phase 3: Clarifying Questions / Operation Selection]** — Interview the user to fix the exact operation set (which references, where, new detail text, new name, etc.). Surface research uncertainties. PAUSE per `§ Pause-point pattern`.

7. **[Phase 4: Validate Against the Locked Prefix]** — Before composing, check every requested operation against the locked `[specced]` prefix. Any edit/removal/reorder of a `[specced]` reference, or insertion ahead of one, is **refused** with a message **naming the reference and its page backlink** — no files changed (per `§ Pause-point pattern` / `§ Construct` Alteration rules).

8. **[Phase 5: Compose + Contiguous Renumber + Draft Review]** — Apply the operations to the **pending tail** only: edit `CONSTRUCT.md` (intro and/or checklist), edit/add/remove/reorder `references/N-*.md`, and **renumber the pending tail contiguously** in execution order (specced prefix never moves). For a rename: rename the folder `.grimoire/constructs/NNN-<old>/` → `NNN-<new>/` preserving `NNN`, and fix internal self-references. Present the altered files per `§ IDE-aware review` (write-to-disk + PAUSE in IDE mode; inline fallback otherwise). Handle approval / requested edits / abandonment (on abandonment, restore the construct to its pre-edit state — never leave unapproved changes on disk).

9. **[Phase 6: Commit]** — Single atomic commit per `§ Commits`: `docs(grimoire): update construct <name>`, scoped to the altered construct files **and any rename** (use `git mv` so the rename is tracked). No `HISTORIC.md`, no `PROJECT.md`, no page folder touched.

10. **[Phase 7: Closing]** — Tell the user what changed; if the next `[pending]` reference is ready, remind them they consume it with `/grimoire-spec <NNN>` (the construct number). If `PROJECT.md` was missing, give the non-blocking `grimoire-init` reminder.

11. **[Style / discipline guardrails]** — Operator-facing messages may be pt-BR; construct content + commit messages stay English. **Single source of truth:** all construct/alteration rules live in `GRIMOIRE-CONVENTIONS.md` — reference, never restate.

## Discipline

- Keep the body **referential**, not duplicative — point at the Step 1 sections by name.
- Preserve `$ARGUMENTS` verbatim. Keep frontmatter `---` delimiters and the three keys intact.
- The skill is auto-discovered from `skills/` — no manifest change needed for discovery (the version bump + doc listing happen in Step 3).
- Do **not** touch any file other than the new `skills/grimoire-construct-update/SKILL.md` in this step.

## Commit

Per `§ Commits`, commit this step atomically. Suggested message:
`docs(grimoire): add grimoire-construct-update skill`
