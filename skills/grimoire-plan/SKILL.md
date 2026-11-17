---
name: grimoire-plan
description: Plan a page with Grimoire, interactively — reads the page SPEC (GitHub issue or local SPEC.md), asks about what is still unclear, and writes the step plan as a plan comment on the issue (label grimoire:planned) or as local step files. Optional — /grimoire-execute auto-plans a page that has no plan.
argument-hint: Page number (e.g. 42)
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Backends` (identifiers, labels, plan-comment format, local cache, `gh` cheat sheet), `§ .grimoire/ layout` (page folder, step files, status frontmatter), `§ Parallel execution` (step frontmatter, DAG, waves), `§ TDD` and `§ Code comments` (the steps you write are executed under them), `§ Sub-agent spawning` (this skill plans **in the session** — the `plan` role is the auto-planner of `grimoire-execute`, not this skill), `§ Harness adaptation`, `§ Configuration`, `§ Documentation`, `§ Skill composition`, `§ Commits` (this skill commits **nothing**), `§ IDE-aware review`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ Review loop`, `§ Run`, `§ Construct` — this skill never touches construct objects.
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and `docs/architecture.md`. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` at the end (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice).
4. Detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). `[github].mode = "on"` without auth → `❌ GitHub backend required but gh is not authenticated.` and STOP.

**[Objective]**
Plan the implementation of the page identified by:

$ARGUMENTS

This is the **interactive** planner: use it when the user wants to steer the plan. Without it, `grimoire-execute` auto-plans the page with no interview.

**[Phase 1: Page Resolution & Precondition Check (HARD STOP)]**
Per `§ Pause-point pattern` (`grimoire-plan`: precondition check). Run these checks **before** anything else; STOP on the first failure with the literal message.

1. **Parse the page number** per `§ Backends` (identifiers): the issue number on GitHub (`42` or `#42`); `NNN` locally (`42` and `042` both resolve). Reject anything else.
2. **Load the page.** GitHub: `gh issue view <n> --json number,title,body,labels,milestone,state,comments`. Local: glob `.grimoire/pages/NNN-*/` and read the `SPEC.md` status frontmatter (legacy pages without frontmatter: infer the status per `§ .grimoire/ layout`).
   - No such page → `❌ Page N does not exist. Run /grimoire-spec first.`
   - GitHub only — the issue exists but its body lacks the page marker → `❌ Issue N is not managed by Grimoire. Run /grimoire-adopt N first.`
   - Still a reference (label `grimoire:reference`) → `❌ Page N has not been specified yet. Run /grimoire-spec first.`
   - Local only — the folder has no `SPEC.md` → `❌ Page N has no SPEC.md. Run /grimoire-spec first.`
   - `planned` and a page branch matching `grimoire/<n>-*` already exists (locally or on the remote — `§ Backends`, page slug), or a local page with `status: blocked` → `❌ Page N is already being executed (branch <branch>).` `planned` with **no** branch → print a one-line notice that the page will be re-planned and continue.
   - In `review` → GitHub: `❌ Page N is already pending human review (PR #X).` — local: `❌ Page N is already pending human review (branch <branch>).`
   - Closed (local: `status: done`) → `❌ Page N has already been finished.`
   - `spec` → proceed.
3. **Load the SPEC** in full (the issue body / `SPEC.md`).

Never offer to run another skill automatically and never silently fix the state.

**[Phase 2: Analysis & Clarification]**
- Analyze the codebase architecture relative to what the SPEC requires; identify the best practices for this implementation.
- Per `§ Pause-point pattern` (unclear requirements): if an acceptance criterion is still ambiguous, or a critical architectural decision is needed that the SPEC did not lock in, ask before planning. The SPEC's `## Open questions` are the natural starting point.

**[Phase 3: Planning, Scope & Context Management]**
- You are entirely responsible for the scope of the execution. Project the token usage and context size each step will need — the goal is maximum context lucidity per executor.
- **Output shape:** sequential step files `1-<step>.md`, `2-<step>.md`, … (`§ .grimoire/ layout`). A simple page has one step file; a larger page has several small, cohesive steps. Never rename, move, or create the page itself — choose only the step count and names.
- **Inter-step dependencies (opt-in).** Only when some steps are genuinely independent, emit `depends-on` / `touches` frontmatter per `§ Parallel execution`; when every step builds on the previous one, emit none (strict serial is the default).
- **DAG validation before anything is written:** build the DAG, refuse cycles and dangling references, compute the waves, and flag `touches` overlaps between siblings as advisory warnings — all per `§ Parallel execution`. A broken graph is fixed by revising the breakdown, never written.
- **Assumptions.** Every decision taken without the user's explicit confirmation is recorded for the plan's `## Assumptions` (`§ Backends`, plan comment; locally `PLAN.md` — `§ .grimoire/ layout`).
- **Final clarity check** per `§ Pause-point pattern`: self-review the breakdown; if any architectural choice, step boundary, or tradeoff still rests on a silent assumption, PAUSE and ask (question tooling per `§ Harness adaptation`). When frontmatter will be emitted, also present the full DAG — each step's `depends-on`, the waves (e.g. `Wave 0: {1}`, `Wave 1: {2, 3}`), and the `touches` warnings — so the user can veto the parallelization (force serial, change deps, change boundaries).

**[Phase 4: Draft Review]**
Compose the step files — frontmatter (when the approved DAG requires it) + the markdown body the executor follows — and present them per `§ IDE-aware review`:
- **GitHub:** the throwaway draft `.grimoire/bag/drafts/plan-<epoch>.md`, holding the full plan comment in the `§ Backends` format — marker line, `## Assumptions`, one `<details><summary>Step K — <name></summary>` block per step containing the step file verbatim, frontmatter included.
- **Local:** `PLAN.md` (marker line, `## Assumptions`, step overview — `§ .grimoire/ layout`) and the step files, at their final destination in `.grimoire/pages/NNN-<slug>/`. On a re-plan, first back the existing `PLAN.md` + step files up to `.grimoire/bag/drafts/plan-backup-<epoch>/` (the backup pattern of `§ IDE-aware review`, step 7), then overwrite them; abandonment restores them from the backup, approval deletes it. `SPEC.md` is not touched yet.
- Terminal-only → inline.

PAUSE per `§ Pause-point pattern` (draft review) until approved. Edits → revise in place and re-pause. Abandonment → delete what the draft created (`§ IDE-aware review`).

**[Phase 5: Write]** — no commit (`§ Commits`)
- **GitHub:** post the plan comment with `gh issue comment <n> -F <draft>` (on a re-plan the newest plan comment wins); ensure the `grimoire:planned` label and swap `grimoire:spec` → `grimoire:planned` in one `gh issue edit` (`§ Backends`, labels; a re-plan is already `grimoire:planned`); write the local cache `.grimoire/pages/<n>-<slug>/K-<step>.md` from the approved step files — `<slug>` per `§ Backends` (page slug), reusing an existing `pages/<n>-*` folder — replacing any previous cache (`§ Backends`, local cache); delete the draft.
- **Local:** `PLAN.md` and the step files are already in place (inline fallback: write them now; re-plan: delete the backup); set `status: planned` in the `SPEC.md` frontmatter (stamping the full frontmatter on a legacy page — `§ .grimoire/ layout`).

**[Phase 6: Closing]**
Tell the user the next step: `/grimoire-execute <n>`. Never run it automatically. If `PROJECT.md` was missing, remind the user about `grimoire-init`.
