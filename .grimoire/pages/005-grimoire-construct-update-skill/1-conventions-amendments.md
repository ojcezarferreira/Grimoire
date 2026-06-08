# Step 1 — Amend GRIMOIRE-CONVENTIONS.md (single source of truth)

**Goal:** Make `GRIMOIRE-CONVENTIONS.md` the single source of truth for the new `grimoire-construct-update` skill **before** the skill body (Step 2) references it. This step edits **only** `GRIMOIRE-CONVENTIONS.md`. No code, no TDD — this is prose. Conventional Commit in English.

This is the foundation step: Step 2 (the SKILL.md body) will reference the section anchors and the new Alteration-rules subsection authored here, and must never restate them. Get the wording right and self-consistent here.

## Context you need (already established in SPEC.md)

`grimoire-construct-update` is a new **orthogonal** skill — the **second authorized writer** of construct files (the first is `grimoire-construct`, which *authors from scratch*; `grimoire-spec` may only flip one reference `[pending]`→`[specced]` on consumption). It alters an **existing** construct in place: it never creates a construct, never spawns a page, never touches `HISTORIC.md`/`PROJECT.md`. It is the construct analog of `grimoire-note`.

The dominant safety property is the **locked `[specced]` prefix**: because `grimoire-spec` always consumes the lowest-numbered `[pending]` reference, `[specced]` references form an immutable leading prefix (`1..k` specced, `k+1..n` pending). Every alteration is confined to the `[pending]` tail (or construct-level metadata).

## Edits to make (4 amendments)

All four edits are in `GRIMOIRE-CONVENTIONS.md`. Read each target section in full before editing so the new prose dovetails with the existing wording.

### 1. `§ Construct` — extend the writer contract + add an "Alteration rules" subsection

In the **Writer contract** subsection of `§ Construct`, add `grimoire-construct-update` as the **second authorized author/rewriter** of construct files. Make explicit:
- `grimoire-construct` creates and authors a construct from scratch (unchanged).
- `grimoire-construct-update` alters an **existing** construct in place; it **never creates** one and hard-stops if the target does not exist.
- `grimoire-spec` still makes exactly its one in-place status flip (unchanged).
- "All other skills never touch construct files" stays true.

Then add a new **"Alteration rules"** subsection inside `§ Construct` (place it logically — after the writer contract, near the consumption/self-containment rules). It must state, as the single source of truth:
- **Locked `[specced]` prefix invariant.** `[specced]` references are immutable: they cannot be edited, removed, or reordered, and **no new reference may be inserted ahead of a `[specced]` one**. The invariant follows directly from lowest-pending-first consumption: the specced refs are a leading prefix, so editing the tail keeps every spawned page traceable and never orphaned.
- **Permitted operations**, all confined to the `[pending]` tail (or construct-level metadata):
  - **Structural** — add reference(s) (append, or insert at a position **within the pending tail**), remove `[pending]` reference(s), reorder `[pending]` references.
  - **Edit reference detail** — refine a `[pending]` reference's `references/N-<short-name>.md` body and its one-line `CONSTRUCT.md` checklist entry.
  - **Edit construct intro/objective** — rewrite the `CONSTRUCT.md` header/intro/arc (not the reference list).
  - **Rename the construct** — change `<name>` of `.grimoire/constructs/NNN-<name>/` (and internal self-references), **preserving `NNN`**.
- **Contiguous renumbering of the pending tail.** After any structural change, `references/N-*.md` files and the `CONSTRUCT.md` checklist are renumbered to stay contiguous and in execution order. The **specced prefix never moves**, so its file numbers and page backlinks are never disturbed. (Pending refs carry empty backlinks, so backlink rewrites never fire in practice.)
- **Rename preserves `NNN`.** Only `<name>` changes on a rename; the independent construct counter `NNN` is stable.
- **Resolution / hard-stop.** The target construct is resolved from the input by `NNN` number or `<name>`; if it does not exist, hard-stop (operator-facing message + pause-point live in `§ Pause-point pattern`, do not duplicate the message string here — reference it).

### 2. `§ Commits` — add the update-construct commit line

Add a line to `§ Commits` defining the single atomic commit for this skill:
`docs(grimoire): update construct <name>` — covers the altered construct files (`CONSTRUCT.md`, affected `references/` files) **and any rename** (the folder rename + internal self-reference edits). One commit per run; no page-state commits. Mirror the phrasing style of the existing `docs(grimoire): construct <name>` line for `grimoire-construct`.

### 3. `§ Sub-agent spawning` — add a `grimoire-construct-update` clause

Add a clause (alongside the existing `grimoire-construct` / orthogonal-skill clauses) stating: for `grimoire-construct-update`, any needed codebase/external **research for add/edit operations runs inside sub-agent(s)** so the orchestrator stays lucid; the **orchestrator** interviews the user, resolves the operation set, and performs the writes itself. Keep it consistent with how `grimoire-construct`'s research clause is phrased.

### 4. `§ Pause-point pattern` — add the `grimoire-construct-update` pauses

Add `grimoire-construct-update` entries to `§ Pause-point pattern`:
- **target-construct-resolution hard-stop:** `❌ Construct NNN não existe. Rode /grimoire-construct primeiro.` (operator-facing pt-BR per project precedent, matching the existing hard-stop message style). Resolve the input to `.grimoire/constructs/NNN-<name>/` first; if missing, STOP and create/change nothing. Never offer to run `grimoire-construct` automatically.
- **locked-`[specced]`-operation refusal:** when the user requests an edit/removal/reorder of a `[specced]` reference, or an insertion ahead of one, **refuse** with a message **naming the reference and its page backlink** — no files changed. (Word the rule here; the exact message can be illustrative.)
- **clarifying-questions / operation-selection pause:** after resolving the target and (optionally) running research, interview the user to fix the operation set; PAUSE for answers before composing.
- **draft-review pause:** after composing the altered `CONSTRUCT.md` and affected `references/` files, present them per `§ IDE-aware review` and PAUSE for approval / edits / abandonment.

## Discipline

- **Single source of truth:** every rule above lives **only** here. Step 2's SKILL.md body will *reference* these sections and must not restate them. Make the anchors and subsection name (`Alteration rules`) clear so the SKILL.md can point at them cleanly.
- Operator-facing message strings stay pt-BR per project precedent; rule prose stays English.
- Do **not** touch any other file in this step.

## Commit

Per `§ Commits`, commit this step atomically. Suggested message:
`docs(grimoire): add construct-update rules to conventions`

(This is a step-file commit, separate from the Phase 6 HISTORIC update which `grimoire-plan` already handled. Do not touch `HISTORIC.md` in this step.)
