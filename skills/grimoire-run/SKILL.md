---
name: grimoire-run
description: Run a whole construct end to end — spec interviews for pending references first, then autonomous plan → execute → review → PR for every page, in dependency waves with stacked PRs; stops when every PR awaits human review.
argument-hint: Construct (milestone number/title, or NNN/name locally)
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Run` (the single source of truth for everything this skill orchestrates — hard-stops, the interactive phase, the boundary, the page DAG and waves, flat orchestration, the ledger, resume, the watchdog, the stop condition), `§ Review loop` (the per-page protocol every page goes through — page worktree, resume mode, phases, reviewer, rounds, outcome), `§ Parallel execution` (the Kahn-wave algorithm, reused at page level; step waves and the worktree contract inside each page), `§ Construct` (storage per backend, reference status, consumption, `depends-on` between references), `§ Skill composition` (Grimoire-on-Grimoire — invoking `grimoire-spec`), `§ Sub-agent spawning` (roles `plan`, `execute`, `fix`, `review`; the orchestrator never implements), `§ Harness adaptation` (spawn, wait / watch, sibling-skill invocation, watchdog enforcement), `§ Configuration` (role lookup, `[run]`, `[review]`, `[verify]`, `[github]`, `{port}`), `§ Backends` (identifiers, markers, labels, page slug, PR body, base & stacking, `gh` cheat sheet), `§ .grimoire/ layout` (local frontmatter, `bag/runs/`, `bag/worktrees/`), `§ TDD` (including the documented review-gate exception), `§ Code comments`, `§ Commits` (code commits only, on page branches), `§ Documentation`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ IDE-aware review` (this skill presents no draft of its own — the `grimoire-spec` interviews present theirs).
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and `docs/architecture.md`. Sub-agents get pointers, never pasted docs: `plan` → `docs/conventions.md` + `docs/architecture.md`; `execute` → those + `docs/development.md`; `fix` / `review` → `docs/conventions.md` + `docs/development.md`. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` in the summary (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` — resolve the `plan` / `execute` / `fix` / `review` roles through the role lookup order; read `[run]`, `[review]`, `[verify]`, `[github]`; print the one-line `session` notice when it applies.
4. Detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). `[github].mode = "on"` without auth → `❌ GitHub backend required but gh is not authenticated.` and STOP.

**[Objective]**
Run the construct identified by:

$ARGUMENTS

end to end per `§ Run`: first one `grimoire-spec` consumption interview per pending reference (interactive), then — after the `🚀` boundary — plan → execute → review → PR for every runnable page, autonomously, in dependency waves with stacked PRs, until every page is in `review`, `blocked`, or `skipped`. The session agent is a **flat orchestrator** (`§ Sub-agent spawning`): it invokes `grimoire-spec`, spawns every per-page sub-agent itself, runs mechanical git / `gh` commands, watches, and records — it never writes code, plans, reviews, or fixes.

**[Hard constraints]**
- **No question after the `🚀` boundary line** (`§ Run`, `§ Pause-point pattern`). An ambiguity found later becomes a planner assumption or a `blocked` outcome whose `⛔` comment carries the question (`§ Review loop`).
- **Never implement; never nest an orchestrator** inside a sub-agent (`§ Sub-agent spawning`, `§ Run`).
- **Never touch construct objects** — the reference flips belong to `grimoire-spec` (`§ Construct`, writer contract). Never write `docs/`, `PROJECT.md`, or `config.toml` (`§ Documentation`). No state commit (`§ Commits`).
- **The only branch deletion** is the `executing` case of the ledger resume (`§ Run`); otherwise branches remain and PRs are never closed.

**[Phase 1: Resolve, Hard-Stops, Resume Detection]**
Per `§ Run` (hard-stops, resume) and `§ Pause-point pattern` (`grimoire-run`). STOP on the first failure with the literal message; nothing is changed.
1. **Resolve the construct** per `§ Backends` (identifiers) and `§ Construct` (storage per backend). GitHub: the milestone by number (`gh api repos/{owner}/{repo}/milestones/<n>`) or by exact title (`gh api 'repos/{owner}/{repo}/milestones?state=all'`); local: `.grimoire/constructs/NNN-<name>/` by `NNN` or `<name>`. Not found → `❌ Construct N does not exist.` Keep the construct number `<m>` (milestone number / `NNN`) — `grimoire-spec` takes only digits.
2. **Load the construct and its pages.** GitHub: the milestone's `## References` list (the order) + `gh issue list -m <m> -s all --json number,title,labels,state,body --limit 100` (status labels, page-marker headers with `depends-on`). Local: `CONSTRUCT.md`, the `references/*` frontmatter, and the `SPEC.md` frontmatter of every page a specced reference points at (`page:`); legacy pages infer their status per `§ .grimoire/ layout`. Classify every entry: pending reference, or a page in `spec` / `planned` / `blocked` / `review` / closed.
3. **Resume detection.** An unfinished ledger of this construct under `.grimoire/bag/runs/<m>-*.md` (some page not yet terminal — `§ Run`, ledger and resume) → announce `▶ Resuming run <id>` (`<id>` = the ledger's run id) and continue at **[Phase 4]** under the ledger resume rules below. Phase 2 is never re-run — no re-interview; the page set is exactly the ledger's.
4. **Nothing to run** — no pending reference and no runnable page (every page in `review`, closed, or `blocked`) → `❌ Construct N has nothing to run.`, followed by the `blocked` pages, if any, each with the hint to resume it with `/grimoire-execute M`. STOP.

**[Phase 2: Spec Interviews]** — interactive
Per `§ Run` (phase 1) and `§ Pause-point pattern` (`grimoire-run`: Phase 1 pauses). Tell the user once that they may answer "skip the rest" at any interview. Then, for every pending reference in list order:
- Invoke `grimoire-spec <m>` in consumption mode — Grimoire-on-Grimoire per `§ Skill composition` (Claude Code: the `Skill` tool; Codex: read and follow the sibling `grimoire-spec` SKILL.md by path — `§ Harness adaptation`). Its clarifying questions, draft review, and hard-stops apply unchanged; it consumes strictly the first pending reference (`§ Construct`, consumption). Its own closing suggestions are superseded by this run.
- **"Skip the rest"** → stop interviewing: the remaining references stay `reference` and — together with their transitive dependents — are left out of the autonomous phase (`§ Run`). An **abandoned consumption draft** counts as "skip the rest": proceed to Phase 3 with the pages already specced (`§ Run`).
- No pending reference → this phase is empty; go straight to Phase 3.

**[Phase 3: Run Plan & Boundary]**
1. Re-load the construct and its pages (Phase 1 step 2) — the interviews changed statuses.
2. **Page DAG** per `§ Run` (page DAG): nodes, edges from the `depends-on` headers / frontmatter when any page carries one, otherwise the implicit chain in list order; pages in `review` or closed are satisfied dependencies; a `blocked` page is excluded and its transitive dependents are `skipped`, as are the dependents of skipped references.
3. **Validate the page DAG** (`§ Run`, hard-stops) — STOP with the literal message, nothing changed:
   - a cycle between pages → `❌ Construct N has cyclic dependencies between pages. Fix them with /grimoire-construct-update first.`
   - a `depends-on` pointing at a non-existent page → `❌ Construct N references a non-existent page in depends-on. Fix it with /grimoire-construct-update first.`
4. **Waves** — Kahn levels per `§ Parallel execution` (wave construction), applied to pages (`§ Run`). Do not restate the algorithm.
5. **Create the ledger** `.grimoire/bag/runs/<m>-<epoch>.md` (`<epoch>` = `$(date +%s)`; name and run id per `§ Run`, ledger) with the frontmatter and table of `§ Run` (ledger): every node `pending` with its wave, every excluded page `skipped` with a note naming the cause.
6. Print the boundary line — glyph and tokens verbatim, prose localized (`§ User-facing language`): `🚀 Autonomous phase: N pages, K waves — you can leave.` **From here on, no question is asked.**

**[Phase 4: Autonomous Waves]**
Per `§ Run` (phase 2) — orchestrate it, do not restate it. The **[Teardown invariant]** below is in force from the first page worktree on.
- **Waves in increasing order**; inside a wave, start pages concurrently up to `[run].page_parallelism` (default 2; `0` = unlimited; Codex also caps it — `§ Harness adaptation`), starting the next page as a slot frees. A wave starts only when every page of the previous one is terminal or `skipped`.
- **Per page — exactly the `§ Review loop` protocol**, the same one `grimoire-execute` runs for a single page: auto-plan (`plan` role) when the page is in `spec`; base and stacking per `§ Backends` (a dependency not yet integrated → branch from it; the draft PR carries `-m "<milestone title>"`); page branch + page worktree, or resume mode when the branch already exists; steps per `§ Parallel execution` (`execute` role); `git push -u` + draft PR after the first step commit; review rounds (`review` and `fix` roles, verdict comments, `## Review log`); outcome `review` or `blocked` with the `⛔` comment. Local: frontmatter and `REVIEW.md` per `§ .grimoire/ layout`.
- **Flat orchestration.** The session agent spawns every `plan` / `execute` / `fix` / `review` sub-agent of every page itself, per `§ Harness adaptation` (Codex: each prompt starts with `cd <worktree>`), with the docs pointers of `[Required Reading]` step 2; it never implements (`§ Sub-agent spawning`).
- **UI reviews.** `{port}` in `[verify]` → allocate a distinct free port per page and substitute it (`§ Configuration`); no placeholder → serialize UI reviews across pages through the mutex recorded in the ledger, and a port already in use means no browser plus the human-validation note (`§ Review loop`).
- **Ledger.** Rewrite it at **every** transition (`§ Run`, ledger): `pending` → `planning` → `executing k/n` → `reviewing r/R` → `review` | `blocked` | `skipped`, updating `branch`, `base`, `pr`, `updated`, and `note`.
- **Watchdog** per `§ Run`: `[run].step_timeout_minutes` (default 45) per step sub-agent and per `plan` sub-agent, `[run].review_timeout_minutes` (default 30) per review / fix sub-agent. Timeout or crash → **one** retry with a fresh sub-agent fed the failure context; a second failure → the page is `blocked` (label + `⛔` comment on the PR when one exists, otherwise on the issue; local: `status: blocked` + `REVIEW.md`). Check elapsed time whenever the orchestrator wakes; stopping an overdue sub-agent is best-effort (`§ Harness adaptation`).
- **Blocked propagation.** Every `blocked` outcome — rounds exhausted, step failure, watchdog — marks the page's transitive dependents `skipped` in the ledger; independent pages continue (`§ Run`).

**Ledger resume** (entered from Phase 1 step 3) — per `§ Run` (resume), page by page:
- `review`, `blocked`, `skipped` → untouched (a `blocked` page is resumed by the human through `/grimoire-execute N`);
- `pending` → runs normally in its wave; `planning` → planning restarts;
- `executing` → the branch is Grimoire's own, proven by the ledger and never marked ready: first tear down that page's leftover worktrees (`page-<N>/`, `page-<N>-step-*`) per the per-page teardown of `§ Review loop`, then close the draft PR if one exists (`gh pr close <n>`), delete the branch locally and, when a remote exists, remotely (`git push origin --delete <branch>`), then re-execute the page from scratch on a new branch with the same deterministic name `grimoire/<N>-<slug>` — the **only** destructive git operation in the design;
- `reviewing` → the review cycle restarts at round 1 on the existing branch (resume mode of `§ Review loop`).

**[Phase 5: Stop & Summary]**
- **Stop** when every page is in `review`, `blocked`, or `skipped` (`§ Run`, stop). Run the **[Teardown invariant]**.
- **Final summary**: a table `page / PR / state / merge order / pointer to Human validation` — the PR (local: branch + `REVIEW.md`), the final state, the merge order implied by the stacking, and where `## Human validation` lives (PR body / `REVIEW.md`).
- Next steps — never run automatically: `review` → the human reviews and merges, in the stated order; `blocked` → reply on the issue or on the PR, then `/grimoire-execute N`; references left pending → `/grimoire-spec <m>` or a new `/grimoire-run <m>`, which also picks up `skipped` pages once their blockers are resolved (a finished ledger is never resumed — `§ Run`). If `PROJECT.md` was missing, remind the user about `grimoire-init`.

**[Teardown invariant]** — try/finally-shaped, non-negotiable
Per `§ Review loop` (the page worktree), `§ Parallel execution` (unconditional teardown), and `§ Run` (stop). Each page tears down its own worktrees and kills its dev server when its execution ends — approved, `blocked`, failed, timed out, or aborted. Whatever ends the run — the stop condition, an error, or an abort — the cleanup runs: kill every dev server a reviewer started; `git worktree remove --force` every page and step worktree this run created, then a defensive `rm -rf` of any residue under `.grimoire/bag/worktrees/`; verify that `.grimoire/bag/worktrees/` is empty and `git worktree list` shows only the main workspace; report anything that could not be removed. Page branches **remain** (pushed when a remote exists).

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language`; the `❌`, `🚀`, `▶`, `⛔` lines keep their glyphs and literal tokens. Issue, PR, comment, and ledger content stays English.
- **Single source of truth.** `§ Run` and `§ Review loop` own every rule this skill orchestrates — this body references them and never restates them.
