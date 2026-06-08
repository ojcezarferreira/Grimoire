---
depends-on: []
touches:
  - skills/grimoire-deps/SKILL.md
---

# Step 1 — Write `skills/grimoire-deps/SKILL.md`

This is the load-bearing artifact of page 003. Every other step (2–5) only *describes* the skill you write here, so this step settles its behavior. Model the structure on the orthogonal skills already in the repo: read [skills/grimoire-know/SKILL.md](skills/grimoire-know/SKILL.md) (read-mostly audit sub-agent, web research, citations) and [skills/grimoire-quick/SKILL.md](skills/grimoire-quick/SKILL.md) (apply path: sub-agent, plan authorization, atomic commits) before writing. Re-read [.grimoire/pages/003-grimoire-deps-skill/SPEC.md](.grimoire/pages/003-grimoire-deps-skill/SPEC.md) for the full contract.

## Locked decisions (do not re-derive)

- **Orthogonal skill.** Same family as `grimoire-know` / `grimoire-note` / `grimoire-update`. It runs on the **consuming** project. It NEVER creates a page folder, NEVER writes `HISTORIC.md`, NEVER writes `PROJECT.md`, and never participates in the Spec → Plan → Execute lifecycle.
- **Maturity threshold = 14 days, fixed.** Flag any target release younger than 14 days as *"deixar maturar"*. No argument/config knob — keep it a stated constant in the body.
- **Ecosystems = core set + extensible.** Fully support: npm/pnpm/yarn, pip/poetry/uv, composer, cargo, go mod. Detect and best-effort anything else present.
- **TDD exception stated in THIS body only.** Do NOT edit `GRIMOIRE-CONVENTIONS.md § TDD`. The post-bump gate runs the project's broader test/build/lint (not the filter-only run) because a dependency bump has global blast radius. State this explicitly in the apply phase so it does not read as a convention violation.
- **Upgrade brief = ephemeral throwaway draft** under `.grimoire/bag/drafts/` (IDE-aware, like `grimoire-quick`/`grimoire-update` drafts), deleted at end of run. It is NOT a page and NOT a `SPEC.md`.
- **Report table columns:** `Dependency | Current | Target | Semver jump | CVEs / advisories | Maturity (age) | Reputation | Recommendation`. Recommendation ∈ **apply** / **wait** / **plan-migration**.
- **Operator-facing messages in PT-BR; commit/spec/code content in English** (project convention).

## Frontmatter to write (verbatim shape)

```
---
name: grimoire-deps
description: Audit and update project dependencies — scores CVEs, semver risk, release maturity, and supply-chain reputation; applies safe updates with per-dependency atomic commits and routes breaking upgrades to /grimoire-spec.
argument-hint: Optional dependency or ecosystem to focus on
---
```

(Keep the three frontmatter keys and the `---` delimiters exactly. `$ARGUMENTS` in the body is a runtime substitution — preserve verbatim.)

## Body to write (sections, in order)

1. **`[Required Reading]`** — mirror the orthogonal-skill pattern:
   - Read `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`. State which sections apply: `§ Sub-agent spawning`, `§ Commits`, `§ Project context`, `§ Historic` (read-only consumption), `§ IDE-aware review`, `§ Pause-point pattern`. State that `§ TDD`'s filter-only rule is **deliberately excepted** for the post-bump gate (forward-reference to the apply phase). Note `§ .grimoire/ layout` and the page lifecycle do **not** apply — this skill writes no pages.
   - If `.grimoire/PROJECT.md` exists, read it for project context; if missing, proceed and suggest `grimoire-init` at the end (non-blocking).
   - If `.grimoire/HISTORIC.md` exists, read it read-only for recent context; missing → proceed.

2. **`[Objective]`** — audit the consuming project's dependencies and interactively apply the safe updates. `$ARGUMENTS` is an optional focus filter (a single package or one ecosystem); empty means audit everything detected.

3. **`[Hard constraints — orthogonal skill]`** — explicit bullets: never create a page folder under `.grimoire/pages/`; never write `HISTORIC.md` or `PROJECT.md`; never make page-lifecycle commits; the only files it writes outside the actual dependency bumps are (a) the ephemeral upgrade-brief draft under `.grimoire/bag/drafts/` and (b) the dependency manifest/lockfile changes during apply. Reputation/maturity signals are **best-effort heuristics**, never guarantees — a "clean" verdict must never be presented as a security guarantee.

4. **`[Phase 1: Ecosystem detection]`** — auto-detect package ecosystems from manifests/lockfiles (`package.json` + `package-lock.json`/`pnpm-lock.yaml`/`yarn.lock`; `requirements.txt`/`pyproject.toml`/`poetry.lock`/`uv.lock`; `composer.json`/`composer.lock`; `Cargo.toml`/`Cargo.lock`; `go.mod`/`go.sum`). Core set first-class; others best-effort. Honor the `$ARGUMENTS` focus filter if present.

5. **`[Phase 2: Audit]`** — spawn one read-mostly sub-agent per `§ Sub-agent spawning` (model on `grimoire-know`) with `Read`, `Grep`, `Glob`, read-only `Bash`, `WebSearch`, `WebFetch`. Brief it to score each dependency on the four axes:
   - **Security** — run the ecosystem's native audit (`npm audit`, `pip-audit`, `composer audit`, `cargo audit`, `govulncheck`/`osv-scanner`, …) and cross-check CVEs/advisories against GitHub Advisory / OSV.
   - **Semver risk** — patch / minor / major jump from current → latest acceptable.
   - **Maturity** — release age; flag target releases **younger than 14 days** as *"deixar maturar"*.
   - **Reputation / controversy** — supply-chain red flags (hijacked / compromised / malware / deprecation) via web search (cite the Tanstack and Laravel-lang hijacks as the motivating class of incident).
   - Return structured rows + an explicit list of anything it was uncertain about.

6. **`[Phase 3: Ranked report & selection]`** — render a ranked markdown table (the locked columns) via `§ IDE-aware review`; each row carries a recommendation (**apply** / **wait** / **plan-migration**). PAUSE per `§ Pause-point pattern`: the user selects which updates to apply by replying against the report (must scale to long lists — reply-against-report, not a per-dep prompt). State the best-effort-heuristics disclaimer in the report.

7. **`[Phase 4: Apply selected safe updates]`** — spawn an apply sub-agent (model on `grimoire-quick`). For each selected low-risk update, in turn:
   - Bump exactly one dependency.
   - **Run the project's broader verification gate (test / build / lint), NOT a filtered test run** — state inline that this is a conscious exception to `§ TDD`'s filter-only rule because a dependency bump has global blast radius.
   - On pass: make **one atomic Conventional Commit for that dependency** per `§ Commits` (e.g. `chore(deps): bump <pkg> to <ver>`).
   - On fail: **revert that dependency's bump/commit** and continue; other applied bumps stay intact. Report which were applied, which were reverted.

8. **`[Phase 5: Breaking / high-risk handoff]`** — for any selected `plan-migration` update, generate an **upgrade brief** (ephemeral throwaway draft under `.grimoire/bag/drafts/upgrade-brief-<epoch>.md`, IDE-aware; generate `<epoch>` with `date +%s` and memorize the path). The brief summarizes the breaking upgrade and the migration concerns, then instructs the user to run `/grimoire-spec` to open a page. The skill itself creates NO page, NO `SPEC.md`, NO `HISTORIC.md` entry.

9. **`[Phase 6: Cleanup]`** — delete any ephemeral draft(s) written under `.grimoire/bag/drafts/`. If `PROJECT.md` was missing in Required Reading, remind the user to run `grimoire-init`. End.

## TDD / process for this step

This page is plugin content (markdown only) — there is no test suite. Do not invent one. Produce the file, then verify by re-reading it that: frontmatter keys are intact, every locked decision above is reflected, and no instruction tells the skill to write `PROJECT.md`/`HISTORIC.md`/a page.

## Commit

One atomic commit per `§ Commits`: `docs(grimoire): add grimoire-deps skill`. Commit only `skills/grimoire-deps/SKILL.md`.
