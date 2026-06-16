---
name: grimoire-deps
description: Audit and update project dependencies — scores CVEs, semver risk, release maturity, and supply-chain reputation; applies safe updates with per-dependency atomic commits and routes breaking upgrades to /grimoire-spec.
argument-hint: Optional dependency or ecosystem to focus on
---

**[Required Reading]**
1. Read `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`. The sections that apply to this skill are: `§ Sub-agent spawning` (the audit and apply sub-agents), `§ Commits` (per-dependency atomic Conventional Commits in English), `§ Project context` and `§ Historic` (read-only consumption only), `§ IDE-aware review` (the ranked report and the upgrade brief), `§ User-facing language`, and `§ Pause-point pattern` (the report selection pause). **Exception:** `§ TDD`'s filter-only rule is **deliberately excepted** for the post-bump verification gate in Phase 4 — a dependency bump has global blast radius, so the gate runs the project's broader test/build/lint, not a filtered test run (see Phase 4 for the full rationale). **Not applicable:** `§ .grimoire/ layout` and the Spec → Plan → Execute page lifecycle do **not** apply — this skill is orthogonal (same family as `grimoire-know` / `grimoire-note` / `grimoire-update`) and writes no pages, no `SPEC.md`, and no `HISTORIC.md` entries.
2. If `.grimoire/PROJECT.md` exists in the project root, read it for project context (tech stack, conventions, verification gate). If it does not exist, proceed without it and, at the end of the run, suggest the user run `grimoire-init` once to enrich future runs (non-blocking — never refuse to audit because `PROJECT.md` is missing).
3. If `.grimoire/HISTORIC.md` exists, read it read-only for recent-page context. Missing → proceed without it.

**[Objective]**
Audit the consuming project's dependencies along four axes (security, semver risk, maturity, reputation), present a ranked report, and interactively apply the safe updates the user selects. Breaking / high-risk upgrades are NOT executed here — they are handed off to the Spec → Plan → Execute pipeline via an upgrade brief.

`$ARGUMENTS` is an optional focus filter: a single package name or one ecosystem to scope the audit to. When empty, audit every ecosystem and dependency detected in the project.

**[Hard constraints — orthogonal skill]**
- Never create a page folder under `.grimoire/pages/`.
- Never write to `.grimoire/HISTORIC.md`.
- Never write to `.grimoire/PROJECT.md` (the dual-writer contract `grimoire-init` / `grimoire-note` is unchanged).
- Never make page-lifecycle commits (`docs(grimoire): spec …`, `chore: register …`, `chore: mark … planned/finished`). This skill never participates in the page lifecycle.
- The only files this skill writes — beyond the actual dependency bumps — are: (a) the ephemeral upgrade-brief draft under `.grimoire/bag/drafts/` (Phase 5), deleted in Phase 6; and (b) the dependency **manifest/lockfile changes** produced during the apply phase (Phase 4). The dependency bumps are committed; the draft is not.
- Reputation and maturity signals are **best-effort heuristics** (native audit tooling + advisory feeds + web search), never guarantees. A "clean" verdict must NEVER be presented as a security guarantee. State this disclaimer in the report.

**[Phase 1: Ecosystem detection]**
- Auto-detect the package ecosystems present by scanning for manifests and lockfiles at the project root (and obvious sub-projects):
  - **npm / pnpm / yarn** — `package.json` + `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock`.
  - **pip / poetry / uv** — `requirements.txt` / `pyproject.toml` / `poetry.lock` / `uv.lock`.
  - **composer** — `composer.json` / `composer.lock`.
  - **cargo** — `Cargo.toml` / `Cargo.lock`.
  - **go mod** — `go.mod` / `go.sum`.
- The five ecosystem families above are the **core set** and are first-class. Any other ecosystem present (e.g. Gemfile, gradle, pubspec, …) is handled **best-effort**: detect it, audit what the native tooling allows, and flag in the report where coverage is partial.
- If `$ARGUMENTS` names a single package or one ecosystem, honor it as a **focus filter** — restrict detection and the rest of the run to that scope. Empty → audit everything detected.
- If no recognizable ecosystem is found, tell the user (PT-BR) that nothing auditable was detected and end.

**[Phase 2: Audit]**
- Spawn **one read-mostly audit sub-agent** per `§ Sub-agent spawning`, modeled on `grimoire-know`, with `Read`, `Grep`, `Glob`, read-only `Bash`, `WebSearch`, and `WebFetch`. The sub-agent must not mutate the project, must make no commits, and must not touch any `.grimoire/` state file.
- Brief it with a self-contained prompt naming the detected ecosystems, the focus filter (if any), and instructions to score **each dependency** on these four axes:
  - **Security** — run the ecosystem's native audit tool (`npm audit` / `pnpm audit` / `yarn audit`, `pip-audit`, `composer audit`, `cargo audit`, `govulncheck` or `osv-scanner`, …) and cross-check the reported CVEs / advisories against the GitHub Advisory Database and OSV.
  - **Semver risk** — classify the jump from the currently-installed version to the latest acceptable version as **patch**, **minor**, or **major**.
  - **Maturity ("baking time")** — determine the target release's age. **Flag any target release younger than 14 days as *"deixar maturar"*.** The 14-day threshold is a fixed constant for this skill — there is no argument or config knob.
  - **Reputation / controversy** — search the web (`WebSearch` / `WebFetch`) for supply-chain red flags: hijacked / compromised / malware-injected / deprecated packages. The motivating class of incident is the recent **Tanstack** and **Laravel-lang** package hijacks — treat those as the kind of signal worth surfacing.
  - The sub-agent must return **structured rows** (one per dependency, carrying the four-axis findings and the consulted URLs) plus an **explicit list of anything it was uncertain about**.

**[Phase 3: Ranked report & selection]**
- Render a **ranked markdown table** from the sub-agent's rows, ordered most-urgent-first (security and reputation issues at the top). The table columns are exactly:

  `Dependency | Current | Target | Semver jump | CVEs / advisories | Maturity (age) | Reputation | Recommendation`

  Each row's **Recommendation** is one of: **apply** (safe, low-risk), **wait** (e.g. too fresh — *"deixar maturar"* — or an unresolved reputation flag), or **plan-migration** (breaking / high-risk — routed to `/grimoire-spec`).
- Surface the report via `§ IDE-aware review`:
  - **IDE detected:** write the report to a throwaway draft under `.grimoire/bag/drafts/` (create the folder if needed; generate `<epoch>` with `date +%s` and memorize the path) so the IDE renders it, and tell the user in one short PT-BR line that the report is open in the editor.
  - **Terminal-only fallback:** print the table inline.
- Include the **best-effort-heuristics disclaimer** in the report: reputation and maturity are advisory signals, not security guarantees; a "clean" row is not a guarantee of safety.
- Append the audit sub-agent's **"uncertain about"** list when non-empty, and a **References** section listing the consulted URLs when the web was actually used.
- PAUSE per `§ Pause-point pattern`: the user selects which updates to apply by **replying against the report** (e.g. by dependency name or row number). This reply-against-report model is deliberate so it scales to long dependency lists — never prompt per dependency. Wait for the user's selection before proceeding.

**[Phase 4: Apply selected safe updates]**
- Spawn an **apply sub-agent** per `§ Sub-agent spawning`, modeled on `grimoire-quick`. Process the user's selected low-risk updates **one at a time**, and for each:
  1. **Bump exactly one dependency** (edit the manifest and refresh the lockfile for that single package).
  2. **Run the project's broader verification gate — its test / build / lint — NOT a filtered test run.** State inline to the sub-agent that this is a **conscious, documented exception** to `§ TDD`'s filter-only rule: a dependency bump has global blast radius, so a filtered run would not detect the regressions a bump can cause. This is by design, not a convention violation.
  3. **On pass:** make **one atomic Conventional Commit for that dependency** per `§ Commits`, e.g. `chore(deps): bump <pkg> to <ver>` (in English).
  4. **On fail:** **revert that dependency's bump (and its commit, if already made)** and continue to the next selected update. Other already-applied bumps stay intact — one failure does not roll back the batch.
- After the batch, report (PT-BR) which dependencies were **applied** and which were **reverted**.

**[Phase 5: Breaking / high-risk handoff]**
- For any selected **plan-migration** update, generate an **upgrade brief**: a concise summary of the breaking upgrade and its migration concerns (what changed, what will likely break, what the migration must cover).
- Write the brief as an **ephemeral throwaway draft** at `.grimoire/bag/drafts/upgrade-brief-<epoch>.md`, IDE-aware (create the folder if needed; generate `<epoch>` with `date +%s` and memorize the full path for Phase 6). This is **not a page and not a `SPEC.md`**.
- Instruct the user (PT-BR) to run `/grimoire-spec` to open a page from the brief. **This skill creates NO page folder, NO `SPEC.md`, and NO `HISTORIC.md` entry** — it only diagnoses and hands off.

**[Phase 6: Cleanup]**
- Delete every ephemeral draft written under `.grimoire/bag/drafts/` during this run (the Phase 3 report draft in IDE mode, and any Phase 5 upgrade brief). The applied dependency-bump commits stay; the drafts do not.
- If `.grimoire/PROJECT.md` was missing in `[Required Reading]`, remind the user (PT-BR) that running `grimoire-init` once would enrich future runs.
- End.
