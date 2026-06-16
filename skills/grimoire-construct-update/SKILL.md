---
name: grimoire-construct-update
description: Alter an existing construct in place — add, remove, or reorder references, edit a reference's detail, rewrite the construct intro, or rename it; the locked-[specced]-prefix is immutable. Never creates a construct or page, never touches HISTORIC.md/PROJECT.md.
argument-hint: A construct number or <name>, plus the alteration to make
---

**[Required Reading]**
1. Read `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`. The sections that apply to this skill are: `§ Construct` (the single source of truth for the construct artifact — definition, folder layout, `CONSTRUCT.md` format, writer contract, and the **Alteration rules** subsection that governs every in-place change), `§ .grimoire/ layout` (the `constructs/` folder structure), `§ Sub-agent spawning` (research for add/edit operations runs in sub-agents; the orchestrator stays lucid and owns the interview, resolution, and writes), `§ Skill composition`, `§ Commits` (the `docs(grimoire): update construct <name>` commit), `§ User-facing language`, `§ Pause-point pattern` (the resolution hard-stop, the locked-`[specced]` refusal, the clarifying-questions / operation-selection pause, and the draft-review pause), `§ Project context` (read `PROJECT.md`; never write it), and `§ IDE-aware review` (the draft surface). **Not applicable:** `§ TDD`, `§ Historic`, and the Spec → Plan → Execute page lifecycle do **not** apply — this skill is orthogonal (same family as `grimoire-init` / `grimoire-note` / `grimoire-construct`) and is the construct analog of `grimoire-note`: it writes no page, no `SPEC.md`, and no `HISTORIC.md` entry. **Do not restate any `§ Construct` / Alteration rule in this body — reference it.**
2. If `.grimoire/PROJECT.md` exists in the project root, read it for project context. If it does not exist, proceed without it and, at the end of the run, give the non-blocking reminder to run `grimoire-init` once (per `§ Project context`).
3. If `.grimoire/HISTORIC.md` exists, read it **read-only** for recent-page recency context. Absence is non-blocking — this skill does not write or depend on `HISTORIC.md`.

**[Objective]**
Alter an **existing** construct in place per the `§ Construct` Alteration rules: add, remove, or reorder references in the `[pending]` tail, refine a `[pending]` reference's detail, rewrite the construct intro/objective, or rename the construct (preserving `NNN`). The construct is the roadmap-of-record; this skill keeps it accurate without ever spawning a page or disturbing the work already specced.

User's target + requested alteration:

$ARGUMENTS

**[Hard constraints — orthogonal skill]**
- **Never** write to `.grimoire/HISTORIC.md`. **Never** write to `.grimoire/PROJECT.md`. **Never** create a page folder under `.grimoire/pages/`.
- **Never create a construct** — bringing a construct into existence belongs to `grimoire-construct`. This skill only alters one that already exists, and hard-stops otherwise (see Phase 1).
- The `[specced]` prefix is **immutable** and the construct stays **flat and self-contained** — these are the `§ Construct` Alteration rules and self-containment guarantees; do not restate them here, enforce them.

**[Phase 1: Target Resolution & Precondition Check (HARD STOP)]**
Resolve the user's input to an existing `.grimoire/constructs/NNN-<name>/` folder — by the `NNN` number or by the `<name>`. List `.grimoire/constructs/` and match. If the target does not exist, STOP immediately, creating or changing nothing, with the canonical message from `§ Pause-point pattern`:

> ❌ Construct NNN does not exist. Run /grimoire-construct first.

Do **not** offer to run `grimoire-construct` automatically; do **not** create the folder. Once resolved, read `CONSTRUCT.md` and identify the **locked `[specced]` prefix** (the leading `1..k` references, lowest-numbered) versus the **`[pending]` tail** (`k+1..n`). Every alteration in the following phases is confined to that pending tail (or to construct-level metadata), per `§ Construct` Alteration rules.

**[Phase 2: Research (conditional)]**
For add/edit operations that need codebase or external grounding (e.g. a new reference whose shape depends on how the project is structured, or a refined detail that must reflect an established external convention), spawn research sub-agent(s) per `§ Sub-agent spawning` so the orchestrator's context stays lucid. Equip each sub-agent with `Read`, `Grep`, `Glob`, read-only `Bash`, and — when the alteration's shape depends on facts outside the repo — `WebSearch` / `WebFetch`. The sub-agent returns its findings plus an explicit list of anything it was uncertain about (these become questions for Phase 3). For pure structural operations (remove, reorder, rename) that need no grounding, **skip this phase** — do not spawn a sub-agent gratuitously.

**[Phase 3: Clarifying Questions / Operation Selection]**
Per `§ Pause-point pattern` (`grimoire-construct-update` — clarifying-questions / operation-selection pause), interview the user to fix the **exact operation set**: which references are added, removed, or reordered; where in the pending tail; the new detail text; the new intro; the new name. Surface any research uncertainties from Phase 2 here. PAUSE for the answers and iterate to consensus on the operation set before composing anything.

**[Phase 4: Validate Against the Locked Prefix]**
Before composing, check every requested operation against the locked `[specced]` prefix. Per `§ Construct` Alteration rules, any edit, removal, or reorder of a `[specced]` reference — or an insertion **ahead of** a `[specced]` one — is **refused**. Per `§ Pause-point pattern` (`grimoire-construct-update` — locked-`[specced]`-operation refusal), the refusal message **names the reference and its page backlink**, e.g.:

> ❌ Reference 2 has already been specified (page 007) — it cannot be edited, removed, or reordered.

No files are changed when an operation is refused. If a partially-valid operation set mixes legal pending-tail changes with an illegal prefix change, refuse the illegal part and confirm with the user whether to proceed with the legal remainder before composing.

**[Phase 5: Compose + Contiguous Renumber + Draft Review]**
Apply the approved operations to the **pending tail** only:
- Edit `CONSTRUCT.md`: the intro/objective/arc (for an intro rewrite) and/or the affected one-line checklist entries.
- Add / remove / reorder / edit the `references/N-<short-name>.md` detail files for the pending references involved.
- **Renumber the pending tail contiguously** in execution order after any structural change, per `§ Construct` Alteration rules. The `[specced]` prefix **never moves** — its file numbers and page backlinks are never disturbed.
- For a **rename**: rename the folder `.grimoire/constructs/NNN-<old>/` → `.grimoire/constructs/NNN-<new>/` **preserving `NNN`**, and fix any internal self-references to the old name. Use `git mv` so the rename is tracked (see Phase 6).

Present the altered files for review per `§ IDE-aware review`:
- **IDE detected:** write the altered files to their **final paths** (including the renamed folder) so the IDE surfaces them with markdown preview. Tell the user in one short line which files are open and what answer you're waiting for.
- **Terminal-only fallback:** present the altered content inline in chat.

PAUSE per `§ Pause-point pattern` (`grimoire-construct-update` — draft review). Wait for explicit approval, requested edits, or abandonment.
- **On approval:** proceed to Phase 6 (files are already at their final paths in IDE mode).
- **On requested edits:** re-apply the composition with the corrections and re-pause.
- **On abandonment:** restore the construct to its **pre-edit state** — revert every altered file (and undo any folder rename) to its committed `HEAD` content — never leave unapproved changes on disk.

**[Phase 6: Commit]**
Commit per `§ Commits`: a single atomic `docs(grimoire): update construct <name>` commit covering the altered construct files (`CONSTRUCT.md`, affected `references/` files) **and any rename** (use `git mv` so the folder rename and its internal self-reference edits are tracked together). One commit per run. No `HISTORIC.md`, no `PROJECT.md`, and no page folder are touched — if any unrelated file is dirty in the working tree, do not include it; warn the user and let them stage it separately.

**[Phase 7: Closing]**
- Tell the user what changed (the operations applied and the resulting pending-tail order).
- If the next `[pending]` reference is ready to consume, remind the user they expand it into a real page with `/grimoire-spec <NNN>` (the bare construct number). **Do not run it automatically** — consumption is a separate, user-initiated step.
- If `.grimoire/PROJECT.md` was missing in `[Required Reading]`, give the non-blocking reminder that running `grimoire-init` once would enrich future runs.

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language` (English source strings, rendered in the user's native language at runtime). Construct content and commit messages stay English.
- **Single source of truth.** All construct and alteration rules live in `GRIMOIRE-CONVENTIONS.md § Construct` — this body references them and never restates them.
