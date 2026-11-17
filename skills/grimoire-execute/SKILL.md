---
name: grimoire-execute
description: Execute a page with Grimoire — auto-plans it when it has no plan, runs every step in sub-agents inside an isolated page worktree and branch, opens a draft PR, and drives automated review rounds (scope, code review, full test/build/lint gate, UI check) until the PR is ready for human review (label grimoire:review) or the page is blocked with the way back. GitHub backend (issue + PR) or local (branch + REVIEW.md); resumes blocked or interrupted pages. Asks no questions.
argument-hint: Page number (e.g. 42)
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Review loop` (the single source of truth for everything this skill orchestrates — page worktree, hard-stops, resume mode, phases, reviewer, rounds, outcome), `§ Parallel execution` (step DAG, waves, worktree contract, failure semantics), `§ Sub-agent spawning` (roles `plan`, `execute`, `fix`, `review`; the orchestrator never implements), `§ Harness adaptation`, `§ Configuration` (role lookup, `[verify]`, `[review]`, `[github]`, `{port}`), `§ Backends` (identifiers, markers, labels, PR body, base & stacking, local cache, `gh` cheat sheet), `§ .grimoire/ layout`, `§ TDD` (including the documented review-gate exception), `§ Code comments`, `§ Commits` (code commits only, on the page branch), `§ Skill composition`, `§ Documentation`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ IDE-aware review` (this skill presents no draft), `§ Construct` (construct objects are never touched — only a page's `depends-on` is read), `§ Run` (standalone execution of one page).
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and `docs/architecture.md`. Sub-agents get pointers, never pasted docs: `plan` → `docs/conventions.md` + `docs/architecture.md`; `execute` → those + `docs/development.md`; `fix` / `review` → `docs/conventions.md` + `docs/development.md`. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` in the summary (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` — resolve the `plan` / `execute` / `fix` / `review` roles through the role lookup order; read `[verify]`, `[review]`, `[github]`; print the one-line `session` notice when it applies.
4. Detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). `[github].mode = "on"` without auth → `❌ GitHub backend required but gh is not authenticated.` and STOP.

**[Objective]**
Take the page identified by:

$ARGUMENTS

from `spec` or `planned` (or `blocked`) to a pull request waiting for human review — or to `blocked` with the way back — per `§ Review loop`. The session agent is a pure **orchestrator** (`§ Sub-agent spawning`): it dispatches sub-agents, runs mechanical git / `gh` commands, watches, and records; it never writes code, plans, reviews, or fixes itself. This skill **asks the user nothing**: the auto-plan has no interview, and from the draft PR on any ambiguity becomes a planner assumption or a `blocked` outcome whose `⛔` comment carries the question (`§ Pause-point pattern`).

**[Phase 1: Resolve, Hard-Stops, Resume Detection]**
Per `§ Review loop` (phase 1, hard-stops) and `§ Pause-point pattern` (`grimoire-execute`: precondition check). STOP on the first failure with the literal message; nothing is changed.

1. **Parse the page number** per `§ Backends` (identifiers): the issue number on GitHub (`42` or `#42`); `NNN` locally (`42` and `042` both resolve).
2. **Load the page.** GitHub: `gh issue view <n> --json number,title,body,labels,milestone,state,comments` (the SPEC is the issue body, never cached). Local: glob `.grimoire/pages/NNN-*/`, read `SPEC.md` and its status frontmatter (legacy pages: infer the status per `§ .grimoire/ layout`).
   - No such page → `❌ Page N does not exist.`
   - GitHub only — the issue exists but its body lacks the page marker → `❌ Issue N is not managed by Grimoire. Run /grimoire-adopt N first.`
   - Still a reference → `❌ Page N has not been specified yet. Run /grimoire-spec first.`
   - Local only — no `SPEC.md` → `❌ Page N has no SPEC.md. Run /grimoire-spec first.`
   - In `review` → GitHub: `❌ Page N is already pending human review (PR #X).` — local: `❌ Page N is already pending human review (branch <branch>).`
   - Closed → `❌ Page N has already been finished.`
3. **Check the page's `depends-on`** (page-marker header / `SPEC.md` frontmatter). For each dependency `M`:
   - never executed (`spec` / `planned`, no branch) → `❌ Page N depends on #M, which has not been executed yet. Run /grimoire-execute M first (or /grimoire-run <construct>).`
   - `blocked` → `❌ Page N depends on #M, which is blocked. Resume it with /grimoire-execute M first.`
4. **Load the plan** when the page is `planned` / `blocked`: GitHub — the latest plan comment; re-materialize the cache `.grimoire/pages/<n>-<slug>/K-<step>.md` from it when absent or stale (the comment always wins — `§ Backends`, local cache; folder found by the prefix `pages/<n>-*`, else named per `§ Backends`, page slug); local — `PLAN.md` and the step files. Build the step DAG per `§ Parallel execution` and select the mode (strict serial when no step declares `depends-on`; waves otherwise):
   - cyclic → `❌ Page N has cyclic dependencies between steps. Run /grimoire-plan N to fix.`
   - dangling → `❌ Page N references a non-existent step in depends-on. Run /grimoire-plan N to fix.`
5. **Resume detection** (`§ Review loop`, resume mode). When a page branch matching `grimoire/<N>-*` already exists (locally or on the remote — `§ Backends`, page slug) — a `blocked` page, an interrupted execution, another machine — announce `▶ Resuming page N on existing branch <branch>` and enter resume mode: look up the PR (`gh pr list --head <branch> --state all --json number,state,mergedAt`) and collect the **new human comments** on the issue and on the PR — newer than the last Grimoire-authored comment, as `§ Backends` (verdict comment) defines; locally the whole `NOTES.md` of the page folder is that input (`§ .grimoire/ layout`). A `blocked` page is never a hard-stop.

**[Phase 2: Auto-Plan]** — only when the page is in `spec`
Per `§ Review loop` (phase 2). Spawn one `plan` sub-agent (`§ Sub-agent spawning`, `§ Harness adaptation`) with the SPEC, its docs pointers, and the step-file schema of `§ Parallel execution`. It plans **without an interview**: every unresolved choice goes into `## Assumptions`; `touches` overlaps between parallel siblings become a note in the plan. It writes the step files — locally into `.grimoire/pages/NNN-<slug>/` together with `PLAN.md` (`§ .grimoire/ layout`), on GitHub into the cache folder `.grimoire/pages/<n>-<slug>/` (`<slug>` per `§ Backends`, page slug) — and returns the assumptions. Then, in the orchestrator:
- validate the DAG again (defense in depth) — the cycle / dangling hard-stops of Phase 1 step 4 apply;
- **GitHub:** assemble the plan comment in the `§ Backends` format from those files (marker, `## Assumptions`, one `<details>` block per step, frontmatter included), post it with `gh issue comment <n> -F <file>`, ensure the label and swap `grimoire:spec` → `grimoire:planned`;
- **local:** set `status: planned` in the `SPEC.md` frontmatter.

A user who wants to steer the plan runs `/grimoire-plan <N>` beforehand — never suggest it mid-run.

**[Phase 3: Page Branch & Worktree]**
Per `§ Review loop` (the page worktree). **The user's working tree never changes branch.**
- **Fresh execution:** compute the base per `§ Backends` (base branch and stacking — default branch on GitHub / the branch checked out in the main workspace locally; the last non-integrated dependency's branch when stacking, merging the other non-integrated ones with `git merge --no-edit`). Create the branch `grimoire/<N>-<slug>` (`§ Backends`, page slug) from it and the page worktree `.grimoire/bag/worktrees/page-<N>/` on it. Local: record `branch`, `base`, and `phase: steps` in the `SPEC.md` frontmatter.
- **Resume:** check the existing branch out into the page worktree. With a draft PR (local: `phase: review`) → skip Phase 4; the review cycle drives the remaining work. With **no** draft PR (local: `phase: steps` or absent) — the previous execution died in the middle of the steps → `git reset --hard <base>` on the page branch and run Phase 4 from scratch — the only history rewrite this skill performs (`§ Review loop`, resume mode).
- Run `[verify].install_command` once in the page worktree, before any test or dev server.
- From here on, **[Teardown invariant]** below is in force.

**[Phase 4: Steps]**
Per `§ Parallel execution` — orchestrate it, do not restate it.
- **Strict serial** (no `depends-on`): one `execute` sub-agent per step file in numeric order, each working directly in the page worktree; never start step `K+1` before step `K` has completed.
- **Waves** (`depends-on` present): for each wave in increasing order — skip-filter steps whose dependencies transitively failed; create the step worktrees `.grimoire/bag/worktrees/page-<N>-step-<K>/` from the page worktree's `HEAD`; spawn one `execute` sub-agent per step concurrently; wait for the whole wave to settle (no mid-wave kill); cherry-pick the successful steps' commits into the **page worktree** in step-number order; tear the wave's step worktrees down before the next wave.
- **Every `execute` prompt** names its step file, its worktree (Codex: the prompt starts with `cd <worktree>` — `§ Harness adaptation`), its docs pointers, and requires `§ TDD`, `§ Code comments`, `§ Commits`, with all edits and commits confined to that worktree.
- **After the first step commit reaches the page branch:** `git push -u origin <branch>`, then open the draft PR — `gh pr create --draft -B <base> -H <branch> -t "<issue title>" -F pr.md` (plus `-m "<milestone title>"` when the page belongs to a construct), body per the `§ Backends` PR template (`Closes #N`, `## Plan` linking the plan comment). Keep the remote branch current after each later step or wave. Local: push when a remote exists; no PR. **From the draft PR on, no question is asked.**
- **A failed step** follows the failure semantics of `§ Parallel execution`: the remaining independent work still runs, the page skips Phase 5 and ends `blocked` in Phase 6, with the `⛔` comment listing the failed and skipped steps.

**[Phase 5: Review Cycle]**
Per `§ Review loop` (the reviewer; rounds, fixer, outcome): rounds `r = 1..[review].max_rounds` (default 3). Local: set `phase: review` in the `SPEC.md` frontmatter when round 1 starts. On resume the cycle restarts at round 1, `grimoire:blocked` is removed (local: `status: blocked` → `planned`) when the round starts, and the round opens with the **fixer** when unresolved blocking findings or new human comments exist.
- **Reviewer** — one fresh `review` sub-agent per round, in the page worktree, **instructed never to edit code**. Inputs per `§ Review loop`: the SPEC, the plan with `## Assumptions` (local: `PLAN.md`), `git diff <base>...<branch>`, the PR number, the new human comments (local: `NOTES.md`), `[verify]`, `[review].ui_globs`. Checks in the `§ Review loop` order: (a) scope, (b) `ponytail-review`, (c) the full `test_command` + `build_command` + `lint_command` gate (the `§ TDD` exception), (d) UI — only when a changed file matches `ui_globs`. For (d) the orchestrator allocates a free port and substitutes `{port}` into `[verify].dev_command` / `dev_url`; the reviewer starts a **fresh** dev server in the page worktree (never one already answering), uses `agent-browser`, `impeccable`, `revenue-centric-design` and the project's own design system per `§ Review loop` and `§ Skill composition`, saves screenshots under `.grimoire/bag/reviews/page-<N>/round-<r>/`, and kills the server when done. Its report ends with the verdict block of `§ Review loop`.
- **Record the verdict:** GitHub — post the report as a PR comment whose line 1 is `<!-- grimoire:verdict round=<r> -->` (`gh pr comment <pr> -F review.md`); local — append it to `REVIEW.md` in the page folder.
- **`changes-requested`** with rounds left → spawn a fresh `fix` sub-agent in the page worktree (no step worktree) with the SPEC, the plan, the blocking **and** advisory findings, and the new human comments; it commits atomically per `§ Commits` and pushes. Next round.
- **`approve`** → the reviewer has written the PR body sections `§ Review loop` assigns it (`gh pr edit <pr> --body-file pr.md`); run `gh pr ready <branch>`, ensure the label and swap the status to `grimoire:review` (removing `grimoire:blocked` if present). Local: `REVIEW.md` holds the same sections; `status: review`.
- **Rounds exhausted** → ensure and add `grimoire:blocked` (it coexists with `grimoire:planned`); the PR stays draft; post the `⛔` comment of `§ Review loop` — unresolved blocking findings **and** the way back, `/grimoire-execute N` — on the PR (`gh pr comment`). Local: `status: blocked` + the same block in `REVIEW.md`.

**[Phase 6: Final State, Teardown, Summary]**
- Final state per `§ Review loop` (phase 6): `review` or `blocked` — GitHub: labels + PR state; local: `REVIEW.md` + the `SPEC.md` frontmatter. A step failure writes its `⛔` comment on the PR when one exists, otherwise on the issue (`gh issue comment`). No state commit; nothing else is written.
- Run the **[Teardown invariant]**.
- Summary to the user: page, branch, PR link (local: branch + `REVIEW.md`), final state, rounds used, steps finished / failed / skipped, and where `## Human validation` lives. Next step: `review` → the human reviews and merges the PR (stacked PRs: merge in the order stated there); `blocked` → reply on the issue or on the PR, then `/grimoire-execute N` resumes. If `PROJECT.md` was missing, remind the user about `grimoire-init`.

**[Teardown invariant]** — try/finally-shaped, non-negotiable
Per `§ Parallel execution` (unconditional teardown) and `§ Review loop` (the page worktree). Whatever ends the execution — approval, `blocked`, a failed step, a hard-stop raised after Phase 3, an error, or an abort — the cleanup runs:
- kill any dev server the reviewer started;
- `git worktree remove --force` every step worktree and the page worktree this run created, then a defensive `rm -rf` of any residue under `.grimoire/bag/worktrees/`;
- verify that `.grimoire/bag/worktrees/` is empty and `git worktree list` shows only the main workspace; report anything that could not be removed so the user can clear it by hand.

The page branch **remains** (pushed when a remote exists). **This skill never deletes a branch and never closes a PR** (`§ Review loop`).
