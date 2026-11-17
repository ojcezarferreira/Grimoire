# Grimoire Conventions

Shared, load-bearing rules for the Grimoire workflow skills (`grimoire-init`, `grimoire-spec`, `grimoire-plan`, `grimoire-execute`, `grimoire-run`, `grimoire-adopt`, `grimoire-quick`, `grimoire-know`, `grimoire-update`, `grimoire-note`, `grimoire-deps`, `grimoire-construct`, `grimoire-construct-update`). Each SKILL.md references this file as required reading at `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md` (the installer replaces the token with the absolute install path — `§ Harness adaptation`). Do not duplicate these rules inside skill bodies — update them here.

The long-form pipeline is **Spec → Plan → Execute**: `grimoire-spec` gathers context, interviews the user, and writes the page's specification; `grimoire-plan` turns that specification into executable step files when the user wants to steer the plan (otherwise `grimoire-execute` auto-plans); `grimoire-execute` runs the steps inside a page worktree, drives the automated `§ Review loop`, and leaves a pull request waiting for human review. `grimoire-quick` is a separate fast-path that bypasses all three. `grimoire-run` executes a **whole construct**: spec interviews for every pending reference first, then plan → execute → review for every page autonomously, in dependency waves (`§ Run`). `grimoire-adopt` brings **pre-existing GitHub issues and milestones** under Grimoire management. The remaining skills are orthogonal to the pipeline: `grimoire-init` and `grimoire-note` maintain project context (`§ Documentation`), `grimoire-know` answers questions read-only, `grimoire-deps` audits and bumps dependencies, `grimoire-construct` and `grimoire-construct-update` author and alter constructs (`§ Construct`), and `grimoire-update` maintains the Grimoire installation itself.

Workflow state lives in one of two **backends** (`§ Backends`): **GitHub** — pages are issues, constructs are milestones, plans and verdicts are comments, work ships as pull requests — or **local** — the same objects as git-ignored files under `.grimoire/`. Every skill detects the backend once — step 4 of its `[Required Reading]` (`§ Documentation`) — and announces it. Behaviour is identical across backends and across harnesses (Claude Code and Codex — `§ Harness adaptation`); only the storage and the tool names differ.

---

## § TDD

Every code change follows strict Red → Green → Refactor.

**CRITICAL:** NEVER execute the entire test suite. Use test filters (e.g., `--filter` in PHPUnit/Pest, `-k` in pytest, exact file paths in Jest/Vitest, etc.) to run ONLY the tests created or modified in the current step.

1. **Red:** Write or modify the tests for the current step. Run ONLY these tests and verify failure.
2. **Green:** Implement the minimum code needed. Run the same filtered tests again and verify they pass.
3. **Refactor:** Clean up the code while keeping the filtered tests green.

The same loop applies regardless of whether the work comes from `grimoire-plan`, `grimoire-execute`, or `grimoire-quick`.

**Documented exception — the review gate.** The reviewer in `§ Review loop` runs the project's **full** `test_command`, `build_command`, and `lint_command` (`[verify]` in `§ Configuration`) once per review round, inside the page worktree. A pull request has global blast radius, so the filter-only rule above does not apply to that gate — the same documented exception `grimoire-deps` makes for a dependency bump. Step executors and fixers still follow the filtered loop.

---

## § Code comments

Comments are the exception, not the default. Code Grimoire writes should read on its own through clear names and structure; a comment earns its place only when the code cannot make the intent obvious by itself.

- **Comment the unusual, not the routine.** Only blocks with non-obvious, surprising, or hard-to-assimilate details deserve a comment — and it should explain the *why* (the reason, tradeoff, or gotcha), not restate the *what*.
- **Large branching flows MAY get light guideposts.** A long flow with several partitions and paths may carry small comments that orient the reader through the sections — short signposts, not narration of every line.
- **Methods/helpers: brief, and only if not obvious.** A helper may carry a one-line note of what it does, but only when its name and signature don't already make that clear. Skip the comment when it would just echo the name.
- **No redundant, commented-out, or TODO-as-comment noise.** Don't comment the obvious, don't leave dead code commented out, and don't narrate the change history — that's what commits are for (`§ Commits`).

This rule governs code written during `§ TDD` (the Refactor step is where excess comments are removed). It applies to `grimoire-execute` and `grimoire-quick`.

---

## § Harness adaptation

Grimoire runs on two harnesses: **Claude Code** and **Codex**. This section is the **single source of truth** for everything harness-specific — SKILL.md bodies reference it; they never restate these rules. Every other section of this file is harness-neutral: it names an *operation* (spawn a role, wait, ask the user, invoke a sibling skill) and the table below maps that operation to each harness.

**Detection.** The harness is detected once per skill run from the tools present in the session: an `Agent` tool means Claude Code; a `spawn_agent` tool means Codex. The result selects the `[agents.claude]` / `[agents.codex]` table of `§ Configuration`.

| Operation | Claude Code | Codex |
|---|---|---|
| spawn(role) | `Agent` with `model` / `effort` from the role's config entry and `run_in_background: true`; `subagent_type: Explore` for the `research` role (read-only, enforced by the harness), `general-purpose` for every other role; the worktree path is stated in the prompt | `spawn_agent(message, task_name, model, reasoning_effort)`; **no per-child cwd** → the prompt starts with `cd <worktree>`; worktrees stay inside the repository so the `workspace-write` sandbox allows them |
| tool restriction | none per call → reviewer / planner restrictions are **instructed, not enforced** | same (only coarse `features.*` keys exist) |
| wait / watch | completion notifications; `TaskStop` on an overdue agent when the orchestrator wakes up (best-effort) | the harness's wait / collect tool; `agents.max_concurrent_threads_per_session` caps the wave |
| ask the user | `AskUserQuestion` | the harness's question tool, or a plain prompt |
| skill directory | absolute path substituted at install time (`${GRIMOIRE_HOME}`) | same; the SKILL.md path also appears in the skills list |
| invoke a sibling skill / dependency | `Skill` tool | read the SKILL.md by path (`~/.agents/skills/<name>/SKILL.md`) |
| model / effort values | `fable`, `opus`, `sonnet`, `haiku`; `low` … `max` | `gpt-6-astra`, `gpt-6.1-sol`, …; `low` … `max` (`ultra` → `max` with a warning) |

**Codex deltas.** There is no `Workflow` tool and no `Skill` tool: composition is by path (`§ Skill composition`). Sub-agents inherit no working directory, so every spawned prompt begins with `cd <worktree>`. The watchdog of `§ Run` is best-effort on both harnesses: the orchestrator checks elapsed time when it wakes up and can only stop an overdue sub-agent through the harness's stop tool — it cannot preempt it.

**Install location.** Skills are installed as **copies** under `~/.claude/skills/<name>/` (Claude Code) and `~/.agents/skills/<name>/` (Codex). The literal token `${GRIMOIRE_HOME}` in every skill body is replaced by the installer with the absolute path of the Grimoire home (default `$HOME/.grimoire`), which holds `GRIMOIRE-CONVENTIONS.md`, `VERSION`, `install.sh`, and the global `config.toml` (`§ Configuration`).

---

## § Sub-agent spawning

The session agent is an **orchestrator**. It dispatches sub-agents, watches them, and records their outcome — it **never implements**: no code, no fixes, no auto-plan bodies, no reviews are produced in the orchestrator's own context. Implementation runs inside sub-agents so the orchestrator's context stays lucid.

**Roles.** Every sub-agent is spawned under one of seven roles. The role resolves to a model + effort through the **role lookup order** of `§ Configuration` and to the harness's spawn call through `§ Harness adaptation`.

| Role | Spawned by | Does |
|---|---|---|
| `research` | `grimoire-spec`, `grimoire-construct`, `grimoire-construct-update`, `grimoire-adopt`, `grimoire-know`, `grimoire-deps` (audit) | read-only codebase / web analysis; returns findings to the orchestrator. On Claude Code it uses the `Explore` subagent type (read-only enforced); on Codex it is instructed read-only |
| `plan` | `grimoire-execute` / `grimoire-run` — auto-plan of a page in `spec` status | writes the step files **without an interview**; unresolved choices become `## Assumptions` (`§ Review loop`) |
| `execute` | `grimoire-execute` / `grimoire-run` — one per step file | implements one step per `§ TDD`, commits per `§ Commits` |
| `fix` | the `§ Review loop`, after a `changes-requested` verdict | resolves the reviewer's findings on the page branch; commits; pushes |
| `review` | the `§ Review loop` — one per round | reviews the page: reads and runs, never edits code |
| `quick` | `grimoire-quick` | the whole quick fix, once the user has authorized the inline plan |
| `deps` | `grimoire-deps` (apply) | applies one selected dependency bump at a time |

- **Who spawns what.** `grimoire-spec`, `grimoire-construct`, `grimoire-construct-update`, `grimoire-adopt`, `grimoire-know`, and the audit phase of `grimoire-deps` run their analysis in `research` sub-agents; the orchestrator interviews the user and performs the writes itself. `grimoire-plan` — the interactive planner — plans in the session because it is a dialogue with the user; the `plan` role belongs to the **auto-planner** of `grimoire-execute` / `grimoire-run` only. `grimoire-init`, `grimoire-note`, and `grimoire-update` spawn nothing.
- **`grimoire-execute` on a page with one step file:** one `execute` sub-agent.
- **`grimoire-execute` on a page with multiple step files and NO `depends-on` frontmatter:** strict serial — one `execute` sub-agent **per step file** in numeric order; never start step `N+1` until step `N` has fully completed.
- **`grimoire-execute` on a page where any step file declares `depends-on` frontmatter:** parallel-wave mode per `§ Parallel execution`. Steps inside a single wave MAY be spawned **concurrently** — one sub-agent per step, each operating inside its own step worktree per the worktree contract. Sequencing **across** waves remains strict: wave `K+1` never starts until wave `K` has settled and all of its worktrees have been torn down.
- **`grimoire-run`:** the pages of a wave run concurrently up to `[run].page_parallelism`; each page spawns its own `plan` / `execute` / `fix` / `review` sub-agents exactly as `grimoire-execute` does (`§ Run`). Orchestration stays **flat**: the session agent spawns every sub-agent itself and never nests an orchestrator inside a sub-agent.
- **`grimoire-quick`:** a single `quick` sub-agent for the entire fix once the user has authorized the inline plan.
- **Claude Code subagent types.** `research` → `Explore`; every other role → `general-purpose`. Tool restrictions for `plan` and `review` are **instructed, not enforced**, on both harnesses (`§ Harness adaptation`).

Always instruct the sub-agent with the specific step file (or inline plan, or review brief) it must act on and the worktree it must work in, and require it to follow `§ TDD`, `§ Code comments`, and `§ Commits`.

---

## § Configuration

This section is the **single source of truth** for Grimoire's configuration — SKILL.md bodies reference it; they never restate these rules.

**Files.**
- **Global:** `${GRIMOIRE_HOME}/config.toml`. Copied from `config.example.toml` by the installer when absent, **never overwritten** by it, git-ignored in the Grimoire checkout. Holds the user's personal defaults (models, efforts, parallelism).
- **Project:** `.grimoire/config.toml` in the consuming repository. **Committed.** Written by `grimoire-init` (`[verify]`, `[docs]`, and any project-level override); hand-editable afterwards.

**Precedence.** Built-in defaults (the schema below) < global file < project file, merged **key by key** — a project file that sets only `[verify]` keeps the global `[agents.*]`.

**Role lookup order** (`§ Sub-agent spawning`). A role's model + effort is the first hit in: project `[agents.<harness>].<role>` → global `[agents.<harness>].<role>` → project `[agents.<harness>].default` → global `[agents.<harness>].default` → the built-in `<role>` value of the schema below. A user-set `default` therefore overrides the built-in per-role values.

**Reading.** Skills read both files **as text** and interpret them — there is no TOML parser in the loop. Unknown keys are ignored. An invalid value produces a **one-line warning** and the built-in default. Configuration **never hard-stops** a skill: a missing file, a missing table, or a broken line degrades to the defaults.

**Schema and built-in defaults** (`config.example.toml` ships exactly this):

```toml
[agents.claude]
session  = { model = "fable", effort = "max" }   # recommendation only: the skill warns when the session model differs
default  = { model = "opus",  effort = "high" }
research = { model = "fable", effort = "max" }
plan     = { model = "fable", effort = "max" }
execute  = { model = "opus",  effort = "high" }
fix      = { model = "opus",  effort = "high" }
review   = { model = "opus",  effort = "high" }
quick    = { model = "opus",  effort = "high" }
deps     = { model = "opus",  effort = "high" }

[agents.codex]
session  = { model = "gpt-6-astra", effort = "max" }
default  = { model = "gpt-6.1-sol", effort = "max" }
research = { model = "gpt-6-astra", effort = "max" }
plan     = { model = "gpt-6-astra", effort = "max" }
execute  = { model = "gpt-6.1-sol", effort = "max" }
fix      = { model = "gpt-6.1-sol", effort = "max" }
review   = { model = "gpt-6.1-sol", effort = "max" }
quick    = { model = "gpt-6.1-sol", effort = "max" }
deps     = { model = "gpt-6.1-sol", effort = "max" }

[run]
page_parallelism = 2            # 0 = unlimited (Codex also caps it via agents.max_concurrent_threads_per_session)
step_timeout_minutes = 45
review_timeout_minutes = 30

[review]
max_rounds = 3
ui_globs = ["src/**/*.{tsx,jsx,vue,svelte,css,scss}", "app/**", "components/**", "pages/**"]

[github]
mode = "auto"                   # auto | on | off
label_prefix = "grimoire"
branch_prefix = "grimoire"

[verify]                        # discovered by grimoire-init; used by execute / review / agent-browser
install_command = "pnpm install"
dev_command = "pnpm dev --port {port}"     # {port} = port allocated per page; without the placeholder UI reviews are serialized
dev_url = "http://localhost:{port}"
test_command = "pnpm test"
build_command = "pnpm build"
lint_command = "pnpm lint"

[docs]
dir = "docs"
language = "en"                 # grimoire-init asks once (or infers it from the README)
```

**Roles → consumers.** `research` = the analysis sub-agents of `grimoire-spec`, `grimoire-construct`, `grimoire-construct-update`, `grimoire-adopt`, `grimoire-know`, and the `grimoire-deps` audit (on Claude Code spawned as the `Explore` subagent type — read-only enforced); `plan` = the auto-planner of `grimoire-execute` / `grimoire-run`; `execute` = the step executors; `fix` = the fixers of the `§ Review loop`; `review` = the reviewer; `quick` = the `grimoire-quick` sub-agent; `deps` = the `grimoire-deps` apply sub-agent. A role missing from a file resolves per the **role lookup order** under Precedence above.

**The `session` role is notice-only.** It recommends the model / effort the user should run the session (the orchestrator) with. Skills never change the session model; at startup a skill compares its own model with `session` and, when they differ, prints a one-line notice and continues.

**Harness mapping.** Claude Code → `Agent(model = <alias>, effort = <x>)`, `model ∈ {fable, opus, sonnet, haiku}` (aliases — full model ids are reserved for a future generation of `.claude/agents/*.md`). Codex → `spawn_agent(model = <id>, reasoning_effort = <x>)`. The effort `ultra` is not a sub-agent effort on Codex: it is rejected with a warning and replaced by `max`.

**Validation per harness.** Effort accepted on both harnesses: `low`, `medium`, `high`, `xhigh`, `max`. Model on Claude Code: `fable`, `opus`, `sonnet`, `haiku`. Model on Codex: `gpt-6-astra`, `gpt-6.1-sol`, `gpt-6.1-terra`, `gpt-6-luna` (as of Codex CLI 0.169; a newer id the harness accepts is passed through unchanged). A value the harness rejects at spawn time falls back to the role's built-in default with the same one-line warning.

**The `{port}` placeholder.** `[verify].dev_command` and `[verify].dev_url` MAY contain the literal `{port}`. When present, the `§ Review loop` allocates a free port per page and substitutes it into both strings before starting the dev server, so pages reviewed in parallel never collide. When absent, UI reviews are **serialized** across pages (`§ Run`) and a port already in use means the review proceeds without a browser. `grimoire-init` emits `{port}` whenever the project's dev tool accepts a port flag (Vite `--port`, Next `-p`, …).

**`[github]`.** `mode` drives backend detection (`§ Backends`); `label_prefix` and `branch_prefix` are the literal prefixes of the labels (`<label_prefix>:spec`, …) and of the page branches (`<branch_prefix>/<page>-<slug>`). This file spells the defaults — `grimoire:` and `grimoire/` — everywhere; a project that overrides them reads every such literal with its own prefix.

**`[run]`, `[review]`, `[docs]`** are consumed by `§ Run`, `§ Review loop`, and `§ Documentation` respectively.

---

## § Skill composition

This section is the **single source of truth** for how every Grimoire skill discovers and uses *other* locally-installed skills as helpers. SKILL.md bodies reference it; they never restate these rules. Composition lets a skill borrow a sibling's strength (research, review, verification, docs-lookup, …) without ever surrendering Grimoire's own contracts.

1. **Discovery mechanism (no FS scan).** The orchestrator surveys the skill list the Claude Code runtime injects into context (the "available skills" block) together with the `Skill` tool registry, and matches candidate helpers by each skill's `description`. Grimoire performs **no filesystem scanning** of skill directories — it never reads `~/.claude/skills/`, the project's `.claude/skills/`, or any plugin cache to find helpers. Discovery is purely from what the runtime already presents. **On Codex there is no `Skill` tool, so discovery is by path:** the runtime's skill list shows each skill's SKILL.md path, and a helper is invoked by reading that file (`~/.agents/skills/<name>/SKILL.md`) — still no directory scan (`§ Harness adaptation`).

2. **Invocation posture: discover always; invoke with a one-line announcement.** Discovery runs on every skill; only invocation is need-driven.
   - **Read-only / assistive helpers** (research, review, verification, docs-lookup, and the like) are used **automatically** whenever one materially helps, announcing in a single line which helper ran and why (see the announcement template below).
   - **Helpers that write, have side-effects, or change the task's scope** are surfaced as a *candidate* and require an explicit user **"ok"** before invocation. This write/scope gate **folds into the skill's existing `§ Pause-point pattern` checkpoints** — it is asked at the nearest existing pause-point and **does not introduce a new pause-point or a new pipeline phase**.

3. **Announcement template.** The reusable operator-facing one-liner for read-only/assistive use is prefixed with the `🧩` glyph:

   `🧩 Using <skill-name> to <reason>.`

   Like the `❌` and `📄` glyphs, the `🧩` glyph and the literal `<skill-name>` are preserved **verbatim** while the surrounding prose is localized per `§ User-facing language`. The "may I use `<skill-name>`?" gating prompt for write/scope-changing helpers is likewise operator-facing prose, localized the same way (glyph and skill name verbatim).

4. **Guardrails / exclusions.**
   - **Exclude conflicting orchestrators / planners.** Any skill that would duplicate or fight Grimoire's own Spec → Plan → Execute pipeline — a competing `init` / `plan` / `review` / spec workflow — is **never** composed with.
   - **Helpers never own `.grimoire/` state.** A helper skill never takes write-ownership of `.grimoire/` state (`PROJECT.md`, `config.toml`, `CONSTRUCT.md`, or any page/construct folder) nor of the backend objects of `§ Backends`. Those writers are fixed by `§ Documentation`, `§ Backends`, and `§ Construct`.
   - **Helpers never override Grimoire contracts.** `§ TDD`, `§ Commits`, `§ Pause-point pattern`, `§ Backends` state ownership, the `§ Documentation` and `§ Construct` dual-writer contracts, and every hard-stop stay in force regardless of any helper invoked.

5. **Grimoire-on-Grimoire.** Grimoire's own skills MAY invoke one another where a sibling genuinely helps, but each sibling keeps its own write-ownership and hard-stops; composition **never bypasses a precondition hard-stop** (e.g. invoking `grimoire-plan` from within another skill does not skip its `spec`-status precondition).

6. **Localization pointer.** All helper announcements and any "may I use X?" prompts are operator-facing prose, rendered in the user's language per `§ User-facing language` — command/skill names and the `🧩` glyph preserved verbatim.

7. **Applicability.** This convention applies to **every** skill, but each skill composes only *where a helper materially helps*. A skill that rarely finds a relevant helper (e.g. `grimoire-update`) simply rarely composes. Discovery is always performed; invocation is need-driven.

---

## § Parallel execution

`grimoire-execute` MAY run mutually-independent step files of the same page concurrently. This section is the **single source of truth** for the parallel-wave model — SKILL.md bodies reference it; they never restate the rules.

The model is **strictly opt-in**. A page becomes eligible for parallel execution only when at least one of its step files declares `depends-on` in its YAML frontmatter (see schema below). A page where no step file carries `depends-on` runs via the legacy strict-serial path defined in `§ Sub-agent spawning` — step sequencing identical to the pre-0.8.0 implementation, inside the page worktree. `§ Run` reuses the same Kahn-wave algorithm at **page** level — the nodes are the pages of a construct and the edges their `depends-on`.

### Frontmatter schema

Step files MAY carry a YAML frontmatter block at the very top of the file, delimited by `---` lines:

```
---
depends-on: [<step-numbers>]
touches: [<repo-relative paths>]
---

# Step N — …

(markdown body as before)
```

- `depends-on` — list of step numbers (integers) this step depends on. **Missing or empty means the step is a DAG root** (eligible for wave `0`).
- `touches` — list of repo-relative paths the step will modify. **Optional but recommended.** Used at plan time to surface advisory overlap warnings between parallel siblings; not enforced at execute time.
- The markdown body below the frontmatter is the canonical step content the sub-agent executes; the frontmatter is parsed and stripped by the runtime.

### DAG construction

- **Nodes** are step files (identified by step number).
- **Edges** are `depends-on` references: an edge from step `K` to step `N` exists when step `N` lists `K` in its `depends-on`.
- **Cycle detection is mandatory** at both plan time (refuse to write step files) and execute time (refuse to start the run). Defense in depth — neither side may assume the other validated the graph.
- **Dangling references are a hard error.** A `depends-on` value pointing at a step number that does not exist in the page is a hard error at both plan time and execute time. It is never silently ignored.

### Wave construction (Kahn-style topological levels)

- **Wave `0`** = the set of all steps whose `depends-on` is missing or empty (DAG roots).
- **Wave `K`** = the set of all steps whose entire `depends-on` set lies in waves `< K`.
- Waves are computed deterministically from the DAG at the start of the run.
- All steps in a wave run **concurrently**. Waves run **sequentially** in increasing order (`0`, then `1`, then `2`, …).

### Worktree contract (load-bearing — non-negotiable)

- **Location.** Each step's worktree lives at the deterministic, page- and step-scoped path `.grimoire/bag/worktrees/page-<N>-step-<K>/`, where `<N>` is the page number (in GitHub mode the issue number, unpadded; locally the zero-padded `NNN`) and `<K>` is the step number. The page worktree itself — `.grimoire/bag/worktrees/page-<N>/`, `§ Review loop` — is the **reference workspace** of the run; step worktrees branch from it.
- **Creation.** At the start of each wave, the orchestrator runs `git worktree add` for every step in the wave, branching from the page worktree's (the reference workspace's) current `HEAD` — the page branch. The runtime MAY use detached worktrees or short-lived branches — the only requirement is that each worktree is independently committable.
- **Per-step sub-agent isolation.** Each step's sub-agent works **only inside its own worktree directory**. It must not touch the main workspace, sibling worktrees, or any `.grimoire/` state file outside its worktree.
- **Cherry-pick back to the page worktree.** Once the wave settles (every step sub-agent has either succeeded or failed), the orchestrator cherry-picks each **successful** step's commits back to the page worktree (the reference workspace) **in step-number order** (lowest step number first). The page branch history reads as if the wave had run serially, even though the work itself was concurrent.
- **Unconditional teardown.** Before starting the next wave, **and** at the end of the run regardless of outcome (success, partial failure, or hard abort), the orchestrator runs `git worktree remove --force <path>` for every worktree it created in that wave, followed by a defensive filesystem `rm -rf` on any residual step directory (`page-<N>-step-*`) under `.grimoire/bag/worktrees/` — the page worktree itself is torn down at the end of the run per `§ Review loop`. **Per page: after a page's execution ends, no `page-<N>/` and no `page-<N>-step-*` worktree of that page remains. Per invocation: at the end of the whole invocation — `grimoire-execute` standalone, or `grimoire-run` as a whole — `.grimoire/bag/worktrees/` MUST be empty AND `git worktree list` MUST show only the main workspace.**
- The skill body must enumerate teardown as a **try/finally-shaped invariant** — teardown runs whether the wave succeeded, failed, partially failed, or the run was aborted. The maintainer has been bitten by stale worktree clutter before; this is the dominant safety property of the feature.

### Failure semantics

- **Failed step → worktree discarded.** No commits from a failed step's worktree are cherry-picked back to the page worktree. The worktree is removed per the teardown rule above.
- **Successful siblings still cherry-pick.** Other steps in the same wave that succeeded **still apply their commits** back to the page worktree, in step-number order, skipping the failed step's slot.
- **Downstream waves are filtered.** Any step in a later wave whose `depends-on` set **transitively** includes the failed step is **skipped**. Independent downstream waves (no transitive dep on the failure) still run.
- **No mid-wave kill.** When one step inside a wave fails, the orchestrator waits for the other in-flight siblings to finish (success or failure) before declaring the wave result. Premature cancellation is out of scope.
- **The page stays `planned`** on partial failure and, within that execution, never enters the review cycle: the run ends `blocked` (label + `⛔` comment listing the failed steps — `§ Review loop`). The user re-runs `/grimoire-execute <N>` to retry; the re-run follows the resume rules of `§ Review loop` — with no draft PR yet, the page branch is reset to its base and every step runs again. There is no resume-from-partial-success state file in v1.
- **No concurrency cap** inside `grimoire-execute` itself. All wave members are spawned at once. The runtime's existing sub-agent limits are the de-facto cap.

### Back-compat fallback

- If **no step file** in the page carries `depends-on` frontmatter, `grimoire-execute` falls back to the **legacy strict-serial path** defined in `§ Sub-agent spawning`. No **step** worktrees are created and no waves are computed; step sequencing is identical to the pre-0.8.0 implementation — sub-agents are spawned one at a time in numeric order, each working directly in the page worktree (`§ Review loop`).
- This detection happens in `grimoire-execute` Phase 1, before any execution begins.
- Existing pages (e.g., `001-grimoire-note-skill`) are unaffected — no auto-migration, no silent re-planning, no auto-emit of frontmatter on legacy step files.

### Commits

Per-step atomic commits follow `§ Commits`. This section does not restate those rules — it only notes that step-level commits are made by the sub-agent **inside its worktree**, and that cherry-pick-back to the page worktree preserves their atomicity and order.

---

## § Commits

- Make granular, atomic commits as work progresses.
- Commit immediately after each logical step completes (typically end of Green or Refactor).
- Use **Conventional Commits in English**: `feat:`, `fix:`, `test:`, `refactor:`, `chore:`, `style:`, `docs:`.
- One logical change per commit — do not bundle unrelated edits.
- **Only code commits.** The consuming repository receives commits from the step executors and fixers (`grimoire-execute` / `grimoire-run`), from `grimoire-quick`, and from `grimoire-deps` (`chore(deps): bump <pkg> to <ver>`, one atomic commit per dependency) — plus the documentation / migration commits of the two context writers:
  - `grimoire-init` → `docs(grimoire): initialize project context` (first run) or `docs(grimoire): update project context` (update mode), and `chore(grimoire): migrate to 0.14 layout` when the 0.13 migration is accepted (`§ Documentation`).
  - `grimoire-note` → `docs(grimoire): refine project context`.
- **No state commits in any backend.** Specifying, planning, reviewing, blocking, or finishing a page, and creating or altering a construct, never produce a commit: that state lives in GitHub objects or in git-ignored files (`§ Backends`, `§ .grimoire/ layout`). `grimoire-spec`, `grimoire-plan`, `grimoire-construct`, `grimoire-construct-update`, `grimoire-adopt`, `grimoire-know`, and `grimoire-update` commit nothing.
- **Branch and PR.** A page executes on the branch `<branch_prefix>/<page>-<slug>` (default `grimoire/<page>-<slug>`; `<page>` = the issue number on GitHub, `NNN` locally), created from the base computed per `§ Backends` and never checked out in the user's working tree (`§ Review loop`). Step commits land on it — directly, or by cherry-pick from step worktrees per `§ Parallel execution`. After the **first step commit** reaches the page branch, `grimoire-execute` pushes it (`git push -u`) and opens a **draft** pull request; on reviewer approval it runs `gh pr ready`. Fixers push after every round. Locally (no GitHub) the branch is pushed when a remote exists and `REVIEW.md` stands in for the PR.
- Step executors commit **inside their own worktree**; the orchestrator never amends, squashes, or rewrites their commits. The only history rewrite any skill performs is the branch reset of `§ Review loop` (resume without a draft PR); the only branch deletion is the one in `§ Run`.

---

## § Backends

This section is the **single source of truth** for where Grimoire's workflow state lives — SKILL.md bodies reference it; they never restate these rules. Two backends exist: **GitHub** (issues, milestones, comments, pull requests) and **local** (git-ignored files under `.grimoire/` — `§ .grimoire/ layout`). The invocation syntax, the phases, and the pause-points of every skill are the same on both; only the storage differs.

### Detection and announcement

- Detection runs **once per skill run**, in `[Required Reading]`, after the configuration has been loaded (`§ Documentation`). `[github].mode` is `auto` | `on` | `off`:
  - `auto` → GitHub **iff** `git remote get-url origin` has host `github.com` (ssh or https) **and** `gh auth status` exits 0; otherwise local.
  - `on` → GitHub; when `gh auth status` fails → hard-stop `❌ GitHub backend required but gh is not authenticated.`
  - `off` → local, even with a GitHub remote.
- The skill announces the result in one line: `🔗 Backend: GitHub (owner/repo)` or `📁 Backend: local` — glyphs verbatim, prose localized per `§ User-facing language`.

### Identifiers

The invocation syntax is identical on both backends; what a number resolves to depends on the backend.

| Object | GitHub | Local |
|---|---|---|
| page | issue number (`42` or `#42`) | `NNN` (`42` and `042` both resolve) |
| construct | milestone number (the exact milestone title is also accepted) | `NNN` or `<name>` |

- `grimoire-spec <number>` = consume the next reference of that construct; `grimoire-plan <number>` / `grimoire-execute <number>` = a page; `grimoire-run <number|title>` = a construct; `grimoire-adopt 42` / `#42` = an issue and `grimoire-adopt milestone 3` / `m3` / `<title>` = a milestone (GitHub only).
- In operator-facing messages `N` is rendered as the identifier of the backend in use: `#42` on GitHub, `042` locally.
- **Page slug (GitHub).** A page's `<slug>` is derived from the issue title at first use — lowercase; every run of non-alphanumerics → `-`; repeats collapsed; leading / trailing `-` trimmed; at most 40 characters — and names the branch `grimoire/<N>-<slug>` and the cache folder `.grimoire/pages/<N>-<slug>/`. Every later lookup (resume detection, run ledger, PR lookup) matches by the prefix `grimoire/<N>-*` / `.grimoire/pages/<N>-*`, so a later title edit is harmless.
- **Unmanaged issues.** An existing issue whose body lacks the page marker is not a page: `grimoire-plan` and `grimoire-execute` hard-stop and point at `grimoire-adopt` (`§ Pause-point pattern`).
- **No state commits in any backend** (`§ Commits`): the consuming repository receives code commits and the `grimoire-init` / `grimoire-note` documentation commits only.

### GitHub state model

Every object Grimoire manages starts with a **marker in an HTML comment** — invisible when rendered, preserved **verbatim by every writer** (a writer that rewrites a body keeps line 1 and only updates the fields it owns):

| Object | Marker (line 1) | Content |
|---|---|---|
| Milestone ⇄ construct | `<!-- grimoire:construct v=1 -->` | Title = the construct name. Description = intro / arc / research findings + `## References`: a **numbered** list in execution order, `1. #123 — <one line>` (optional suffix `(after #121, #122)` mirroring the dependencies). The list is the source of the **order**. |
| Issue ⇄ reference / page | `<!-- grimoire:page v=1 construct=#M order=3 depends-on=#121,#122 -->` (fields optional) | Reference: body = the seed (intent, scope hints, constraints, acceptance signals). Page: body = the SPEC sections (Context, Goals, Non-goals, Scope, Acceptance criteria, Constraints, Open questions, References). The header is the source of the **dependencies**. |
| Comment ⇄ plan | `<!-- grimoire:plan v=1 -->` | `## Assumptions` (the planner's unilateral decisions) + one `<details><summary>Step K — <name></summary>` per step holding the **step file verbatim, YAML frontmatter included** (`depends-on` / `touches`). The most recent plan comment wins (re-plan = new comment — allowed only while no page branch exists, `§ Pause-point pattern`). |
| Comment ⇄ verdict | `<!-- grimoire:verdict round=N -->` | The reviewer's report (format in `§ Review loop`). |
| PR ⇄ branch | — | Branch `grimoire/<issue>-<slug>`. Body: `Closes #N` · `## Summary` · `## Plan` (link to the plan comment) · `## Human validation` · `## Review log` · `## Known advisories`. |

**Labels.** One status label at a time; `grimoire:blocked` and `grimoire:dropped` are side labels. Progression: `grimoire:reference` → `grimoire:spec` → `grimoire:planned` → `grimoire:review` → issue closed by the merge (`Closes #N`). The prefix is `[github].label_prefix`.

| Label | Color | Meaning |
|---|---|---|
| `grimoire:reference` | `BFD4F2` | reference seed of a construct, not yet specified |
| `grimoire:spec` | `1D76DB` | page specified, not yet planned |
| `grimoire:planned` | `0E8A16` | page planned (plan comment posted) |
| `grimoire:review` | `FBCA04` | PR ready, waiting for human review |
| `grimoire:blocked` | `B60205` | side label — execution stopped, human input needed (coexists with `grimoire:planned`) |
| `grimoire:dropped` | `CFD3D7` | side label — reference removed from its construct (issue closed) |

- **Label-ensure rule.** Labels are created idempotently with `gh label create <name> --color <hex> --description "<d>" --force` — eagerly by `grimoire-init` (GitHub mode) and lazily by any writer about to apply a label that may not exist yet.
- **Transitions per skill:** `grimoire-construct` / `grimoire-adopt` → `reference` (adopting a single issue → `spec`); `grimoire-spec` → `spec`; `grimoire-plan` and the auto-planner → `planned`; `grimoire-execute` / `grimoire-run` → `review` (approved) or `+blocked` (rounds exhausted or execution failed; coexists with `planned`); `grimoire-construct-update` (removal) → `dropped` + close. A writer swaps the status label in a single `gh issue edit` (`--remove-label … --add-label …`); `grimoire:blocked` is removed when a resume starts (`§ Review loop`).

**Plan comment** — line 1 is the marker, then `## Assumptions`, then one collapsed block per step in numeric order:

~~~
<!-- grimoire:plan v=1 -->
## Assumptions
- <decision the planner took unilaterally, and why>

<details><summary>Step 1 — <name></summary>

```markdown
---
depends-on: []
touches: [<paths>]
---

# Step 1 — <name>
…
```

</details>
~~~

**Verdict comment** — line 1 is `<!-- grimoire:verdict round=N -->`, then the reviewer's report whose final block is the verdict defined in `§ Review loop`. Human comments on the issue or on the PR **newer than the last Grimoire-authored comment** (a verdict or a `⛔` comment; when there is none, every human comment since the plan comment) are the input of a resume (`§ Review loop`).

**PR body template:**

```
Closes #N

## Summary
<what the page delivers — rewritten by the reviewer on approval>

## Plan
<link to the plan comment>

## Human validation
<concrete manual steps · what could not be verified · merge order when stacked>

## Review log
- round 1 — changes-requested (<n> blocking) → <link to the verdict comment>
- round 2 — approve

## Known advisories
- [<category>] <file:line> — <finding>
```

**Base branch and stacking.** The **base** of a page branch is the repository's default branch on GitHub (`gh repo view --json defaultBranchRef`); locally it is the branch checked out in the main workspace when the execution starts, recorded in the page's frontmatter `base` (`§ .grimoire/ layout`). **Stacking:** when some page in the page's `depends-on` is not yet integrated — GitHub: its PR is **not merged**; local: its branch is **not an ancestor** of the base (`git merge-base --is-ancestor <dep-branch> <base>` fails) — the base becomes the branch of the **last** such dependency in list order, and the remaining non-integrated dependencies are `git merge --no-edit`'d into the new branch at creation time (a rare, documented case). After the human merges the base and deletes its branch, GitHub re-targets the stacked PR; **v1 performs no rebase** — `## Human validation` states the merge order. The orchestrator never waits for a human merge.

**`gh` cheat sheet** — the commands the skills use:

- Repository: `gh repo view --json nameWithOwner,defaultBranchRef`
- Milestones (no native `gh milestone`): create `gh api repos/{owner}/{repo}/milestones -f title=… -F description=@desc.md` · read `gh api repos/{owner}/{repo}/milestones/<n>` · update `gh api -X PATCH … -F description=@desc.md` · list `gh api 'repos/{owner}/{repo}/milestones?state=all'`
- Issues: create `gh issue create -t "<t>" -F body.md -l grimoire:reference -m "<milestone title>"` · edit `gh issue edit <n> -F body.md --remove-label grimoire:reference --add-label grimoire:spec` · read `gh issue view <n> --json number,title,body,labels,milestone,state,comments` · list `gh issue list -m <n|title> -s all --json number,title,labels,state,body --limit 100` · comment `gh issue comment <n> -F plan.md` · removal `gh issue edit <n> --remove-milestone --add-label grimoire:dropped && gh issue close <n> -c "Removed from construct <name>"`
- Pull requests: create `gh pr create --draft -B <base> -H <branch> -t "<t>" -F pr.md -m "<milestone title>"` · edit `gh pr edit <n> --body-file pr.md` · ready `gh pr ready <branch>` · comment `gh pr comment <n> -F review.md` · read `gh pr view <branch> --json number,url,isDraft,baseRefName,state,comments` · list `gh pr list --head <branch> --state all --json number,state,mergedAt`
- Labels: `gh label create <name> --color <hex> --description "<d>" --force` · block `gh issue edit <n> --add-label grimoire:blocked` · unblock `gh issue edit <n> --remove-label grimoire:blocked`
- Run resume only (`§ Run`): `gh pr close <n>` · `git push origin --delete <branch>`

**Adoption** (`grimoire-adopt` on a milestone). The milestone becomes a construct in place:
- Issues that already carry the page marker keep their state and label, and are listed in `## References` in the order fixed during the interview.
- Closed issues are excluded from the list unless the user asks to include them.
- The original milestone description is preserved verbatim inside `<details><summary>Original milestone description</summary>…</details>`, placed after the Grimoire intro.
- Issues adopted as references get the page marker (`construct=#M order=N`, optional `depends-on`) and the `grimoire:reference` label, and keep their original text inside `<details><summary>Original issue text</summary>…</details>` below the seed.

**Local cache (GitHub mode).** `.grimoire/pages/<issue>-<slug>/K-<step>.md` is a git-ignored cache of the plan comment, written by `grimoire-plan` / the auto-planner together with the comment: `grimoire-execute` re-materializes the step files from the latest plan comment when they are absent (switching machines), and the plan comment always wins over a stale cache. The SPEC is **not** cached — it is read from the issue every time.

---

## § .grimoire/ layout

Every feature, change, or alteration tracked by Grimoire is a **page**; a larger-than-a-page objective is a **construct** (`§ Construct`). In GitHub mode both live in GitHub objects (`§ Backends`) and `.grimoire/` holds committed context plus git-ignored caches; in local mode `.grimoire/` holds the objects themselves — still git-ignored. **Only two files under `.grimoire/` are ever committed.**

```
.grimoire/PROJECT.md                              committed — index of docs/ + Grimoire-only rules (§ Documentation)
.grimoire/config.toml                             committed — project configuration (§ Configuration)
.grimoire/pages/NNN-<slug>/                       git-ignored — SPEC.md, PLAN.md, NOTES.md, K-<step>.md, REVIEW.md
.grimoire/constructs/NNN-<name>/                  git-ignored — CONSTRUCT.md, references/N-<name>.md
.grimoire/bag/{drafts,runs,reviews,worktrees}/    git-ignored — drafts, run ledgers, review screenshots, worktrees
```

`grimoire-init` guarantees the three ignore lines (`.grimoire/pages/`, `.grimoire/constructs/`, `.grimoire/bag/`) in the project's `.gitignore` under a `# Grimoire` block (`§ Documentation`). There is no recency log and no archive: status lives in labels (GitHub) or in frontmatter (local). "Recent context", for any skill that wants it, is the last 5 folders of `.grimoire/pages/` by `NNN` descending (frontmatter + Goals) locally; on GitHub the Grimoire-labelled issues serve the same purpose.

**Page folder** (local mode; plan cache in GitHub mode).
- Path: `.grimoire/pages/NNN-<slug>/` locally — `NNN` is incremental and chronological across the whole project (`001`, `002`, `003`, …), scanned from `.grimoire/pages/`; `.grimoire/pages/<issue>-<slug>/` in GitHub mode (cache only, `§ Backends`).
- Created by `grimoire-spec` (local) when the page is first specified; in GitHub mode (cache only) by `grimoire-plan` / the auto-planner when they write the plan, or by `grimoire-execute` when re-materializing the cache. `grimoire-plan` and `grimoire-execute` never create a *page* — they look an existing one up by number.
- `SPEC.md` — the page specification (Context, Goals, Non-goals, Scope, Acceptance criteria, Constraints, Open questions, References to code). Written by `grimoire-spec`, consumed by `grimoire-plan` / the auto-planner. Local mode only — on GitHub the SPEC is the issue body and is never cached.
- `K-<step>.md` — sequential, page-scoped step files `1-<step>.md`, `2-<step>.md`, … Written by `grimoire-plan` or the auto-planner in both modes — locally the plan of record; on GitHub the cache `.grimoire/pages/<N>-<slug>/K-<step>.md` of the plan comment, which `grimoire-execute` re-materializes when absent. A simple page has one step file; a larger page has several — the planner chooses the count by projected context lucidity per step. Step files MAY carry YAML frontmatter per `§ Parallel execution`.
- `REVIEW.md` — local mode only: the verdict + `## Human validation`, written by the `§ Review loop` where GitHub mode posts a verdict comment and fills the PR body.
- `PLAN.md` — local mode only: the counterpart of the plan comment — the marker line `<!-- grimoire:plan v=1 -->`, `## Assumptions`, and a one-line overview per step (the `K-<step>.md` files remain the executable units). Written by `grimoire-plan` and the auto-planner.
- `NOTES.md` — local mode only, optional: free-form human notes, the counterpart of issue / PR comments. `grimoire-execute` reads the whole file on resume (`§ Review loop`); only the human writes or clears it.
- The folder, its `SPEC.md`, and its step files stay in place after execution. **Nothing is moved; nothing is committed.**

**Status frontmatter (local mode)** — the first lines of each file; it is the status-of-record:

```
SPEC.md
---
status: spec | planned | review | blocked
construct: NNN                  # optional — parent construct
depends-on: [NNN, …]            # optional — pages this page depends on
branch: grimoire/NNN-<slug>     # set by grimoire-execute
base: <branch>                  # set by grimoire-execute — the base the page branch was created from (§ Backends)
pr: <url>                       # optional
phase: steps | review           # set by grimoire-execute — steps when the page branch is created, review when review round 1 starts
---

CONSTRUCT.md
---
status: open | done
---

references/N-<short-name>.md
---
status: pending | specced
page: NNN                       # set when specced
depends-on: [N, …]              # optional — earlier references (lower numbers) this one depends on
---
```

- `status` on `SPEC.md` progresses `spec` → `planned` → `review`; `blocked` is the stop state the `§ Review loop` sets when rounds are exhausted or the execution failed (a resume takes it back to `planned` and into the loop). `review` is **terminal** locally — there is no merge detection. `phase` is the local analog of "a draft PR exists" in resume mode (`§ Review loop`), with a deliberate asymmetry: on GitHub a draft PR exists from the first step commit (a mid-steps death continues through the review cycle), while `phase: review` is set only after all steps landed (a mid-steps death resets and re-runs the steps).
- `CONSTRUCT.md` `status: done` means **no reference is `pending`**. It is written by `grimoire-spec` in the same write as the last reference flip (consumption of the last pending reference — `§ Construct`). There is no GitHub equivalent: the milestone is closed by the human.
- Writers of frontmatter: `grimoire-spec` (`status: spec`, `construct`, `depends-on`), `grimoire-plan` / the auto-planner (`planned`), `grimoire-execute` / `grimoire-run` (`branch`, `base`, `pr`, `phase`, `review`, `blocked`), `grimoire-construct` / `grimoire-construct-update` (construct and reference files), `grimoire-spec` (`specced`, `page`, and the derived `CONSTRUCT.md` `status: done`).
- **Legacy pages (0.13) without frontmatter.** Skills infer the status from the files present — only `SPEC.md` → `spec`; step files → `planned`; `REVIEW.md` → `review` — and stamp the frontmatter on their first write to the file. The migration run by `grimoire-init` (`§ Documentation`) stamps every legacy page and construct in one batch.

**Construct folder (local mode).** `.grimoire/constructs/NNN-<name>/` with `CONSTRUCT.md` at the root plus `references/N-<short-name>.md` in execution order. `NNN` is an **independent incremental counter** scanned from `.grimoire/constructs/` — it does not share or collide with the `pages/` counter. Full rules in `§ Construct`.

**`.grimoire/bag/`** — ephemeral, git-ignored, never committed:
- `drafts/` — IDE-review drafts (`§ IDE-aware review`), the construct handoff brief (`§ Construct`), the `grimoire-deps` upgrade brief.
- `runs/` — `grimoire-run` ledgers `<construct>-<epoch>.md` (`§ Run`).
- `reviews/page-<N>/round-<r>/` — reviewer screenshots (`§ Review loop`).
- `worktrees/page-<N>/` and `worktrees/page-<N>-step-<K>/` — page and step worktrees, always torn down at the end of a run (`§ Parallel execution`, `§ Review loop`).

**Committed context.** `.grimoire/PROJECT.md` and `.grimoire/config.toml` are the only committed files; their writers and formats live in `§ Documentation` and `§ Configuration`.

---

## § Documentation

This section is the **single source of truth** for project context — the neutral `docs/` folder, the `.grimoire/PROJECT.md` index, who writes them, and the `[Required Reading]` order every skill follows. SKILL.md bodies reference it; they never restate these rules.

**`docs/` — neutral, human-owned.** The project's documentation lives in `[docs].dir` (default `docs/`) with **zero Grimoire vocabulary** — it is the project's own documentation, usable by any human or tool. Four canonical files:
- `overview.md` — purpose, audience, stage.
- `architecture.md` — stack, repository layout, key modules.
- `conventions.md` — code rules, constraints, notes.
- `development.md` — install / run / test / build / lint (mirrors `[verify]`).

Language: `[docs].language` — asked once by `grimoire-init`, or inferred from the README.

**`.grimoire/PROJECT.md` — index + Grimoire-only rules.** The name is kept; the file is committed; it is an index, not a mirror:

```
# <Project> — Grimoire index

## Documentation
- docs/overview.md — <one line>
- docs/architecture.md — <one line>
- docs/conventions.md — <one line>
- docs/development.md — <one line>

## Grimoire rules
- <rules only the Grimoire agents must obey in this repository>
```

Every further `docs/*` file the project has is indexed with one line too. `## Grimoire rules` holds behaviour rules for the agents (e.g. "never touch `legacy/`") — never code conventions, which belong in `docs/conventions.md`.

**`grimoire-init`.**
- `docs/` exists → index every file with one line, **never rewrite human docs**, and propose only the *missing canonical topics* at the draft-review pause. `docs/` absent → write the four canonical files after the interview.
- Always: ensure the `.gitignore` lines `.grimoire/pages/`, `.grimoire/constructs/`, `.grimoire/bag/` (a `# Grimoire` block; only the missing lines are added); write `.grimoire/config.toml` with the discovered `[verify]` (scripts in `package.json`, lockfile → package manager, `Makefile`, `pyproject`, …; `{port}` emitted when the dev tool accepts a port flag — Vite `--port`, Next `-p`, …) and `[docs]`; in GitHub mode ensure the labels (`§ Backends`).
- The IDE-aware draft covers `docs/*` (new or proposed files) + the index + `config.toml`.
- **Update mode:** when `.grimoire/PROJECT.md` already exists, read it first and ask only about deltas (what changed or is missing), then rewrite the index in place; `docs/` is touched only to add the missing canonical files the user approved.
- Commits: `docs(grimoire): initialize project context` / `docs(grimoire): update project context` (`§ Commits`).

**Migration of 0.13 repositories.** In update mode, when `grimoire-init` detects `.grimoire/pages/`, `.grimoire/constructs/`, `.grimoire/HISTORIC.md`, or `.grimoire/bag/historic/` **tracked by git**, it proposes the migration at the draft-review pause: stamp `status:` frontmatter on the legacy `SPEC.md` / `CONSTRUCT.md` / `references/*` files (from the `HISTORIC.md` entries and from the files present — `§ .grimoire/ layout`), `git rm -r --cached` the folders that are now ignored, delete `HISTORIC.md` and `bag/historic/`, and commit `chore(grimoire): migrate to 0.14 layout`. It lists the pages still in progress; in GitHub mode it warns that they are no longer addressable by number (numbers are now issue numbers) and suggests re-specifying them with `/grimoire-spec`, pasting the SPEC text. The migration is **never silent** and can be declined — declining leaves everything in place and the skill continues with the rest of its update.

**`grimoire-note`.** Each rule in the note is classified: *how code is written in this repository* → `docs/conventions.md`; *how the Grimoire agents must behave here* → `PROJECT.md` `## Grimoire rules`; ambiguous → asked at the existing draft-review pause. The synthesis discipline (merge, rewrite, generalize, minimum-word phrasing, retroactive consolidation) applies to both targets. Commit: `docs(grimoire): refine project context`.

**Dual-writer contract.**
- `grimoire-init` creates `docs/*` (missing canonical files only), `PROJECT.md` (the whole file), the `.gitignore` lines, `config.toml`, and performs the migration.
- `grimoire-note` writes only `docs/conventions.md` and `PROJECT.md` `## Grimoire rules`, incrementally; it never creates `PROJECT.md` (hard-stop — `§ Pause-point pattern`), never adds sections, never touches the other docs.
- **Every other skill is read-only** on `docs/`, `PROJECT.md`, and `config.toml` — not as a primary action, not as a side effect.
- A missing `PROJECT.md` is non-blocking for every skill except `grimoire-note`: proceed without it and, at the end of the run, remind the user that running `grimoire-init` once gives future Grimoire sessions richer context.

**`[Required Reading]` — the order every skill follows.**
1. `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md` (this file) — the sections the skill depends on.
2. `.grimoire/PROJECT.md` (the index), then the links the task needs: `docs/conventions.md` **always**; `docs/architecture.md` for planning and execution (`grimoire-plan`, `grimoire-execute`, `grimoire-run`, and their `plan` / `execute` sub-agents); `docs/development.md` for execution and review (the `execute`, `fix`, and `review` roles).
3. `.grimoire/config.toml` + the global `${GRIMOIRE_HOME}/config.toml` (`§ Configuration`).
4. Backend detection and announcement (`§ Backends`).

Sub-agents receive the same pointers in their prompt (which docs to read for their role) — the orchestrator never pastes the docs into the prompt.

---

## § Construct

This section is the **single source of truth** for constructs — SKILL.md bodies reference it; they never restate these rules.

**Definition.** A **construct** is a larger-than-a-page objective decomposed into an *ordered, flat list of reference-seeds*. Each reference is later expanded — through the normal full `grimoire-spec` interview — into one real **page**; `grimoire-run` does that for every pending reference in sequence and then executes the pages (`§ Run`). The construct is the roadmap-of-record; the pages it spawns are the actual work. Constructs are **flat and self-contained**: no nested constructs, no sub-references, no construct-of-constructs. A construct is never a page and never produces a commit of its own.

**Storage per backend.**

| | GitHub | Local |
|---|---|---|
| construct | a **milestone** — title = name; description = `<!-- grimoire:construct v=1 -->` + intro / arc / research findings + `## References`, a numbered list in execution order (`§ Backends`) | `.grimoire/constructs/NNN-<name>/CONSTRUCT.md` — frontmatter `status: open \| done`, the intro, the ordered reference checklist |
| reference | one **issue per reference, created immediately** by `grimoire-construct`: label `grimoire:reference`, header `<!-- grimoire:page v=1 construct=#M order=N depends-on=… -->`, body = the seed. The issue number **is** the future page number | `references/N-<short-name>.md` — frontmatter `status: pending \| specced` and `page: NNN` once specced; body = the seed |
| order | position in the milestone's `## References` list | file number `N-` and checklist position |
| dependencies | `depends-on=` in each reference header (optional, issue numbers), mirrored as `(after #…)` in the list | `depends-on: [N, …]` in the reference frontmatter (reference numbers), translated into page numbers in the spawned page's `SPEC.md` frontmatter |
| identifier | milestone number (exact title also accepted) | `NNN` (independent counter) or `<name>` |

**Reference status** is binary. **Pending** = label `grimoire:reference` (GitHub) / `status: pending` (local). **Specced** = any other Grimoire status label — the issue has become a page — (GitHub) / `status: specced` + `page:` (local). There is no "page finished" state at the construct level: page progress is read from the page itself.

**Local checklist format** (`CONSTRUCT.md`), one entry per reference:
`N. [pending] <short description> → references/N-<short-name>.md`
`N. [specced] <short description> → references/N-<short-name>.md (page 007)`

The frontmatter `status` fields of `references/*` are the **record**; the checklist tokens are **derived** from them and rewritten whenever a frontmatter status changes.

**`depends-on` between references.** The research of `grimoire-construct` proposes the order **and** the dependencies between references when some are independent of each other; the user confirms them in the interview. They become the page DAG of `§ Run`; a construct with no `depends-on` at all runs as an implicit chain. Locally a reference may only depend on **earlier** references (lower numbers) — `grimoire-construct` and `grimoire-construct-update` validate this; on GitHub the header carries issue numbers from creation, so no translation is ever needed.

**Writer contract.**
- **`grimoire-construct`** creates a construct from scratch — milestone + reference issues, or folder + files. It is the only skill that brings a construct into existence from a free-text objective.
- **`grimoire-construct-update`** alters an **existing** construct in place per the Alteration rules below. It never creates a construct and hard-stops when the target does not exist (`§ Pause-point pattern`). It is the construct analog of `grimoire-note`.
- **`grimoire-adopt`** (GitHub only) turns an existing milestone into a construct: marker + intro + ordered list written into the description; the milestone's existing issues become references (header added, label `grimoire:reference`, original text preserved under `<details><summary>Original issue text</summary>`); gaps become new reference issues. It never specifies a reference by itself.
- **`grimoire-spec`** makes exactly one kind of construct edit — consuming a reference: on GitHub it rewrites the reference issue's body into the page SPEC (marker preserved) and swaps `grimoire:reference` for `grimoire:spec`; locally it flips the reference to `specced` with the page backlink **and, when that was the last pending reference, sets `CONSTRUCT.md` `status: done` in the same write**. A surgical status change — the reference flip plus the derived construct `status` — never authoring.
- **All other skills** never touch construct objects.

**Consumption** (`grimoire-spec` bare-number mode; also what `grimoire-run` Phase 1 invokes).
- Consumption is **strictly the first pending reference in list order** — GitHub: the first `## References` entry whose issue still carries `grimoire:reference`; local: the lowest-numbered `[pending]`. No out-of-order pick, no user pick in v1.
- Not found → hard-stop, no page created. Fully specified (no pending reference left) → hard-stop, no page created. Messages in `§ Pause-point pattern`.
- On a successful consumption the reference seeds the **full** `grimoire-spec` interview; the result is a normal page that names its parent construct (`construct=#M` in the header / `construct: NNN` in the frontmatter) and inherits the reference's `depends-on` — locally `grimoire-spec` translates each reference number into that reference's `page:` value when writing the page's `SPEC.md` `depends-on` (always resolvable, because consumption is in order); on GitHub the issue numbers carry over unchanged. Then the reference is marked specced. No commit (`§ Commits`).
- **No size re-evaluation at consumption time** — references are authored page-sized by `grimoire-construct`.

**Alteration rules** (`grimoire-construct-update`). This subsection is the single source of truth for how an existing construct may be modified in place.
- **Locked prefix invariant.** Because consumption always takes the first pending reference, the specced references form an immutable leading prefix. A specced reference — GitHub: label ≠ `grimoire:reference`; local: `status: specced` — **cannot be edited, removed, or reordered**, and **no reference may be inserted ahead of one**. The refusal names the reference and its page (`§ Pause-point pattern`).
- **Permitted operations**, all confined to the pending tail or to construct-level metadata:
  - **Add** — GitHub: create the reference issue (issue create, `§ Backends` cheat sheet) and insert it into the list after the last locked entry or at the requested pending position; local: add the file and the checklist entry.
  - **Remove** — GitHub: remove the milestone, add `grimoire:dropped`, close the issue (the removal command of the `§ Backends` cheat sheet), then drop the list entry; local: delete the file and the entry. Dependencies that pointed at the removed reference are dropped from the remaining headers / frontmatter.
  - **Reorder** — rewrite the list (and the `order=` fields) within the pending tail only.
  - **Edit reference detail** — rewrite the pending reference's issue body / `references/N-*.md` and its one-line entry.
  - **Edit construct intro / objective** — rewrite the description / `CONSTRUCT.md` header (not the list).
  - **Rename** — GitHub: `PATCH` the milestone title; local: a plain filesystem `mv` of the folder to the new `<name>` **preserving `NNN`**, updating internal self-references (the folder is git-ignored — no git operation, no commit).
- **Numbering after a structural change.** Local: the pending tail's `references/N-*.md` files and checklist entries are **renumbered contiguously** in execution order and every `depends-on` value is rewritten to the new numbers; the specced prefix never moves. GitHub: **no renumbering** — issue numbers are permanent; the order is the list position, and only the `order=` header fields of the pending tail are rewritten.
- **Resolution / hard-stop.** The target is resolved by milestone number or exact title (GitHub) / `NNN` or `<name>` (local). Not found → hard-stop (`§ Pause-point pattern`).
- No commit (`§ Commits`).

**Self-containment.** A construct is never listed as work of its own: only the pages it spawns carry status, branches, and PRs, and each spawned page points back at its construct. Construct progress is readable from the milestone's list + its issues' labels (GitHub) or from `CONSTRUCT.md` + the `references/*` frontmatter (local).

**Size-evaluation trigger & handoff-brief contract.** When `grimoire-spec` (new-page mode) judges a free-text request **too large for a single page**, it recommends creating a construct. On user approval it writes a **handoff brief** — the best possible prompt to feed `grimoire-construct` — to `.grimoire/bag/drafts/construct-brief-<epoch>.md` (epoch = Unix seconds at write time) and **STOPS without creating a page**, instructing the user to start a fresh, clean-context session and run `/grimoire-construct` with that brief. The brief **persists** (it is consumed by a different, clean-context session) — `grimoire-spec` never auto-deletes it; `grimoire-construct` deletes it after successfully creating the construct. On decline, `grimoire-spec` proceeds as a normal large page.

`grimoire-adopt` applies the same contract to an issue judged too large for one page: it recommends a construct and PAUSES; on approval it writes `.grimoire/bag/drafts/construct-brief-<epoch>.md`, seeded with the issue text and the interview's findings, and STOPS leaving the issue untouched, telling the user to run `/grimoire-construct` with the brief in a fresh session; on decline it continues adopting the issue as one page. `grimoire-construct` deletes the brief after use, as above.

---

## § Review loop

This section is the **single source of truth** for how a page is executed and reviewed — by `grimoire-execute` directly, and by `grimoire-run` for every page of a construct (`§ Run`). SKILL.md bodies reference it; they never restate these rules.

### The page worktree

- A page **always** executes inside its own worktree: `.grimoire/bag/worktrees/page-<N>/`, checked out on the page branch `<branch_prefix>/<N>-<slug>` (default `grimoire/<N>-<slug>`), created from the base computed per `§ Backends` (base branch and stacking rule). The user's working tree **never** changes branch.
- Parallel steps use nested step worktrees `page-<N>-step-<K>/` branched from the page branch and cherry-picked back **into the page worktree** — exactly per `§ Parallel execution`. The page worktree is the reference workspace of the run.
- `[verify].install_command` runs **once per page worktree**, before any test or dev server.
- **Unconditional teardown** (try/finally): when a page's execution ends — approved, blocked, failed, or aborted — no `page-<N>/` and no `page-<N>-step-*` worktree of **that page** remains (other pages may still be running under `grimoire-run`); at the end of the whole invocation — `grimoire-execute` standalone, or `grimoire-run` as a whole — `.grimoire/bag/worktrees/` is empty and `git worktree list` shows only the main workspace. The **branch remains** (and is pushed whenever a remote exists); any dev server the reviewer started is killed.
- **`grimoire-execute` never deletes a branch and never closes a PR.** The only history rewrite it performs is the reset of resume mode below; the only branch deletion in the whole design belongs to `§ Run`.

### Hard-stops

After backend detection and configuration (`§ Pause-point pattern` holds the literal messages): page not found; an issue without the page marker (not managed by Grimoire); page still a `reference` (never specified); page already in `review` (PR pending human review); page closed (finished); a `depends-on` page that has never been executed — `spec` / `planned` with no branch; a `depends-on` page that is `blocked` (the human resumes it first); a cyclic or dangling step `depends-on`. A `blocked` page is **not** a hard-stop: it proceeds in resume mode, announced.

### Resume mode

Resume applies whenever the page branch `grimoire/<N>-<slug>` already exists — the page is `blocked`, a previous execution was interrupted, or the work was started on another machine. It announces `▶ Resuming page N on existing branch <branch>` and:
- reuses the existing branch and draft PR; a plan already posted is **not** re-planned; a PR that is closed but **not merged** counts as no draft PR — a new draft PR is opened when the first step lands;
- reads the **human comments on the issue and on the PR newer than the last Grimoire-authored comment** (a verdict or a `⛔` comment; when there is none, every human comment since the plan comment) and hands them to the fixer and to the reviewer — locally the whole `NOTES.md` of the page folder plays that role, and the plan's `## Assumptions` come from `PLAN.md` (`§ .grimoire/ layout`); when there are unresolved blocking findings or new comments, the round starts with the **fixer**;
- restarts the review cycle at **round 1**;
- removes `grimoire:blocked` (local: `status: blocked` → `planned`) when the round starts;
- **never re-executes steps.** When the previous execution died in the middle of the steps and **no draft PR exists**, the page is re-executed from scratch **on the same branch**: the branch is reset to its base (`git reset --hard <base>`) and every step runs again — allowed because the branch was never marked ready. This is the only history rewrite `grimoire-execute` performs. With a draft PR present, the remaining work is driven by the review cycle (scope findings → fixer). Locally the analog of "a draft PR exists" is `SPEC.md` `phase: review`; `phase: steps` (or absent) with an existing branch means the execution died mid-steps → the reset-and-rerun rule above. The asymmetry is deliberate: on GitHub the draft PR exists from the first step commit, so a mid-steps death continues through the review cycle; locally `phase: review` is set only after all steps landed, so a mid-steps death resets and re-runs the steps.

### Phases

1. **Resolve.** Resolve the page; load the SPEC (issue body / `SPEC.md`), the plan (latest plan comment → local cache / local `PLAN.md` + step files), the configuration, and — in resume — the new human comments.
2. **Auto-plan**, when the page is in `spec` status: spawn a `plan` sub-agent (`§ Sub-agent spawning`) that plans **without an interview** — every unresolved choice goes into `## Assumptions`; the step DAG is validated (cycle / dangling check); `touches` overlap between parallel siblings becomes a note in the plan; the plan is posted as a plan comment (GitHub) or written as local step files + `PLAN.md`; status → `planned`. A user who wants to steer the plan runs `/grimoire-plan <N>` beforehand.
3. **Branch / worktree.** Create the page branch from its base and the page worktree — or enter resume mode.
4. **Steps** per `§ Parallel execution` (strict serial or waves), each step an `execute` sub-agent committing per `§ TDD` / `§ Commits`. After the **first step commit reaches the page branch**: `git push -u` and open the **draft PR** (body template in `§ Backends`). From this point on **no question is asked to the user**. A failed step follows the failure semantics of `§ Parallel execution`: within that execution the page never enters the review cycle with missing steps — it ends `blocked` (a later resume with a draft PR present completes the work through the review cycle, see resume mode).
5. **Review cycle**, rounds `1..[review].max_rounds` (default 3) — below.
6. **Final state:** `review` or `blocked`. GitHub: labels + PR state. Local: `REVIEW.md` in the page folder + the `SPEC.md` frontmatter. No state commit; nothing else is written.

### The reviewer

One `review` sub-agent per round. It reads and runs — tests, dev server, `agent-browser` — and is **instructed to never edit code** (no harness offers a per-call tool allowlist — `§ Harness adaptation`).

**Inputs:** the SPEC; the plan including `## Assumptions`; `git diff <base>...<branch>`; the PR number; the new human comments (resume); `[verify]`; `[review].ui_globs`.

**Checks, in this order:**
- **(a) Scope** — every acceptance criterion of the SPEC is mapped to code and tests in the diff; a missing or partial criterion is blocking.
- **(b) `ponytail-review`** over the change — correct / secure / holds under load / tested / fast / lean (this covers "is this the simplest form?"). Composed per `§ Skill composition`; when the helper is not installed the reviewer applies the same six questions itself and says so.
- **(c) Full gate** — `test_command`, `build_command`, `lint_command` from `[verify]`, run in the page worktree. The whole suite, not a filter: a PR has global blast radius (the documented exception to `§ TDD`, like `grimoire-deps`). Any failure is blocking.
- **(d) UI** — only when at least one changed file matches `[review].ui_globs`:
  - **A fresh dev server, always, started in the page worktree.** Never reuse a server that already answers — it would be the user's tree, without the page's code. The port is allocated per page through the `{port}` placeholder in `[verify].dev_command` / `dev_url` (`§ Configuration`). Without the placeholder, UI reviews are **serialized** across pages (a mutex in the run ledger — `§ Run`) and, when the port is already taken, the review proceeds **without a browser** and records `UI not verified in a browser: port in use` under human-validation. Wait for `dev_url` to answer; kill the process when the review ends.
  - Open the affected routes with **`agent-browser`**: accessibility snapshot, console errors, and a screenshot saved locally under `.grimoire/bag/reviews/page-<N>/round-<r>/` (never uploaded — `gh` attaches no images).
  - Apply **`impeccable`** (craft: hierarchy, accessibility, consistency) to every reviewed surface, and **`revenue-centric-design`** only to conversion / onboarding / pricing / checkout surfaces.
  - Check **design-system conformance by reading the project itself**: the components directory, the closest sibling screen, the tokens / theme.
  - A missing helper (`agent-browser`, `impeccable`, `revenue-centric-design`) degrades that check to a "not verified" line under human-validation — never a failure.

**Verdict** — the final block of the report, posted as a PR comment under the `<!-- grimoire:verdict round=N -->` marker (local: appended to `REVIEW.md`):

```
verdict: approve | changes-requested
blocking:
- [scope|security|correctness|simplicity|ui|tests] <file:line> — <finding> — <expected fix>
advisory:
- [scope|security|correctness|simplicity|ui|tests] <file:line> — <finding> — <suggested fix>
human-validation:
- <concrete manual step>
- <what could not be verified, and why>
- <merge order, when the PR is stacked>
```

`changes-requested` requires at least one blocking entry; `approve` has none.

### Rounds, fixer, outcome

- **`changes-requested`** → spawn a **fixer** (`fix` role): a fresh sub-agent on the page branch, inside the page worktree, no step worktree. It receives the SPEC, the plan, the blocking **and** advisory findings, and the new human comments; it makes atomic commits (`§ Commits`) and pushes. The next round spawns a fresh reviewer.
- **`approve`** → the reviewer rewrites `## Summary` and fills `## Human validation` in the PR body (`gh pr edit --body-file`); then `gh pr ready`, status label → `grimoire:review` (`grimoire:blocked` removed if present), remaining advisories listed under `## Known advisories`, one line per round under `## Review log`. Local: `REVIEW.md` holds the same sections; `status: review`.
- **Rounds exhausted** (`max_rounds` reached without approval) → label `grimoire:blocked` (coexists with `grimoire:planned`), the PR **stays draft**, and a `⛔` comment — on the PR when one exists, otherwise on the issue — lists the unresolved blocking findings **and the way back**:

  ```
  ⛔ Page N is blocked after R review rounds.
  Unresolved blocking findings:
  - [<category>] <file:line> — <finding> — <expected fix>
  Reply on the issue or on the PR and run `/grimoire-execute N` to resume.
  ```

  Local: `status: blocked` + the same block in `REVIEW.md`. The same outcome applies when the steps fail (`§ Parallel execution`) — the comment then lists the failed steps and goes to the issue when no PR exists.
- **No questions after the draft PR.** An ambiguity found after that point becomes a planner assumption or a `blocked` outcome with the question inside the `⛔` comment; the human answers there and resumes with `/grimoire-execute N`.

---

## § Run

This section is the **single source of truth** for `grimoire-run <construct>` — executing a whole construct end to end. SKILL.md bodies reference it; they never restate these rules.

**Hard-stops.** Construct not found; nothing to run — no pending reference and no runnable page: every page is in `review`, closed, or `blocked` (`blocked` pages are not runnable here; the message names them); page-DAG validation before the boundary — a cycle between pages, or a `depends-on` pointing at a page that does not exist. Messages in `§ Pause-point pattern`.

**Phase 1 — interactive (spec interviews).** For every pending reference in list order, invoke `grimoire-spec` in consumption mode (Grimoire-on-Grimoire — `§ Skill composition`; its hard-stops and pauses hold). The user may answer "skip the rest" at any interview: the remaining references stay `reference` and — together with their transitive dependents — are left out of Phase 2. **Abandoning a consumption draft counts as "skip the rest"**: that reference stays `reference`, it and its transitive dependents are excluded from Phase 2, and the run proceeds to the boundary with the pages already specced. When no reference is pending, Phase 1 is empty and the run goes straight to the boundary line.

**The boundary.** `🚀 Autonomous phase: N pages, K waves — you can leave.` — `N` = the pages that will run, `K` = the waves. **No question is asked after this line.**

**Phase 2 — autonomous.**
- **Page DAG.** Nodes = the construct's pages that are not in `review`, closed, `skipped`, or `blocked` — a `blocked` page is excluded (the human resumes it individually with `/grimoire-execute N`) and its transitive dependents are `skipped`. Edges = the pages' `depends-on` headers (frontmatter locally) when **any** page carries one; otherwise an **implicit chain** — each page depends on the previous one in list order. Pages already in `review` or closed count as satisfied dependencies.
- **Waves** are Kahn levels — the same algorithm as `§ Parallel execution`, at page level. The members of a wave run **concurrently**, at most `[run].page_parallelism` at a time (default 2; `0` = unlimited), each one through the full `§ Review loop` protocol: auto-plan → branch / worktree → steps → draft PR → review rounds → `review` or `blocked`.
- **Flat orchestration.** The session agent dispatches, watches, and records — it **never implements** (`§ Sub-agent spawning`). It spawns every per-page sub-agent itself; there is no orchestrator inside a sub-agent.
- **Bases and stacking** per `§ Backends`: a page whose dependency is not yet integrated (PR not merged on GitHub; branch not an ancestor of the base locally) is branched from that dependency's branch (stacked PR). The run never waits for a human merge.
- **Blocked propagation.** Every `blocked` outcome — rounds exhausted, step failure, watchdog — marks the page's transitive dependents `skipped`; independent pages continue.
- **UI reviews** are serialized across pages when `[verify]` has no `{port}` placeholder — a mutex recorded in the ledger.

**Ledger** — `.grimoire/bag/runs/<construct>-<epoch>.md`, rewritten at every transition. `<construct>` is the milestone number on GitHub and `NNN` locally; `<epoch>` is Unix seconds at creation; the file stem `<construct>-<epoch>` is the **run id**.
- frontmatter: `construct`, `backend`, `started`, the model / effort snapshot per role, `max_rounds`;
- a table `page | wave | phase | branch | base | pr | updated | note`, with `phase ∈ pending | planning | executing k/n | reviewing r/R | review | blocked | skipped`.

**Resume.** Re-invoking `grimoire-run` for a construct that has an unfinished ledger announces `▶ Resuming run <id>` (`<id>` = the ledger's run id) and continues from the ledger. A resumed run **never re-runs Phase 1** — no re-interview — and its page set is exactly the ledger's:
- `review`, `blocked`, `skipped` → untouched (a `blocked` page is resumed individually by the human through `/grimoire-execute N` after answering);
- `planning` → planning restarts;
- `executing` → the previous attempt died in the middle of the steps. The branch is Grimoire's own — proven by the ledger, never marked ready — so the run first tears down that page's leftover worktrees (`page-<N>/`, `page-<N>-step-*`) per the per-page teardown invariant of `§ Review loop`, then closes the draft PR if one exists, **deletes the branch** — locally and, when a remote exists, remotely (`git push origin --delete <branch>`) — and re-executes the page from scratch on a new branch that reuses the deterministic name `grimoire/<N>-<slug>`. This is the **only** destructive git operation in the whole design; it exists here and never in `grimoire-execute`;
- `reviewing` → the review cycle restarts at round 1 on the existing branch (resume mode of `§ Review loop`).

A finished ledger (every page terminal) is never resumed; a new invocation starts a new ledger for whatever is still pending.

**Watchdog.** `[run].step_timeout_minutes` (default 45) per step sub-agent and per `plan` (auto-plan) sub-agent; `[run].review_timeout_minutes` (default 30) per review / fix sub-agent. Timeout or crash → **one** retry with a fresh sub-agent fed with the failure context; a second failure → the page becomes `blocked` (label + `⛔` comment on the PR when one exists, otherwise on the issue), its transitive dependents become `skipped`, and independent pages continue. Enforcement is best-effort per harness (`§ Harness adaptation`).

**Stop.** The run stops when every page is in `review`, `blocked`, or `skipped`. Each page tears down its own worktrees when its execution ends (`§ Review loop`); when the run stops, `.grimoire/bag/worktrees/` is empty and `git worktree list` shows only the main workspace — the same try/finally invariant as `§ Parallel execution`, at run level. Final summary: a table `page / PR / state / merge order / pointer to Human validation`.

---

## § IDE-aware review

When a skill must show the user a draft, plan, or other markdown content for review before proceeding (e.g., `PROJECT.md` draft, `SPEC.md` draft, `grimoire-quick` plan, `grimoire-update` changelog), prefer rendered markdown in the user's IDE over inline chat text. Inline chat text is hard to scan and has no markdown rendering; an open file in the IDE has both.

**Detection.** Inspect the runtime context for signals that Claude Code is running inside a desktop IDE extension (VSCode native extension, JetBrains plugin, Cursor, etc.). The system context block usually announces this explicitly (e.g., a `# VSCode Extension Context` section, or wording like *"running inside a VSCode native extension environment"*). When in doubt, assume terminal-only and use the inline fallback — the inline path is always safe.

**IDE-aware flow.**

1. Write the reviewable content to disk so the IDE auto-surfaces it with markdown preview:
   - `grimoire-init` → `.grimoire/PROJECT.md`, the `docs/*` files it proposes, and `.grimoire/config.toml` (final destinations).
   - `grimoire-spec` → local mode: `.grimoire/pages/NNN-[page-name]/SPEC.md` (create the page folder first if needed — final destination); GitHub mode: `.grimoire/bag/drafts/spec-<epoch>.md` (throwaway — the approved text becomes the issue body).
   - `grimoire-plan` → local mode: `PLAN.md` and the step files in the page folder (final destination); GitHub mode: `.grimoire/bag/drafts/plan-<epoch>.md` (throwaway — the approved step files become the plan comment).
   - `grimoire-construct` / `grimoire-construct-update` → local mode: the construct files (final destination); GitHub mode: `.grimoire/bag/drafts/construct-<epoch>.md` (throwaway — becomes the milestone + reference issues, or the alteration).
   - `grimoire-adopt` → `.grimoire/bag/drafts/adopt-<epoch>.md` (throwaway — becomes the issue body / milestone description).
   - `grimoire-quick` → `.grimoire/bag/drafts/quick-plan-<epoch>.md` (create the folder if needed; this is a throwaway draft, not a final artifact).
   - `grimoire-update` → `.grimoire/bag/drafts/grimoire-update-changelog-<epoch>.md` (same — throwaway).

   For the ephemeral drafts above (`spec`, `plan`, `construct`, `adopt`, `quick-plan`, `grimoire-update-changelog`), generate `<epoch>` as a Unix timestamp in seconds (`$(date +%s)`) at the moment of writing and memorize the resulting path for use during cleanup. This defeats the VSCode markdown preview cache, which keys on file path — without the suffix, a second invocation can show the stale preview from the prior run. The final-destination drafts (`PROJECT.md`, local `SPEC.md`, local step and construct files) keep their canonical names.
2. Tell the user in one short line which file was opened and what answer you're waiting for. Example: `📄 Draft opened at .grimoire/PROJECT.md — review it in the editor and say "ok" to proceed, or list changes.`
3. PAUSE for the user's confirmation or edits — same semantics as the inline flow.
4. On approval:
   - final-destination drafts (`grimoire-init`; `grimoire-spec`, `grimoire-plan`, `grimoire-construct`, `grimoire-construct-update` in local mode): the file is already at the final path — proceed (for `grimoire-init`, straight to the commit phase). **No additional Write step needed.**
   - throwaway drafts (`grimoire-quick`, `grimoire-update`, and the `spec` / `plan` / `construct` / `adopt` drafts): perform the write the draft stood for (issue, comment, milestone — nothing for `quick` / `update`), then delete the draft file from `.grimoire/bag/drafts/` and proceed. **Every throwaway draft is deleted after use.**
5. On requested edits: edit the file in place and re-pause.
6. On abandonment: every skill deletes whatever its draft created — the throwaway draft and any final-destination files (spec, plan, construct, adopt, init alike), since they were never approved — leaving an uncommitted, unapproved file pollutes the repo.
7. **In-place edits of existing git-ignored files** (local `grimoire-construct-update`, local `grimoire-plan` re-plans): git cannot restore them, so before the first edit back the affected files up to `.grimoire/bag/drafts/<skill>-backup-<epoch>/` — `construct-update-backup-<epoch>/` for `grimoire-construct-update`, `plan-backup-<epoch>/` for a `grimoire-plan` re-plan; on abandonment restore the folder from the backup (undoing any rename); on approval delete the backup.

**Inline fallback (terminal-only).** When the IDE is not detected, paste the rendered draft inline in chat (legacy behavior). Pause semantics, approval gating, and downstream commit timing are identical to the IDE-aware flow.

**Commit timing.** Files written for review remain uncommitted until the user approves. The existing commit phases in each skill run unchanged AFTER approval — there is no separate "draft commit" and no cleanup commit.

---

## § User-facing language

Grimoire's hardcoded operator-facing strings are authored in English, but what the user actually sees in the terminal is rendered in the user's own language. The English source is a translatable template, not the literal output.

- **Source-string rule.** Every hardcoded operator-facing string in a skill body or in this conventions file is written in English. This includes the `❌` hard-stop messages, the `📄` IDE-review lines, the `🔗` / `📁` backend lines, the `▶` resume and `🚀` boundary announcements, the `⛔` blocked notices, the `🧩` helper announcements, and any other prose addressed to the operator.
- **Runtime-rendering rule.** When a skill communicates with the user, it renders all natural-language prose in the user's native language, treating the English source string as a template to translate. This applies to every skill and to every operator-facing message — hard-stops, pauses, clarifying questions, summaries, and status lines alike.
- **Detection rule.** Determine the user's language in this order: (1) the language the user wrote in during the current session — the primary signal; (2) the OS / system locale, when the session input is insufficient to tell; (3) English, as the final fallback when neither is determinable.
- **Localization boundary.** Localize only the natural-language prose. Preserve verbatim: command names (`/grimoire-spec`, `/grimoire-plan`, …), status tokens (label names such as `grimoire:spec`, frontmatter values such as `status: planned`, `[pending]` / `[specced]`), page/identifier placeholders (`NNN`, `#42`, page names), file paths, and the `❌` / `📄` / `🧩` / `🔗` / `📁` / `🚀` / `▶` / `⛔` glyphs. A localized message keeps the same glyph, the same literal tokens, and the same control-flow meaning — only the surrounding prose changes language.
- **Non-operator-facing content stays English.** Commit messages, `SPEC.md` / step-file / `CONSTRUCT.md` content, issue / milestone / PR bodies and the plan, verdict, and `⛔` comments, code, and identifiers are always English regardless of the user's language (see `§ Commits`).

---

## § Pause-point pattern

Grimoire skills must pause and wait for the user at well-defined checkpoints. Never proceed past a pause silently.

**General rules.**
- A **hard-stop** prints its literal `❌` message, changes nothing, never offers to run the other skill automatically, and never silently fixes the state.
- `N` in a message is the identifier the user typed, rendered as the backend's identifier: the issue / milestone number on GitHub (`#42`), the zero-padded `NNN` locally (`§ Backends`). `#M` / `#X` are likewise issue / PR numbers.
- **Backend hard-stop (every skill):** `[github].mode = "on"` and `gh auth status` fails → `❌ GitHub backend required but gh is not authenticated.` The backend announcement itself (`🔗` / `📁`) is not a pause. Configuration never hard-stops (`§ Configuration`).
- The write / scope gate of `§ Skill composition` folds into the nearest existing pause below — it never adds a pause of its own.
- **After a draft PR exists for a page, nothing more is asked about that page within that execution** — `grimoire-execute` and `grimoire-run` finish it with `review` or `blocked` (`§ Review loop`).

**`grimoire-init`**
- **Clarifying questions:** after analyzing the codebase, ask the user only about facts that cannot be inferred from the code (purpose, audience, stage, non-obvious constraints, the docs language). In update mode, ask only about deltas.
- **Draft review:** after composing the proposed `docs/*` files (new or missing canonical ones), the `PROJECT.md` index, and `config.toml`, present them for review per `§ IDE-aware review` and PAUSE for the user's confirmation or edits before locking them in.
- **Migration pause (update mode):** when legacy 0.13 artifacts tracked by git are detected (`§ Documentation`), present the proposed migration — the pages to stamp, the paths to untrack, the files to delete, the in-progress pages affected — at the draft-review pause and PAUSE for an explicit yes. Declinable; never silent.

**`grimoire-spec`**
- **Clarifying questions:** after analyzing the codebase and the user's request (or the reference seed), ask targeted questions about pain, ambiguities, scope, and critical architectural decisions. Answer the user's questions in turn. Iterate until a consensus on what the page must deliver is reached.
- **Draft review:** after composing the proposed SPEC, present it for review per `§ IDE-aware review` and PAUSE for the user's confirmation or edits before writing the issue (GitHub) or locking in `SPEC.md` (local).
- **Size-evaluation pause:** in new-page mode, after codebase analysis, if the request is judged too large for one page, recommend creating a construct and PAUSE for the user's decision. On approval, write the handoff brief per `§ Construct` and STOP without creating a page; on decline, proceed as a normal large page.
- **Construct-consumption hard-stops (HARD STOP):** when invoked in consumption mode (bare-number input), STOP immediately with no page created if:
  - the construct does not exist → `❌ Construct N does not exist. Run /grimoire-construct first.`
  - no reference is pending (construct fully specified) → `❌ Construct N has already been fully specified.`

**`grimoire-plan`**
- **Precondition check (HARD STOP):** before doing anything else, resolve the page (`§ Backends`). STOP immediately with a clear message naming the current state and the skill the user should run instead if:
  - the page does not exist → `❌ Page N does not exist. Run /grimoire-spec first.`
  - GitHub only — the issue exists but its body lacks the page marker (`§ Backends`) → `❌ Issue N is not managed by Grimoire. Run /grimoire-adopt N first.`
  - the page is still a reference (label `grimoire:reference`) → `❌ Page N has not been specified yet. Run /grimoire-spec first.`
  - local only — the page folder has no `SPEC.md` → `❌ Page N has no SPEC.md. Run /grimoire-spec first.`
  - the page is `planned` and its page branch already exists (execution started), or `blocked` (local `status: blocked`; on GitHub `grimoire:blocked` coexists with `grimoire:planned`) → `❌ Page N is already being executed (branch <branch>).` — `grimoire-execute` treats a `blocked` page as a resume. A `planned` page with **no** branch yet MAY be re-planned: print a one-line notice, then post a new plan comment (GitHub) / rewrite the local step files.
  - the page is in `review` → `❌ Page N is already pending human review (PR #X).` — local rendering: `❌ Page N is already pending human review (branch <branch>).`
  - the page is closed → `❌ Page N has already been finished.`
- **Unclear requirements:** after the precondition passes and the SPEC has been read, if a critical architectural decision is still ambiguous, ask clarifying questions before planning.
- **Final clarity check:** immediately before presenting the plan, self-review the planned step breakdown and surface any remaining assumption or open decision. If anything is still unclear (an architectural choice the agent had to guess, a step boundary the SPEC did not anticipate, a tradeoff with no recorded rationale), PAUSE and ask the user using the available question tooling (`§ Harness adaptation`). Skip silently only when the plan is fully unambiguous. **When the planner has decided to emit `depends-on` frontmatter on one or more step files**, the final clarity check MUST also surface the full DAG — each step's `depends-on` set, the computed waves, and any advisory `touches`-overlap warnings between parallel siblings — so the user can veto a suspect parallelization. A cyclic or dangling `depends-on` is never written: the planner fixes the graph before presenting it.
- **Draft review:** present the plan for review per `§ IDE-aware review` — the plan-comment draft (GitHub) or `PLAN.md` + the step files (local) — and PAUSE for the user's confirmation or edits before posting the plan comment (GitHub) or locking in `PLAN.md` + the step files (local).

**`grimoire-execute`**
- **Precondition check (HARD STOP):** after backend detection and configuration, resolve the page. STOP immediately with a clear message if:
  - the page does not exist → `❌ Page N does not exist.`
  - GitHub only — the issue exists but its body lacks the page marker (`§ Backends`) → `❌ Issue N is not managed by Grimoire. Run /grimoire-adopt N first.`
  - the page is still a reference → `❌ Page N has not been specified yet. Run /grimoire-spec first.`
  - local only — the page folder has no `SPEC.md` → `❌ Page N has no SPEC.md. Run /grimoire-spec first.`
  - the page is in `review` → `❌ Page N is already pending human review (PR #X).` — local rendering: `❌ Page N is already pending human review (branch <branch>).`
  - the page is closed → `❌ Page N has already been finished.`
  - a page in its `depends-on` has never been executed (`spec` / `planned`, no branch) → `❌ Page N depends on #M, which has not been executed yet. Run /grimoire-execute M first (or /grimoire-run <construct>).`
  - a page in its `depends-on` is `blocked` → `❌ Page N depends on #M, which is blocked. Resume it with /grimoire-execute M first.`
  - a cyclic `depends-on` graph between steps → `❌ Page N has cyclic dependencies between steps. Run /grimoire-plan N to fix.`
  - a `depends-on` reference to a non-existent step → `❌ Page N references a non-existent step in depends-on. Run /grimoire-plan N to fix.`
- **Resume announcement (not a pause):** a `blocked` page, or an existing page branch, is not a hard-stop — announce `▶ Resuming page N on existing branch <branch>` and continue in resume mode (`§ Review loop`).
- **No interview:** the auto-plan asks nothing — unresolved choices become `## Assumptions`. After the draft PR there are no questions at all: the run ends in `review`, or in `blocked` with the `⛔` comment that carries the question and the way back.

**`grimoire-run`**
- **Hard-stops:** the construct does not exist → `❌ Construct N does not exist.`; nothing to run (no pending reference and no runnable page — every page in `review`, closed, or `blocked`) → `❌ Construct N has nothing to run.`, followed by the list of `blocked` pages, if any, each with the hint to resume it with `/grimoire-execute M`.
- **Page-DAG hard-stops** (before the boundary): a cycle between pages → `❌ Construct N has cyclic dependencies between pages. Fix them with /grimoire-construct-update first.`; a `depends-on` pointing at a non-existent page → `❌ Construct N references a non-existent page in depends-on. Fix it with /grimoire-construct-update first.`
- **Phase 1 pauses:** one `grimoire-spec` consumption interview per pending reference, in list order — its clarifying questions, draft review, and hard-stops apply unchanged. At any interview the user may answer "skip the rest": the remaining references and their transitive dependents are left out of Phase 2. Abandoning a consumption draft counts as "skip the rest" (`§ Run`).
- **Boundary announcement (not a pause):** `🚀 Autonomous phase: N pages, K waves — you can leave.` Nothing is asked after this line; every page ends in `review`, `blocked`, or `skipped` (`§ Run`).
- **Resume announcement (not a pause):** `▶ Resuming run <id>` when an unfinished ledger exists.

**`grimoire-adopt`** (GitHub only)
- **Backend hard-stop:** local backend → `❌ grimoire-adopt requires the GitHub backend.`
- **Target hard-stops:** the object does not exist → `❌ Issue N does not exist.` / `❌ Milestone N does not exist.`; the object is closed → `❌ Issue N is closed.` / `❌ Milestone N is closed.`; the object is already managed by Grimoire (marker or label present) → `❌ Issue N is already managed by Grimoire (grimoire:spec).` — the parenthesis names the status label found — / `❌ Milestone N is already managed by Grimoire.`
- **Clarifications and improvements:** after the research sub-agent has analyzed the code against the request, interview the developer — sharpen scope and acceptance criteria, flag "too large → milestone" — and PAUSE for the answers.
- **Size-evaluation pause (issue only):** when the issue is judged too large for one page, recommend a construct and PAUSE — mirroring `grimoire-spec`'s size-evaluation pause. On approval, write the handoff brief per `§ Construct` and STOP, leaving the issue untouched; on decline, continue adopting it as one page.
- **Draft review:** present `.grimoire/bag/drafts/adopt-<epoch>.md` per `§ IDE-aware review` and PAUSE for confirmation or edits before writing the issue body / milestone description.

**`grimoire-quick`**
- **Scope gatekeeper:** if the request is too large or complex to fit a quick execution, STOP immediately and tell the user to switch to `grimoire-spec` (the entry point to the long-form Spec → Plan → Execute pipeline) instead of generating a plan.
- **Final clarity check:** immediately before composing and presenting the plan draft (per `§ IDE-aware review`), self-review the intended fix and surface any remaining assumption. If anything is still unclear (expected behavior, scope of touched files, error handling, naming), PAUSE and ask the user using the available question tooling before the draft is written or pasted. Skip silently only when the fix is fully unambiguous.
- **Plan authorization:** after presenting the plan for review per `§ IDE-aware review`, PAUSE and wait for the user's explicit authorization or corrections before spawning the sub-agent. Do not start coding yet.

**`grimoire-know`** — no pause-points: read-only, answers directly (uncertainties are stated in the answer, not asked back).

**`grimoire-update`**
- **Changelog review:** when the installed `VERSION` differs from the latest, present the changelog delta per `§ IDE-aware review` and PAUSE for an explicit ok before running the installer. No pause when the versions match (print the up-to-date line and stop).

**`grimoire-note`**
- **Precondition check (HARD STOP):** `.grimoire/PROJECT.md` is missing → `❌ .grimoire/PROJECT.md does not exist.` followed by one line explaining that there is nowhere to write and that the user must run `/grimoire-init` first. STOP; never create a skeleton; never offer to run `grimoire-init` automatically.
- **Draft review:** present the proposed edits to `docs/conventions.md` and `PROJECT.md` `## Grimoire rules` per `§ IDE-aware review` and PAUSE for confirmation or edits before writing and committing. A rule whose classification is ambiguous (`§ Documentation`) is asked at this same pause.

**`grimoire-deps`**
- **Report pause:** after the audit, present the ranked report per `§ IDE-aware review` and PAUSE for the user to select the updates to apply by replying against the report. Nothing is applied before that answer.

**`grimoire-construct`**
- **Clarifying questions:** after research, interview the user about facts that cannot be inferred from the codebase or the handoff brief — including the proposed order and the `depends-on` between references — and PAUSE for the answers before authoring the construct.
- **Draft review:** after composing the proposed construct (`.grimoire/bag/drafts/construct-<epoch>.md` on GitHub; `CONSTRUCT.md` + `references/` locally), present it for review per `§ IDE-aware review` and PAUSE for the user's confirmation or edits before creating the milestone + reference issues or the local files.

**`grimoire-construct-update`**
- **Target-construct resolution (HARD STOP):** before doing anything else, resolve the input to an existing construct (milestone number / title on GitHub; `NNN` / `<name>` locally). If it does not exist, STOP immediately, creating or changing nothing, with `❌ Construct N does not exist. Run /grimoire-construct first.` Never offer to run `grimoire-construct` automatically.
- **Locked-prefix operation refusal:** when the user requests an edit, removal, or reorder of a specced reference, or an insertion ahead of one, **refuse** with a message **naming the reference and its page** — locally `❌ Reference 2 has already been specified (page 007) — it cannot be edited, removed, or reordered.`, on GitHub `❌ Reference 2 (#123) has already been specified — it cannot be edited, removed, or reordered.` — and change nothing. See the Alteration rules in `§ Construct`.
- **Clarifying questions / operation selection:** after resolving the target and (optionally) running research, interview the user to fix the operation set and PAUSE for the answers before composing the alteration.
- **Draft review:** after composing the altered construct, present it per `§ IDE-aware review` and PAUSE for approval, edits, or abandonment before writing.
