# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.14.0] — 2026-11-17

### Added
- New `grimoire-run` skill: runs a whole construct end to end. Phase 1 runs one `grimoire-spec` consumption interview per pending reference (the user may "skip the rest"); after the `🚀 Autonomous phase: N pages, K waves — you can leave.` boundary, Phase 2 asks nothing and takes every page through plan → execute → review → PR in Kahn waves over the page `depends-on` graph (an implicit chain when no page declares one), up to `[run].page_parallelism` pages at a time, with stacked PRs, blocked-propagation to dependents, a best-effort watchdog with one retry, and a resumable ledger under `.grimoire/bag/runs/`. New `GRIMOIRE-CONVENTIONS.md` `§ Run`.
- New `grimoire-adopt` skill (GitHub only): brings an existing issue (→ page) or milestone (→ construct, its issues → references, gaps → new reference issues) under Grimoire after a research sub-agent, an interview, and a draft review, preserving the original texts in `<details>` blocks and never closing a human's issue.
- **GitHub backend** (`§ Backends`): pages are issues (the SPEC is the issue body, the issue number is the page number), constructs are milestones with a numbered `## References` list, every reference is an issue created at once, plans and review verdicts are comments, and each page ships as one pull request. Objects carry HTML markers (`<!-- grimoire:page v=1 … -->`, `<!-- grimoire:construct v=1 -->`, `<!-- grimoire:plan v=1 -->`, `<!-- grimoire:verdict round=N -->`); status lives in labels (`grimoire:reference`, `grimoire:spec`, `grimoire:planned`, `grimoire:review`, side labels `grimoire:blocked`, `grimoire:dropped`). The backend is detected once per run (`[github].mode = auto | on | off`, `origin` on `github.com`, `gh auth status`) and announced; without GitHub the **local backend** keeps the same objects as git-ignored files with `status:` frontmatter.
- **Review loop** (`§ Review loop`): `grimoire-execute` opens a draft PR after the first step commit and drives up to `[review].max_rounds` rounds of a reviewer sub-agent — scope against the acceptance criteria, `ponytail-review`, the full `test_command` / `build_command` / `lint_command` gate (a documented `§ TDD` exception), and, for files matching `[review].ui_globs`, a fresh dev server checked with `agent-browser`, `impeccable`, and `revenue-centric-design` plus design-system conformance — and a fixer sub-agent on `changes-requested`. Approval fills `## Summary` and `## Human validation`, runs `gh pr ready`, and labels the page `grimoire:review`; exhausted rounds leave the PR draft with `grimoire:blocked` and a `⛔` comment naming the way back. Re-running on an existing branch resumes with the new human comments.
- **Page worktrees and stacked PRs:** every page executes on its own branch `grimoire/<N>-<slug>` in `.grimoire/bag/worktrees/page-<N>/` — the user's working tree never changes branch — and a page whose dependency is not merged yet is branched from that dependency (stacked PR). Unconditional worktree teardown at the end of every execution.
- **Configuration** (`§ Configuration`): a global `~/.grimoire/config.toml` and a committed project `.grimoire/config.toml`, merged key by key over built-in defaults; per-harness model + effort for the roles `session`, `default`, `research`, `plan`, `execute`, `fix`, `review`, `quick`, `deps`; `[run]`, `[review]`, `[github]`, `[verify]` (with the per-page `{port}` placeholder), and `[docs]`. Shipped as `config.example.toml`.
- **Codex support** (`§ Harness adaptation`): one table maps every operation — spawning a role, waiting, asking the user, invoking a sibling skill, fetching a URL, model and effort values — to Claude Code and to Codex; skills are installed for both.
- **Installer:** `install.sh` (POSIX sh; `curl … | sh` or `./install.sh` from a checkout in dev mode; flags `--ref`, `--agent`, `--no-deps`, `--dry-run`, `--uninstall [--purge]`, `--home`) clones the Grimoire home to `~/.grimoire`, copies the skills to `~/.claude/skills/` and `~/.agents/skills/` substituting the `${GRIMOIRE_HOME}` token, installs the dependencies of `deps.txt` from upstream (`agent-browser` CLI + skill, `ponytail-review`, `impeccable`, `revenue-centric-design`), and creates the global config. `install.ps1` runs it on Windows through Git Bash; `VERSION` holds the release number; `scripts/test-install.sh` tests the installer in a sandboxed `HOME`.
- **0.13 migration:** `grimoire-init` detects 0.13 state tracked by git and, on explicit consent, stamps `status:` frontmatter on legacy pages and constructs, untracks the now-ignored folders, deletes `HISTORIC.md` and `bag/historic/`, and commits `chore(grimoire): migrate to 0.14 layout`.
- This repository's own `docs/` (overview, architecture, conventions, development) and `.grimoire/config.toml`.

### Changed
- **Documentation split** (`§ Documentation`): project context now lives in neutral, human-owned `docs/` files (`overview.md`, `architecture.md`, `conventions.md`, `development.md`), and `.grimoire/PROJECT.md` becomes an index of those files plus `## Grimoire rules`. `grimoire-init` writes only the missing canonical docs, the index, `config.toml`, and the `.gitignore` block, and ensures the GitHub labels; `grimoire-note` routes each rule to `docs/conventions.md` or `## Grimoire rules`.
- `grimoire-execute` is now autonomous: it auto-plans a page still in `spec` (no interview — open choices become `## Assumptions`), executes in the page worktree, and ends with a PR awaiting human review (`review`) or `blocked`; it asks no questions. `grimoire-plan` remains as the optional interactive planner and writes a plan comment on GitHub.
- `grimoire-spec`, `grimoire-construct`, and `grimoire-construct-update` write GitHub issues and milestones (or git-ignored local files); construct references may declare `depends-on`, which `grimoire-run` uses as the page graph.
- `grimoire-update` reads `${GRIMOIRE_HOME}/VERSION`, compares it with `main/VERSION`, shows the changelog delta, and on approval runs the installer itself (`install.sh --ref v<latest>`).
- The orchestrator never implements: every analysis, plan, step, review, and fix runs in a sub-agent whose model and effort come from its role (`§ Sub-agent spawning`).
- `README.md`, `README.pt-BR.md`, and `CLAUDE.md` rewritten for 0.14.

### Removed
- `.grimoire/HISTORIC.md`, its rotation into `.grimoire/bag/historic/`, and the `[spec]` / `[planned]` / `[finished]` status tokens — status lives in labels or frontmatter.
- State commits: specifying, planning, reviewing, or finishing a page and creating or altering a construct no longer commit anything; only `.grimoire/PROJECT.md` and `.grimoire/config.toml` are ever committed under `.grimoire/`.
- The `.claude-plugin/` manifests (`plugin.json`, `marketplace.json`) and the Claude Code marketplace distribution channel — Grimoire is installed with `install.sh` / `install.ps1`.
- The `${CLAUDE_PLUGIN_ROOT}` token, replaced by `${GRIMOIRE_HOME}`.
- This repository's committed page folders and historic (they remain in the git history).

## [0.13.0] — 2026-06-16

### Added
- New `GRIMOIRE-CONVENTIONS.md` `§ Skill composition` convention: every Grimoire skill surveys the runtime's available-skills list and composes with relevant helpers to enrich its own work. Read-only/assistive helpers run automatically with a `🧩` one-line announcement; write, side-effect, or scope-changing helpers are gated by an explicit user ok folded into the skill's existing pause-points. Conflicting orchestrators are excluded from composition, and helpers never own `.grimoire/` state or override Grimoire contracts. The section is wired into the `[Required Reading]` block of all 11 skills.

## [0.12.0] — 2026-06-16

### Added
- New `GRIMOIRE-CONVENTIONS.md` `§ User-facing language` convention: hardcoded operator-facing strings are authored in English (canonical translatable templates), but every skill renders terminal communication in the user's native language at runtime — detected from the user's session input, falling back to the OS/system locale, then to English. Literal tokens (command names, status tokens, `NNN`/page identifiers, file paths, and the `❌`/`📄` glyphs) are preserved verbatim; only the surrounding prose is localized. The section is wired into the `[Required Reading]` block of all 11 skills.

### Changed
- Normalized every hardcoded operator-facing pt-BR string in the plugin source to English: the `❌` hard-stop messages in `§ Pause-point pattern` and their duplicated copies in `grimoire-execute`, `grimoire-plan`, `grimoire-spec`, and `grimoire-construct-update`; and the `📄` IDE-review example lines in `§ IDE-aware review` and `grimoire-note`. The canonical and duplicated copies stay byte-consistent.
- Removed the contradictory "operator-facing message may be pt-BR per project precedent" notes from `grimoire-note`, `grimoire-construct`, and `grimoire-construct-update`; those bodies now defer to `§ User-facing language`.

## [0.11.0] — 2026-06-08

### Added
- New `grimoire-construct-update` skill: the second authorized writer of construct files (the construct analog of `grimoire-note`). It alters an **existing** construct in place across four operation families — add/remove/reorder references in the `[pending]` tail, refine a `[pending]` reference's detail, rewrite the construct intro/objective, and rename the construct (preserving `NNN`). It enforces the locked-`[specced]`-prefix invariant: editing, removing, reordering a `[specced]` reference — or inserting ahead of one — is refused (the refusal names the reference and its page backlink). After any structural change it renumbers the pending tail contiguously in execution order, leaving the locked prefix untouched. Never creates a construct or a page, never writes `HISTORIC.md`/`PROJECT.md` — orthogonal to the Spec → Plan → Execute pipeline (same family as `grimoire-construct`, `grimoire-know`, `grimoire-update`, `grimoire-note`, and `grimoire-deps`). Ends with a single `docs(grimoire): update construct <name>` commit.

### Changed
- `GRIMOIRE-CONVENTIONS.md` `§ Construct` writer contract amended to admit `grimoire-construct-update` as a second authorized writer, plus a new **Alteration rules** subsection (the immutable `[specced]` prefix, pending-tail-only edits, contiguous renumbering, rename-preserves-`NNN`, self-containment).
- `GRIMOIRE-CONVENTIONS.md` `§ Commits`, `§ Sub-agent spawning`, and `§ Pause-point pattern` amended to wire in the new skill (the `docs(grimoire): update construct <name>` commit, conditional research sub-agents, and the resolution hard-stop / locked-`[specced]` refusal / operation-selection / draft-review pauses).
- `README.md`, `README.pt-BR.md`, and `CLAUDE.md` document `grimoire-construct-update`, the eleventh skill, and its place alongside `grimoire-construct`.

## [0.10.0] — 2026-06-08

### Added
- New **construct** concept: a larger-than-a-page objective container. A construct is a flat, ordered list of reference-seeds living in `.grimoire/constructs/NNN-<name>/` (`CONSTRUCT.md` + an ordered `references/` folder), where each reference is later expanded — through the normal full spec interview — into one real page. Constructs are self-contained: no nested sub-constructs and **no `HISTORIC.md` entry** (only the pages they spawn appear there); `NNN` is an independent counter that does not collide with `pages/`.
- New `grimoire-construct` skill: researches in sub-agents, interviews the user, resolves the construct `NNN`, and authors `CONSTRUCT.md` plus the ordered `references/N-<name>.md` detail files. Never creates a page and never writes `HISTORIC.md`/`PROJECT.md` — orthogonal to the Spec → Plan → Execute pipeline (same family as `grimoire-know`, `grimoire-update`, `grimoire-note`, and `grimoire-deps`). Ends with a single `docs(grimoire): construct <name>` commit.
- `GRIMOIRE-CONVENTIONS.md` — new `§ Construct` section: the single source of truth for the construct artifact (folder layout, `CONSTRUCT.md` format, writer contract, strictly-next-in-order consumption rules, self-containment, and the size-evaluation/handoff-brief trigger).

### Changed
- `grimoire-spec` gains two construct-aware modes. **Size-evaluation:** in free-text new-page mode, a request judged too large for one page triggers a construct recommendation; on approval it writes a handoff brief to `.grimoire/bag/drafts/construct-brief-<epoch>.md` and STOPS without creating a page. **Bare-number construct-consumption:** input that is only digits resolves a construct, seeds the full spec interview with its next `[pending]` reference, produces a normal page that names its parent construct, and flips that reference to `[specced]` in `CONSTRUCT.md` (atomic `chore: mark reference N specced in construct <name>` commit). Free-text new-page behavior is otherwise unchanged.
- `GRIMOIRE-CONVENTIONS.md` `§ .grimoire/ layout`, `§ Commits`, `§ Project context`, `§ Sub-agent spawning`, and `§ Pause-point pattern` amended to wire in the construct concept.
- `README.md`, `README.pt-BR.md`, and `CLAUDE.md` document `grimoire-construct`, the construct flow, the tenth skill, and the `constructs/` layout.

## [0.9.0] — 2026-06-08

### Added
- New `grimoire-deps` skill: orthogonal dependency-audit-and-update. Surveys the project's declared dependencies for security exposure (known CVEs/advisories), semver-upgrade risk, release maturity (favoring versions aged ~14 days to dodge fresh-publish regressions and supply-chain compromise), and supply-chain reputation, then presents a ranked, IDE-aware report with interactive selection. Applies each chosen upgrade as a per-dependency atomic commit gated by the project's own build/test — reverting that dependency on failure — and hands breaking upgrades off to `/grimoire-spec` instead of attempting them inline. Never creates a page folder and never touches `HISTORIC.md` — fully orthogonal to the Spec → Plan → Execute pipeline (same family as `grimoire-know`, `grimoire-update`, and `grimoire-note`).

## [0.8.0] — 2026-05-25

### Added
- `GRIMOIRE-CONVENTIONS.md` — new `§ Parallel execution` section: opt-in YAML frontmatter (`depends-on`, `touches`) on step files unlocks a dependency-graph execution model for `grimoire-execute`. The orchestrator builds a DAG, runs Kahn-style topological waves, spawns one sub-agent per step inside a deterministic git worktree under `.grimoire/bag/worktrees/page-NNN-step-K/`, cherry-picks successful siblings back to the main workspace in step-number order, and tears down every worktree unconditionally (`git worktree remove --force` + defensive filesystem cleanup) before the next wave and at end of run — `.grimoire/bag/worktrees/` and `git worktree list` are guaranteed clean after every run, success or failure.

### Changed
- `GRIMOIRE-CONVENTIONS.md § Sub-agent spawning` amended to admit parallel sub-agents inside a single wave when the page's step files declare `depends-on` frontmatter; sequencing across waves remains strict; legacy strict-serial is the default when no step file carries frontmatter.
- `GRIMOIRE-CONVENTIONS.md § .grimoire/ layout` notes that step files MAY carry YAML frontmatter per `§ Parallel execution`.
- `GRIMOIRE-CONVENTIONS.md § Pause-point pattern`:
  - `grimoire-plan: final clarity check` extended to require DAG presentation (wave list + per-step deps + advisory `touches`-overlap warnings) when frontmatter will be emitted, so the user can veto a suspect parallelization before step files are written.
  - `grimoire-execute: precondition check (HARD STOP)` gains two new hard-stop cases: cyclic `depends-on` graph and `depends-on` reference to a non-existent step.
- `skills/grimoire-plan/SKILL.md` Phase 3 extended: when steps are genuinely independent, the planner MAY emit the new frontmatter; builds and validates the DAG (cycle + dangling-reference detection, advisory `touches`-overlap), computes waves, surfaces the wave plan at the final-clarity-check pause-point, and falls back to legacy serial if the user vetoes parallelization. Phase 4 writes the YAML frontmatter block on each step file when the approved DAG calls for it.
- `skills/grimoire-execute/SKILL.md` Phase 1 detects frontmatter and selects between the legacy strict-serial path and the parallel-wave path. Phase 2 is split into 2A (legacy) and 2B (parallel-wave: worktree creation, concurrent sub-agent spawn, wave-settle wait, cherry-pick in step-number order, unconditional teardown as a try/finally invariant). Phase 4 splits finalization: fully-successful runs mark `[finished]`; partial-failure runs keep HISTORIC at `[planned]` and report finished / failed / skipped steps to the user.
- `README.md`, `README.pt-BR.md`, `CLAUDE.md` describe the new wave model in their `grimoire-plan` and `grimoire-execute` entries, pointing to `§ Parallel execution` for details.

### Compatibility
- **Pure opt-in.** Pages whose step files declare no `depends-on` frontmatter execute byte-identically to pre-0.8.0 — no worktrees created, no behavior change. Existing pages (e.g., `001-grimoire-note-skill`) are unaffected; no auto-migration.

## [0.7.0] — 2026-05-23

### Added
- New `grimoire-note` skill: free-text-in, surgical-edit-out maintenance of `.grimoire/PROJECT.md`. Scope is strictly limited to the `## Key Conventions / Constraints` and `## Notes` sections; the rest of the file is owned by `grimoire-init`. Uses LLM-driven semantic deduplication, refinement of stale phrasing, contradiction handling, and retroactive consolidation across pre-existing entries; assigns each incoming line heuristically to Conventions vs. Notes and pauses to ask when ambiguous; force-fits content that does not match either section into the closer one and flags the misfit back to the user. Honors `§ IDE-aware review` for diff inspection and lands a single atomic commit `docs(grimoire): refine project context`. Writes nothing outside the two governed sections, creates no page folder, and does not touch `HISTORIC.md` — fully orthogonal to the Spec → Plan → Execute pipeline (same family as `grimoire-know` and `grimoire-update`).

### Changed
- `GRIMOIRE-CONVENTIONS.md § Project context` amended to a **dual-writer contract**: `grimoire-init` owns `.grimoire/PROJECT.md` as a whole (bootstrap, every section, section creation), while `grimoire-note` owns only `## Key Conventions / Constraints` and `## Notes` and edits them incrementally.
- `grimoire-init` Phase 2 (UPDATE mode only): preserve-by-default for `## Key Conventions / Constraints` and `## Notes`. The skill now lists existing entries back to the user with an "anything stale?" prompt; additions remain permitted, and silence keeps every existing entry untouched.

## [0.6.0] — 2026-05-22

### Added
- New `grimoire-know` skill: read-only Q&A about the repository or the application it builds. Spawns a sub-agent with `WebSearch`/`WebFetch` access for facts outside the repo, returns the answer with a "References" list of consulted URLs, and explicitly flags anything it is not confident about. Writes nothing, makes no commits, and does not touch `HISTORIC.md` or `.grimoire/pages/` — it is fully ephemeral and orthogonal to the Spec → Plan → Execute pipeline (like `grimoire-update`).

## [0.5.0] — 2026-05-22

### Added
- New pause-point in `GRIMOIRE-CONVENTIONS.md § Pause-point pattern`: **final clarity check** for both `grimoire-plan` and `grimoire-quick`. Before a plan is closed and presented to the user, the agent must self-review for hidden assumptions and surface them via the available question tooling (e.g. `AskUserQuestion`) instead of silently guessing. Skip allowed only when the plan is fully unambiguous.

### Changed
- `grimoire-plan` Phase 3: ends with the new final clarity check before Phase 4 writes step files.
- `grimoire-quick` Phase 2: runs the new final clarity check before composing/presenting the plan draft, replacing the prior "ask any clarifying questions if necessary" wording with an explicit self-review + pause requirement.

## [0.4.2] — 2026-05-22

### Changed
- Ephemeral draft files in `§ IDE-aware review` now include a Unix-epoch suffix in their filenames (`quick-plan-<epoch>.md`, `grimoire-update-changelog-<epoch>.md`) so each run writes to a unique path. This defeats the VSCode markdown preview cache, which is keyed by file path — previously, a second invocation could show the stale preview from the prior run. Final-destination drafts (`PROJECT.md`, `SPEC.md`) are unaffected and keep their canonical names.
- `grimoire-quick` Phases 2/5 and `grimoire-update` Phases 4/5/8: write and cleanup now use the memorized per-run path instead of a fixed filename.

## [0.4.1] — 2026-05-21

### Added
- New `§ IDE-aware review` convention in `GRIMOIRE-CONVENTIONS.md`: when Claude Code is running inside an IDE extension (VSCode, JetBrains, Cursor, etc.), skills now write the draft/plan to disk so the editor renders it with full markdown preview, instead of pasting raw markdown into chat. Falls back to inline-chat output when no IDE is detected.

### Changed
- `grimoire-init` draft review (Phase 3/4): writes the proposed `PROJECT.md` straight to its final path in IDE mode for review; commit phase unchanged.
- `grimoire-spec` draft review (Phase 4/5): writes the proposed `SPEC.md` straight to its final page-folder path in IDE mode for review; commit phase unchanged.
- `grimoire-quick` plan authorization (Phase 2): writes the plan to `.grimoire/bag/drafts/quick-plan.md` in IDE mode and adds a Phase 5 that deletes the draft after execution (or on abandonment).
- `grimoire-update` changelog display (Phase 4): writes the extracted changelog slice to `.grimoire/bag/drafts/grimoire-update-changelog.md` in IDE mode; Phases 5/8 delete the draft on rejection or completion. Notes/Objective updated to reflect that the skill may now write an ephemeral draft.

## [0.4.0] — 2026-05-21

### Added
- `grimoire-update` skill: guided plugin self-update. Reads the installed `plugin.json` version, fetches the latest from GitHub, prints the changelog diff between the two, and then walks the user through `/plugin marketplace update grimoire` + `/reload-plugins`. Exits early when already on the latest version. Writes nothing to the consumer project and makes no commits.

### Changed
- README and CLAUDE.md updated to document the new sixth skill.

## [0.3.0] — 2026-05-21

### Added
- `grimoire-spec` skill: page specification with HISTORIC.md bootstrap/rotation.
- `grimoire-plan` and `grimoire-execute` accept page numbers with precondition checks.

### Changed
- `grimoire-init` and `grimoire-quick` aligned with the Spec → Plan → Execute pipeline.
- README and CLAUDE.md updated for the new pipeline.

[0.14.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.14.0
[0.13.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.13.0
[0.12.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.12.0
[0.11.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.11.0
[0.10.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.10.0
[0.9.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.9.0
[0.8.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.8.0
[0.7.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.7.0
[0.6.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.6.0
[0.5.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.5.0
[0.4.2]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.4.2
[0.4.1]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.4.1
[0.4.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.4.0
[0.3.0]: https://github.com/ojCezarFerreira/grimoire/releases/tag/v0.3.0
