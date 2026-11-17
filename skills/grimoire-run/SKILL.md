---
name: grimoire-run
description: Run a whole construct end to end — spec interviews for pending references first, then autonomous plan → execute → review → PR for every page, in dependency waves with stacked PRs; stops when every PR awaits human review.
argument-hint: Construct (milestone number/title, or NNN/name locally)
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Run` (the single source of truth for everything this skill orchestrates — hard-stops, Phase 1, the boundary, Phase 2, the page DAG and waves, flat orchestration, the ledger, resume, the watchdog, the stop condition), `§ Review loop` (the per-page protocol every page goes through — page worktree, resume mode, phases, reviewer, rounds, outcome), `§ Parallel execution` (the Kahn-wave algorithm, reused at page level; step waves and the worktree contract inside each page), `§ Construct` (storage per backend, reference status, consumption, `depends-on` between references), `§ Skill composition` (Grimoire-on-Grimoire — invoking `grimoire-spec`), `§ Sub-agent spawning` (roles `plan`, `execute`, `fix`, `review`; the orchestrator never implements), `§ Harness adaptation` (spawn, wait / watch and the deadline wake-up, sibling-skill invocation, watchdog enforcement), `§ Configuration` (role lookup, `[run]`, `[review]`, `[verify]`, `[github]`, `{port}`), `§ Backends` (identifiers, markers, labels, page slug, PR body, base & stacking, `gh` cheat sheet), `§ .grimoire/ layout` (local frontmatter, `bag/runs/`, `bag/worktrees/`), `§ TDD` (including the documented review-gate exception), `§ Code comments`, `§ Commits` (code commits only, on page branches), `§ Documentation`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ IDE-aware review` (this skill presents no draft of its own — the `grimoire-spec` interviews present theirs).
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and `docs/architecture.md`. Sub-agents get pointers, never pasted docs: `plan` → `docs/conventions.md` + `docs/architecture.md`; `execute` → those + `docs/development.md`; `fix` / `review` → `docs/conventions.md` + `docs/development.md`. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` in the summary (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` — resolve the `plan` / `execute` / `fix` / `review` roles through the role lookup order; read `[run]`, `[review]`, `[verify]`, `[github]`; print the one-line `session` notice when it applies.
4. Detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). `[github].mode = "on"` without auth → `❌ GitHub backend required but gh is not authenticated.` and STOP.

**[Objective]**
Run the construct identified by:

$ARGUMENTS

end to end per `§ Run`: Phase 1 — one `grimoire-spec` consumption interview per pending reference (interactive); then, after the `🚀` boundary, Phase 2 — plan → execute → review → PR for every runnable page, autonomously, in dependency waves with stacked PRs, until every page is in `review`, `blocked`, `skipped`, or `done`. The session agent is a **flat orchestrator** (`§ Sub-agent spawning`): it invokes `grimoire-spec`, spawns every per-page sub-agent itself, runs mechanical git / `gh` commands, watches, and records — it never writes code, plans, reviews, or fixes. Phase numbers below are those of `§ Run`.

**[Hard constraints]**
- **No question after the `🚀` boundary line** (`§ Run`, `§ Pause-point pattern`). An ambiguity found later becomes a planner assumption or a `blocked` outcome whose `⛔` comment carries the question (`§ Review loop`).
- **Never implement; never nest an orchestrator** inside a sub-agent (`§ Sub-agent spawning`, `§ Run`).
- **Never touch construct objects** — the reference flips belong to `grimoire-spec` (`§ Construct`, writer contract). Never write `docs/`, `PROJECT.md`, or `config.toml` (`§ Documentation`). No state commit (`§ Commits`).
- **The only branch deletion** is the `executing` case of the ledger resume (`§ Run`); otherwise branches remain and PRs are never closed.

**[Phase 0: Resolve, Hard-Stops, Resume Detection]**
Per `§ Run` (hard-stops, ledger, resume) and `§ Pause-point pattern` (`grimoire-run`). STOP on the first failure with the literal message; nothing is changed.
1. **Resolve the construct** per `§ Backends` (identifiers) and `§ Construct` (storage per backend). GitHub: the milestone by number (`gh api repos/{owner}/{repo}/milestones/<n>`) or by exact title (`gh api 'repos/{owner}/{repo}/milestones?state=all'`); local: `.grimoire/constructs/NNN-<name>/` by `NNN` or `<name>`. Not found → `❌ Construct N does not exist.` Keep the construct number `<m>` (milestone number / zero-padded `NNN`) — `grimoire-spec` takes only digits, and the ledger is named by it.
2. **Load the construct and its pages.** GitHub: the milestone's `## References` list (the order) + `gh issue list -m <m> -s all --json number,title,labels,state,body --limit 100` (status labels, page-marker headers with `depends-on`). Local: `CONSTRUCT.md`, the `references/*` frontmatter, and the `SPEC.md` frontmatter of every page a specced reference points at (`page:`); legacy pages infer their status per `§ .grimoire/ layout`. Classify every entry: pending reference, or a page and the ledger state it would enter with (`§ Run`, ledger).
3. **Resume detection.** An unfinished ledger under `.grimoire/bag/runs/<m>-*.md` (`§ Run`, ledger and resume — several → the newest wins, with the one-line warning naming the others) → announce `▶ Resuming run <id>` and go to **[Phase 2]**, applying `§ Run` (resume) page by page. Phase 1 is never re-run; the page set is exactly the ledger's.
4. **Nothing to run** per `§ Run` (hard-stops) → `❌ Construct N has nothing to run.`, followed by the `blocked` pages, if any, each with the hint to resume it with `/grimoire-execute M`. STOP.
5. **Validate the page DAG already known** — the pages specified so far, built as in [The Boundary] step 2 — before any interview:
   - a cycle between pages → `❌ Construct N has cyclic dependencies between pages. Fix the pages' depends-on headers first.`
   - a `depends-on` pointing at a non-existent page → `❌ Construct N references a non-existent page in depends-on. Fix the pages' depends-on headers first.`

**[Phase 1: Spec Interviews]** — interactive
Per `§ Run` (Phase 1) and `§ Pause-point pattern` (`grimoire-run`: Phase 1 pauses). Tell the user once that they may answer "skip the rest" at any interview. Then, for every pending reference in list order:
- Invoke `grimoire-spec <m>` in consumption mode — Grimoire-on-Grimoire per `§ Skill composition` (Claude Code: the `Skill` tool; Codex: read and follow the sibling `grimoire-spec` SKILL.md by path — `§ Harness adaptation`). Its clarifying questions, draft review, and hard-stops apply unchanged; it consumes strictly the first pending reference (`§ Construct`, consumption). Its own closing suggestions are superseded by this run.
- **"Skip the rest"**, or an **abandoned consumption draft** → stop interviewing and go to [The Boundary]; the excluded references and their transitive dependents follow `§ Run` (Phase 1).
- No pending reference → this phase is empty.

**[The Boundary]**
1. Re-load the construct and its pages (Phase 0 step 2) — the interviews changed statuses.
2. **Page DAG** per `§ Run` (Phase 2, page DAG): nodes, edges from the `depends-on` headers / frontmatter when any page carries one, otherwise the implicit chain in list order, satisfied and excluded pages.
3. **Validate it again** — the two page-DAG hard-stops of Phase 0 step 5, same literal messages.
4. **Waves** — Kahn levels per `§ Parallel execution` (wave construction), applied to pages (`§ Run`). Do not restate the algorithm.
5. **Create the ledger** `.grimoire/bag/runs/<m>-<epoch>.md` (`<epoch>` = `$(date +%s)`) with the frontmatter and table of `§ Run` (ledger) — every page of the construct, each in its entry state and wave, `ui_review: none`.
6. **No runnable page** (e.g. everything was skipped) → print no boundary line; go to [Stop & Summary] (`§ Run`, Phase 1).
7. Otherwise print the boundary line — glyph and tokens verbatim, prose localized (`§ User-facing language`): `🚀 Autonomous phase: N pages, K waves — you can leave.` **From here on, no question is asked.**

**[Phase 2: Autonomous Waves]**
Per `§ Run` (Phase 2) — orchestrate it, do not restate it. The **[Teardown invariant]** below is in force from the first page worktree on.
- **Waves in increasing order**; inside a wave, at most `[run].page_parallelism` pages in flight (`§ Configuration`; Codex also caps it — `§ Harness adaptation`).
- **Per page — exactly the `§ Review loop` protocol** (its Phases 2–6: auto-plan, branch / worktree, steps, review cycle, final state), with the base and stacking of `§ Backends` — on GitHub after `git fetch origin --prune`, branching from `origin/<default-branch>` or `origin/<dep-branch>` — and the draft PR attached to the milestone. Every `plan` / `execute` / `fix` / `review` sub-agent is spawned by the session agent itself per `§ Harness adaptation`, with the docs pointers of `[Required Reading]` step 2 and absolute main-workspace paths for every `.grimoire/` file it uses (`§ Harness adaptation`, paths handed to sub-agents).
- **UI reviews.** `{port}` in `[verify]` → a distinct free port per page (`§ Configuration`); no placeholder → the `ui_review` mutex of `§ Run`: hold back a reviewer whose diff matches `[review].ui_globs` while another UI review runs.
- **Watchdog** per `§ Run` (timeouts from `[run]`, `§ Configuration`): one retry with a fresh sub-agent fed the failure context — after discarding the uncommitted edits and keeping the landed commits (`§ Run`, retry with partial state) — then `blocked` with its `⛔` comment and its transitive dependents `skipped`. Per `§ Harness adaptation`, arm a wake-up for the nearest deadline before waiting.
- **Event loop.** On each completion notification or wake-up: map the event to its (page, role); advance that page through the `§ Review loop` phases (plan-cache re-materialization per `§ Backends`, local `phase`, verdict comment with its resume counter, `## Review log`, `## Known advisories`, `gh pr ready`, label swaps, remote branch, `⛔` placement — by reference, not restated), every sub-agent receiving absolute main-workspace paths — step files, `PLAN.md`, `NOTES.md`, `SPEC.md`, the screenshot directory, the ledger (`§ Harness adaptation`); rewrite the ledger (`§ Run`, ledger: `pending` → `planning` → `executing k/n` → `reviewing r/R` → `review` | `blocked`, dependents `skipped`); refill free slots up to `page_parallelism` from the current wave; re-check deadlines and re-arm the wake-up; when every page of the wave is terminal, start the next wave.

**[Stop & Summary]**
- **Stop** per `§ Run` (stop) — every page in `review`, `blocked`, `skipped`, or `done`. Run the **[Teardown invariant]**.
- **Final summary**: a table `page / PR / state / merge order / pointer to Human validation` over every ledger row — the PR (local: branch + `REVIEW.md`), the ledger state, the merge order implied by the stacking, and where `## Human validation` lives (PR body / `REVIEW.md`).
- Next steps — never run automatically: `review` → the human reviews and merges, in the stated order; `blocked` → reply on the issue or on the PR, then `/grimoire-execute N`; references left pending → `/grimoire-spec <m>` or a new `/grimoire-run <m>`, which also picks up `skipped` pages once their blockers are resolved (a finished ledger is never resumed — `§ Run`). If `PROJECT.md` was missing, remind the user about `grimoire-init`.

**[Teardown invariant]** — try/finally-shaped, non-negotiable
Per `§ Review loop` (the page worktree), `§ Parallel execution` (unconditional teardown), and `§ Run` (stop). Each page tears down its own worktrees and kills its dev server when its execution ends — approved, `blocked`, failed, timed out, or aborted. Whatever ends the run — the stop condition, an error, or an abort — the cleanup runs: kill every dev server a reviewer started; `git worktree remove --force` every page and step worktree this run created, then a defensive `rm -rf` of any residue under `.grimoire/bag/worktrees/`, then `git worktree prune`; verify that `.grimoire/bag/worktrees/` is empty and `git worktree list` shows only the main workspace; report anything that could not be removed. Page branches **remain** (pushed when a remote exists).

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language`; the `❌`, `🚀`, `▶`, `⛔` lines keep their glyphs and literal tokens. Issue, PR, comment, and ledger content stays English.
- **Single source of truth.** `§ Run` and `§ Review loop` own every rule this skill orchestrates — this body references them and never restates them.
