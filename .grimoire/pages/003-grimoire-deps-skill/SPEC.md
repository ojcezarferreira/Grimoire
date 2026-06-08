# 003 — grimoire-deps skill

## Context

Dependency management — checking for CVEs, judging *whether* and *when* to update, and watching for supply-chain incidents (the recent Tanstack and Laravel-lang package hijacks) — is tedious, repetitive, and easy to get wrong. The maintainer wants a Grimoire skill that automates the boring part: audit the project's dependencies, score each candidate update, and let the user interactively apply the safe ones. For genuinely large upgrades (breaking changes), the skill should *not* reinvent a planning engine — it should hand off to the existing **Spec → Plan → Execute** pipeline.

This is a **plugin-content page** (dogfooding): it adds a new **orthogonal** skill — `grimoire-deps` — to the Grimoire plugin itself, in the same family as `grimoire-know` / `grimoire-note` / `grimoire-update` (skills that sit outside the Spec → Plan → Execute pipeline).

## Goals

- Add a new skill `skills/grimoire-deps/SKILL.md`, orthogonal to the pipeline, that runs on the **consuming** project.
- **Auto-detect** the project's package ecosystem(s) from manifests/lockfiles (npm/pnpm/yarn, pip/poetry/uv, composer, cargo, go mod, …).
- **Audit** each dependency along four axes:
  1. **Security** — known CVEs/advisories, via the ecosystem's native audit tooling (`npm audit`, `pip-audit`, `composer audit`, …) cross-checked with GitHub Advisory / OSV.
  2. **Semver risk** — patch / minor / major jump.
  3. **Maturity ("baking time")** — how long the target release has existed; very fresh releases are flagged *"deixar maturar"*.
  4. **Reputation / controversy** — supply-chain red flags (hijacked / compromised / malware / deprecation), via `WebSearch` / `WebFetch`.
- Produce a **ranked report** (markdown table) surfaced via `§ IDE-aware review`, with a per-dependency recommendation: **apply** / **wait** / **plan-migration**.
- Let the user **pick which updates to apply** by replying against the report (scales to long dependency lists, unlike a per-dep prompt).
- **Apply** the selected low-risk updates inside a sub-agent: one atomic Conventional-Commit per dependency, running the project's verification gate after each bump and **reverting that dependency's commit** if the gate fails (other applied bumps stay intact).
- For selected **breaking / high-risk** updates, generate an **upgrade brief** (not a page) and instruct the user to run `/grimoire-spec`. The skill never creates a page folder, never writes `SPEC.md`, never touches `HISTORIC.md`.
- Register the new skill across the plugin's docs and bump the plugin version per the release convention.

## Non-goals

- **Not a pipeline skill.** It does not participate in Spec → Plan → Execute and never creates pages, step files, or `HISTORIC.md` entries.
- Does not write `.grimoire/PROJECT.md` (the dual-writer contract `grimoire-init` / `grimoire-note` is unchanged).
- Does not itself execute a breaking-change migration — it only diagnoses and hands off to `grimoire-spec`.
- No dedicated external supply-chain service (Socket.dev / Snyk API) in v1 — native tooling + web search only. No new dependency, no API key.
- Does not invent a new plan-file format — heavy upgrades reuse the existing pipeline.
- Not a continuous / CI monitor — it is an on-demand, interactive skill.

## Scope

- **New:** `skills/grimoire-deps/SKILL.md` — frontmatter (`name`, `description`, `argument-hint`) + prompt body. Body modeled on the orthogonal skills: `[Required Reading]` referencing `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`, a read-mostly audit sub-agent (à la `grimoire-know`) and an apply sub-agent (à la `grimoire-quick`).
- **GRIMOIRE-CONVENTIONS.md** — add `grimoire-deps` to the enumerations that list the orthogonal skills (e.g. `§ Project context`: "all other skills … never write `PROJECT.md`"; the intro skill list). Minimal; no new load-bearing rule unless the plan finds one is genuinely needed (see Open questions on the TDD-exception note).
- **CLAUDE.md** — add `grimoire-deps` to "The skills and how they connect".
- **README.md / README.pt-BR.md** — document the new skill (bilingual).
- **CHANGELOG.md** — new version section.
- **.claude-plugin/plugin.json + .claude-plugin/marketplace.json** — version bump, kept in sync (release trigger).

## Acceptance criteria

- `/grimoire-deps` runs in a consuming project, auto-detects at least the common ecosystems present, and produces a ranked report covering security / semver / maturity / reputation with a clear recommendation per dependency.
- The report is presented via the IDE-aware review flow; the user can select a subset to apply by replying against it.
- Applying a selected safe update produces **one atomic Conventional-Commit per dependency**, runs the project's gate, and **reverts that dependency's commit** (leaving the rest intact) when the gate fails.
- Selecting a breaking / high-risk update yields an **upgrade brief** that routes the user to `/grimoire-spec`; no page folder, `SPEC.md`, or `HISTORIC.md` entry is created by `grimoire-deps`.
- The skill never writes `PROJECT.md` and never participates in the page lifecycle.
- Docs (README ×2, CLAUDE.md, CONVENTIONS enumerations) mention the skill; `plugin.json` and `marketplace.json` versions match and a matching `CHANGELOG.md` section exists.
- Operator-facing messages follow the PT-BR convention; commit / spec / code content stays in English.

## Constraints

- **Orthogonal-skill contract:** no writes to `PROJECT.md` / `HISTORIC.md` / page folders; same family as `grimoire-know` / `grimoire-update` / `grimoire-note`.
- Implementation / apply work runs inside **sub-agents** per `§ Sub-agent spawning`.
- The post-bump verification deliberately runs the **project's broader gate** (test / build / lint), which is a **conscious exception** to the `§ TDD` filter-only rule — a dependency bump has global blast radius, so a filtered test run is insufficient. This exception must be stated explicitly in the skill body so it does not read as a convention violation.
- Reputation / maturity signals are **best-effort heuristics** (web + advisory feeds), never guarantees — the skill must say so and must never present a "clean" verdict as a security guarantee.
- Maturity threshold default ≈ **14 days** (flag younger releases) — value configurable; exact default to confirm at plan time.
- Bilingual docs + versions-in-sync + CHANGELOG-section release rules apply (plugin-content page).

## Open questions

- Exact set of ecosystems to support in v1 vs. marking some as "best-effort / extensible" (resolve in `grimoire-plan`).
- Final maturity-threshold default and whether it is exposed as an argument / config knob.
- Exact columns / format of the ranked report table.
- Whether the upgrade brief is ephemeral chat output or a throwaway file under `.grimoire/bag/drafts/` (lean: ephemeral, IDE-aware like other drafts).
- Whether `GRIMOIRE-CONVENTIONS.md` needs a short new note about the TDD filter-only exception for dependency bumps, or whether stating it in the skill body suffices.

## References

- [skills/grimoire-know/SKILL.md](skills/grimoire-know/SKILL.md) — closest structural analog (orthogonal, spawns a read-mostly sub-agent, web research, citations).
- [skills/grimoire-quick/SKILL.md](skills/grimoire-quick/SKILL.md) — analog for the apply path (sub-agent, plan authorization, atomic commits).
- [GRIMOIRE-CONVENTIONS.md](GRIMOIRE-CONVENTIONS.md) — §§ Sub-agent spawning, Commits, Project context, IDE-aware review, Pause-point pattern, TDD.
- [CLAUDE.md](CLAUDE.md) — "The skills and how they connect" (where the new skill must be described).
- Supply-chain incidents motivating the reputation axis: Tanstack and Laravel-lang package hijacks.
