---
name: grimoire-know
description: Answer questions about the repository or its application — read-only, through a research sub-agent, with web research and source citations when needed.
argument-hint: Your question about the repo or the app
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Sub-agent spawning` (the `research` role), `§ Harness adaptation`, `§ Configuration`, `§ Documentation` (read-only consumption), `§ Skill composition`, `§ User-facing language`, `§ Pause-point pattern` (`grimoire-know` has no pause-points), and — read-only, when the question concerns Grimoire work — `§ Backends`, `§ .grimoire/ layout`, `§ Construct`. **Not applicable:** `§ TDD`, `§ Code comments`, `§ Commits` (this skill commits **nothing**), `§ IDE-aware review`, `§ Parallel execution`, `§ Review loop`, `§ Run` — this skill is pure Q&A: it never mutates the repo and creates no pages.
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and any other linked doc the question touches. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` at the end (non-blocking — never refuse to answer because it is missing, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice) — the `research` role's model and effort.
4. Only when the question concerns Grimoire pages or constructs: detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). `[github].mode = "on"` without auth → `❌ GitHub backend required but gh is not authenticated.` and STOP. Otherwise skip detection.

**[Objective]**
Answer the following question about the repository or the application it builds, faithfully and read-only:

$ARGUMENTS

**[Hard constraints — read-only]**
- Never use `Write`, `Edit`, `NotebookEdit`, or any file-mutating tool against the consumer project.
- Never run shell commands that mutate state (`git commit`, `git push`, `git checkout -b`, file creation/deletion, package installs, `gh` writes, etc.). Read-only `Bash` (`ls`, `cat`, `git log`, `git diff`, `git status`, `find`, `grep`, `gh … view` / `list`) is allowed.
- Never write to `.grimoire/`, `docs/`, or any backend object (issue, milestone, comment, pull request) — `§ Documentation`, dual-writer contract.
- Never make commits.
- When uncertain, say so plainly instead of guessing.

**[Phase 1: Question analysis]**
- Classify whether the question is answerable from the repo alone, requires web research, or both.
- Identify which files or directories are most relevant to the question without reading more than needed. When the question is about recent Grimoire work, "recent context" (`§ .grimoire/ layout`) is the place to look.
- Decide upfront whether the sub-agent will need `WebSearch`/`WebFetch`, so it can be briefed accordingly.

**[Phase 2: Investigation]**
- Spawn one `research` sub-agent per `§ Sub-agent spawning` — `Explore` on Claude Code (read-only enforced), instructed read-only on Codex (`§ Harness adaptation`) — with the model and effort of the `research` role (`§ Configuration`).
- Brief the sub-agent with a self-contained prompt that includes the user's question, the relevant files/dirs identified in Phase 1, the docs pointers of `[Required Reading]` step 2, and explicit instructions to:
  - Inspect only the files needed to answer the question.
  - Use `WebSearch`/`WebFetch` when the answer depends on facts outside the repo (third-party libs, standards, recent docs, API behavior).
  - Collect every URL it actually consulted.
  - Flag any claim it is not confident about, instead of guessing.
  - Return a structured response with: (a) the answer, (b) an "uncertain about" list (empty if none), and (c) the source links it used (empty if none).

**[Phase 3: Response]**
Render the sub-agent's findings to the user in chat, per `§ User-facing language`:
- **Direct answer first.** Lead with the answer to the question — no preamble.
- **Uncertain about.** Include this section only if the sub-agent's "uncertain about" list is non-empty; mark it clearly so the user can verify those claims.
- **References.** Include this section at the end **only when the sub-agent actually consulted the web**, listing each URL on its own line. If no web sources were used, omit the section entirely.
- No file changes, no commits.

**[Phase 4: Cleanup]**
Nothing to clean up — this skill is fully ephemeral. If `.grimoire/PROJECT.md` was missing, remind the user that running `grimoire-init` once would enrich future answers. End.
