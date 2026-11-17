---
name: grimoire-init
description: Initialize or update a project's Grimoire context — analyzes the codebase, discovers the install/dev/test/build/lint commands, interviews you, and writes the neutral docs/ (overview, architecture, conventions, development — only the missing ones), the .grimoire/PROJECT.md index, .grimoire/config.toml, and the .gitignore lines; ensures the GitHub labels; migrates 0.13 repositories to the 0.14 layout on consent.
argument-hint: (optional) extra context or focus areas
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Documentation` (the single source of truth — `docs/`, the `PROJECT.md` index format, `grimoire-init`'s duties, update mode, the migration of 0.13 repositories, the dual-writer contract), `§ Configuration` (schema, `[verify]`, the `{port}` placeholder, `[docs]`), `§ Backends` (detection, labels, label-ensure rule), `§ .grimoire/ layout` (committed vs git-ignored, status frontmatter, legacy pages), `§ Construct` (local construct and reference status), `§ Harness adaptation`, `§ Skill composition`, `§ Commits`, `§ IDE-aware review`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ TDD`, `§ Code comments`, `§ Sub-agent spawning` (this skill spawns nothing), `§ Parallel execution`, `§ Review loop`, `§ Run`.
2. `.grimoire/PROJECT.md` and `docs/` are this skill's **output** — Phase 1 reads them to choose the mode.
3. Read `.grimoire/config.toml` (when present) and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice).
4. Detect the backend per `§ Backends` (required here — labels, migration notice) and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). `[github].mode = "on"` without auth → `❌ GitHub backend required but gh is not authenticated.` and STOP.

**[Objective]**
Build a shared understanding of the current project — what it is, who it's for, how it is built and run — and persist it per `§ Documentation`: the neutral, human-owned `docs/` files, the `.grimoire/PROJECT.md` index with its `## Grimoire rules`, the project `.grimoire/config.toml`, and the `# Grimoire` block of `.gitignore`. Every other Grimoire skill loads that context through its `[Required Reading]`.

Optional extra context or focus areas from the user:

$ARGUMENTS

**[Phase 1: Mode Detection & Codebase Analysis]**
- **Mode.** `.grimoire/PROJECT.md` exists → **UPDATE**: read it, `.grimoire/config.toml`, and the docs it links first, and preserve everything still accurate. Otherwise → **INITIALIZATION**.
- **Codebase scan.** Read only what is needed to form an opinion: root README files; package manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `Gemfile`, `composer.json`, …); build / language config (`tsconfig.json`, `vite.config.*`, `next.config.*`, `pnpm-workspace.yaml`, …); CI definitions (`.github/workflows/`, `.gitlab-ci.yml`, …); the top-level layout (one level deep); `LICENSE`, `CONTRIBUTING.md`. Collect candidate facts: name, languages / frameworks, notable dependencies, layout, audience hints. **Do not invent facts** — what cannot be inferred becomes a Phase 2 question.
- **`[verify]` discovery** (`§ Configuration`) — read, never run:
  - the package manager from the lockfile (`pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn, `package-lock.json` → npm, `bun.lock*` → bun, `poetry.lock` → poetry, `uv.lock` → uv, `Cargo.lock` → cargo, …);
  - `install_command`, `dev_command`, `test_command`, `build_command`, `lint_command` from the `package.json` scripts, `Makefile` targets, `pyproject.toml` tool sections, `composer.json` scripts, CI steps, …, spelled with that package manager;
  - **dev-server port:** when the dev tool accepts a port flag (Vite `--port`, Next `-p`, …), emit the `{port}` placeholder in `dev_command` (with the package manager's pass-through syntax, e.g. `npm run dev -- --port {port}`) and `dev_url = "http://localhost:{port}"`; otherwise write the fixed command and URL;
  - a command that cannot be found is left out — never guessed; ask about it in Phase 2 when it matters.
- **Docs detection.** List `[docs].dir` (default `docs/`): when it exists, note every file and which canonical topics (`overview`, `architecture`, `conventions`, `development`) are missing. In UPDATE mode, a `PROJECT.md` still in the pre-0.14 section format (Purpose … Notes) seeds the missing canonical files and `## Grimoire rules`.
- **Docs language.** Keep an existing `[docs].language`; otherwise infer it from the README's language. Unclear → one Phase 2 question.
- **0.13 migration detection** (both modes — `§ Documentation`): `git ls-files .grimoire/pages .grimoire/constructs .grimoire/HISTORIC.md .grimoire/bag/historic` — any output means legacy artifacts tracked by git. Then read `.grimoire/HISTORIC.md`, `.grimoire/bag/historic/*`, and the legacy page / construct folders to build the proposal: the `SPEC.md` / `CONSTRUCT.md` / `references/*` files to stamp and with which `status:`, the paths to untrack, the files to delete, and the pages still in progress (HISTORIC status other than `[finished]`).

**[Phase 2: Clarifying Questions]**
Per `§ Pause-point pattern` (`grimoire-init`: clarifying questions), ask concise, targeted questions about ONLY what cannot be inferred:
- the project's purpose, audience, and stage (prototype / active development / production / maintenance);
- non-obvious code conventions, constraints, or invariants (→ `docs/conventions.md`) and rules the Grimoire agents must obey here (→ `## Grimoire rules`);
- the docs language, when Phase 1 could not infer it;
- any `[verify]` command Phase 1 could not discover;
- anything to deliberately exclude.

In **UPDATE** mode ask only about deltas. When `## Grimoire rules` has entries, list them back briefly (first ~10 words each) and ask "Anything stale here?" — default **preserve in place**: remove or rewrite an entry only on an explicit delta; silence keeps everything (the section is jointly owned with `grimoire-note` — `§ Documentation`).

**Migration consent** — in either mode, only when Phase 1 detected legacy artifacts, per `§ Pause-point pattern` (`grimoire-init`: migration pause): present the full proposal — the pages and constructs to stamp, the paths to untrack, the files to delete, the in-progress pages affected (on GitHub: no longer addressable by number) — and ask for an explicit yes. Declining skips the migration; the rest of the run continues. Never migrate silently.

Wait for the answers before composing anything.

**[Phase 3: Compose & Draft Review]** — exactly one review pause for everything generated
- **`docs/` files** — neutral, zero Grimoire vocabulary, in `[docs].language` (`§ Documentation`): `[docs].dir` absent → the four canonical files; present → **only the missing canonical topics**, never rewriting a human doc. `development.md` mirrors `[verify]`.
- **`.grimoire/PROJECT.md`** — the index in the exact `§ Documentation` format: one line per `docs/*` file (existing and new), then `## Grimoire rules` (UPDATE mode: the existing entries preserved per Phase 2, plus the new ones).
- **`.grimoire/config.toml`** — `[verify]` from Phases 1–2 and `[docs]` (`dir`, `language`). UPDATE mode: rewrite only those two tables; keep every other table and key the user set.
- **`.gitignore`** — the `# Grimoire` block with only the missing lines among `.grimoire/pages/`, `.grimoire/constructs/`, `.grimoire/bag/`.
- **Migration** (when consented) — restate the accepted plan alongside the files so the final "ok" covers it.

Present per `§ IDE-aware review` (`grimoire-init` → final destinations): create `.grimoire/` if needed, write the files in place, and name every written path — and the `.gitignore` lines added — in the single `📄` line. Terminal-only → paste them inline. PAUSE per `§ Pause-point pattern` (`grimoire-init`: draft review). Edits → revise in place and re-pause. **Abandonment** → delete every file this run created and restore every tracked file it modified (`git checkout -- <path>`); nothing is committed and no migration runs.

**[Phase 4: Finalize]**
- IDE mode: the approved files are already in place. Inline fallback: write them now.
- **Labels** — GitHub backend only: ensure every label of the `§ Backends` table with the label-ensure rule (`gh label create … --force`, idempotent).
- **Migration** — only when consented, per `§ Documentation` (migration of 0.13 repositories):
  1. Stamp the status frontmatter of `§ .grimoire/ layout` on every legacy `SPEC.md` — from its HISTORIC entry with the mapping of `§ .grimoire/ layout` (Legacy pages: `[finished]` → `done`) or, without an entry, from the files present — on every `CONSTRUCT.md` (`open` / `done`), and on every `references/*` file (`pending` / `specced` + `page:`, from the checklist tokens).
  2. `git rm -r -q --ignore-unmatch .grimoire/HISTORIC.md .grimoire/bag/historic` (and remove any untracked leftover of either), then `git rm -r -q --cached --ignore-unmatch .grimoire/pages .grimoire/constructs .grimoire/bag` — those folders stay on disk, now ignored.
  3. Commit **only** those removals: `chore(grimoire): migrate to 0.14 layout` (`§ Commits`).
  4. List the in-progress pages. GitHub backend → warn that they are no longer addressable by number (numbers are now issue numbers) and suggest re-specifying each with `/grimoire-spec`, pasting its `SPEC.md` text.

**[Phase 5: Version Control & Closing]**
- Commit the context files — the `docs/*` written, `.grimoire/PROJECT.md`, `.grimoire/config.toml`, `.gitignore` — and nothing else, per `§ Commits`: `docs(grimoire): initialize project context` (INITIALIZATION) or `docs(grimoire): update project context` (UPDATE).
- Tell the user that every Grimoire skill now loads this context through its `[Required Reading]`, that `.grimoire/config.toml` is hand-editable (`§ Configuration`), and that `/grimoire-note` refines `docs/conventions.md` and `## Grimoire rules` later. Next step: `/grimoire-spec` for a page, or `/grimoire-construct` for a larger objective — never run automatically.

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language`; the `❌`, `📄`, `🔗`, `📁` lines keep their glyphs and literal tokens. Commit messages stay English; `docs/` follow `[docs].language`.
- **Single source of truth.** `§ Documentation` owns every rule this skill applies — this body references it and never restates it.
