---
name: grimoire-construct
description: Research + interview a larger-than-a-page objective into a construct — an ordered list of reference-seeds toward that objective — under .grimoire/constructs/NNN-<name>/.
argument-hint: An objective too large for one page, or a path to a construct brief
---

**[Required Reading]**
1. Read `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`. The sections that apply to this skill are: `§ Construct` (the single source of truth for the construct artifact — definition, folder layout, `CONSTRUCT.md` format, writer contract, self-containment), `§ .grimoire/ layout` (the `constructs/` folder structure), `§ Sub-agent spawning` (research runs in sub-agents; the orchestrator stays lucid), `§ Commits` (the `docs(grimoire): construct <name>` commit), `§ User-facing language`, `§ Pause-point pattern` (the clarifying-questions and draft-review pauses), `§ Project context` (read `PROJECT.md`; never write it), and `§ IDE-aware review` (the draft surface). **Not applicable:** `§ TDD`, `§ Historic`, and the Spec → Plan → Execute page lifecycle do **not** apply — this skill is orthogonal (same family as `grimoire-init` / `grimoire-note` / `grimoire-deps`) and writes no page, no `SPEC.md`, and no `HISTORIC.md` entry. **Do not restate any `§ Construct` rule in this body — reference it.**
2. If `.grimoire/PROJECT.md` exists in the project root, read it for project context. If it does not exist, proceed without it and, at the end of the run, suggest the user run `grimoire-init` once to enrich future runs (non-blocking per `§ Project context`).
3. If `.grimoire/HISTORIC.md` exists, read it read-only for recent-page recency context. Absence is non-blocking — this skill does not write or depend on `HISTORIC.md`.
4. **If invoked with a handoff brief** — a path to (or pasted content of) a `.grimoire/bag/drafts/construct-brief-<epoch>.md` written by `grimoire-spec`'s size-evaluation pause — read it as the seed of the objective. Memorize its exact path for the Phase 6 cleanup.

**[Objective]**
Turn the user's larger-than-a-page objective (or the seeding handoff brief) into a **construct**: a flat, ordered list of page-sized reference-seeds persisted under `.grimoire/constructs/NNN-<name>/`, per `§ Construct`. Each reference is a focused seed that `grimoire-spec` will later expand — through its normal full interview — into one real page. The construct is the roadmap-of-record; the pages it spawns are the actual work.

User's objective (or handoff-brief path / content):

$ARGUMENTS

**[Hard constraints — orthogonal skill]**
- **Never** write to `.grimoire/HISTORIC.md`. **Never** write to `.grimoire/PROJECT.md`. **Never** create a page folder under `.grimoire/pages/`.
- Authoring and rewriting construct files (`CONSTRUCT.md` and the `references/` detail files) belongs to **this skill only**. `grimoire-spec` may only flip a single reference's status in place when it consumes one — never author. This is the `§ Construct` writer contract; do not duplicate it here.
- Keep the construct **flat and self-contained** per `§ Construct`: no nested constructs, no sub-references, no `HISTORIC.md` entry for the construct itself.

**[Phase 1: Research]**
Per `§ Sub-agent spawning`, run the research inside sub-agent(s) so the orchestrator's context stays lucid. The orchestrator stays in charge of the interview, the `NNN` resolution, and the construct writes.
- Brief each research sub-agent with a self-contained prompt naming the objective (or the handoff brief's content) and the project context from `PROJECT.md`. Equip it with `Read`, `Grep`, `Glob`, read-only `Bash`, and — when the objective's established shape depends on facts outside the repo — `WebSearch` / `WebFetch`.
- The research goal is the **decomposition**: analyze the codebase (and, when relevant, the established external shape of the objective) to propose a flat, ordered list of reference-seeds where **each reference is sized to fit one normal page**. A reference too big to spec in one page interview must be split; trivial slivers should be merged.
- The sub-agent returns the proposed ordered reference list (each with a short description and the rationale for its size/ordering) plus an explicit list of anything it was uncertain about. Do not invent facts — uncertainties become questions for Phase 2.

**[Phase 2: Clarifying Questions]**
Per `§ Pause-point pattern` (`grimoire-construct` — clarifying questions), interview the user about only what cannot be inferred from the codebase or the handoff brief: scope boundaries (what's in / deliberately out), the execution ordering of the references, and the decomposition granularity (how finely to split). Surface the research sub-agent's uncertainties here. PAUSE for the answers and iterate to consensus on the ordered reference list before authoring anything.

**[Phase 3: NNN Resolution & Construct Name]**
- List `.grimoire/constructs/` (if it exists). Extract the integer `N` from each `NNN-*` subfolder name. Choose `max(N) + 1`, zero-padded to 3 digits (`NNN`). If the folder is empty or does not exist, use `001`. This counter is **independent** of `.grimoire/pages/` per `§ .grimoire/ layout` — it does not share or collide with the page counter.
- Choose `<name>` in short, descriptive kebab-case (2–5 words) that reads meaningfully on its own. The final folder is `.grimoire/constructs/NNN-<name>/`.

**[Phase 4: Compose & Draft Review]**
- Compose the construct files per the `§ Construct` format:
  - `CONSTRUCT.md` at the construct root: a header/intro describing the larger objective (purpose, the arc, relevant research findings), followed by the **ordered reference checklist**. Author **every** entry as `[pending]` with its one-line description, the path to its `references/N-<short-name>.md` detail file, and an **empty** page backlink (backlinks are filled later by `grimoire-spec` on consumption). Follow the exact entry format defined in `§ Construct`.
  - One `references/N-<short-name>.md` per reference (`1-...md`, `2-...md`, … in execution order). Each is a focused seed describing what that future page must deliver — enough detail for `grimoire-spec` to run a full spec interview from it (intent, scope hints, constraints, acceptance signals).
- Present the composed files for review per `§ IDE-aware review`:
  - **IDE detected:** create `.grimoire/constructs/NNN-<name>/` (and its `references/` subfolder) and write all files to their **final paths** so the IDE surfaces them with markdown preview. Tell the user in one short line which files are open and what answer you're waiting for.
  - **Terminal-only fallback:** present the composed content inline in chat.
- PAUSE per `§ Pause-point pattern` (`grimoire-construct` — draft review). Wait for explicit approval, requested edits, or abandonment.
  - **On approval:** proceed to Phase 5 (files are already at their final paths in IDE mode).
  - **On requested edits:** re-apply the composition with the corrections and re-pause.
  - **On abandonment:** delete the unapproved files (the `CONSTRUCT.md`, the `references/` files, and the construct folder) — never leave an uncommitted, unapproved construct on disk.

**[Phase 5: Finalize & Commit]**
- **IDE mode:** the approved files are already at their final paths under `.grimoire/constructs/NNN-<name>/`. No additional write is needed.
- **Inline fallback:** create the construct folder and `references/` subfolder, then write the approved `CONSTRUCT.md` and all `references/N-<short-name>.md` files.
- Commit per `§ Commits`: `docs(grimoire): construct <name>`. This single commit covers the new `CONSTRUCT.md` and all its `references/` detail files. No `HISTORIC.md` and no `PROJECT.md` are touched.

**[Phase 6: Handoff-Brief Cleanup]**
- If a handoff brief seeded this run (a `.grimoire/bag/drafts/construct-brief-<epoch>.md` passed in or read in `[Required Reading]`), delete it now — it was the throwaway prompt that fed this construct, and per `§ Construct` `grimoire-construct` cleans it up on success.
- If no brief seeded the run (the skill was invoked directly), there is nothing to delete — do **not** fail or warn.

**[Phase 7: Closing]**
- Tell the user how to consume the construct: run `/grimoire-spec <NNN>` with the bare construct number to expand the next `[pending]` reference into a real page through the normal full spec interview. **Do not run it automatically** — consumption is a separate, user-initiated step.
- If `.grimoire/PROJECT.md` was missing in `[Required Reading]`, remind the user (non-blocking) that running `grimoire-init` once would enrich future runs.

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language` (English source strings, rendered in the user's native language at runtime). Construct content and commit messages stay English.
- **Single source of truth.** All construct rules live in `GRIMOIRE-CONVENTIONS.md § Construct` — this body references them and never restates them.
