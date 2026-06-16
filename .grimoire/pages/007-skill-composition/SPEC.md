# 007 — Skill composition: discover and use local helper skills

## Context

Today every Grimoire skill works in isolation from the rest of the user's
Claude Code environment. If the user has other locally-installed skills that
could materially help the task at hand (e.g. `deep-research` for a research
question, `code-review` / `verify` after writing code, a framework-docs skill
for an unfamiliar API), nothing in the Grimoire skill bodies tells the
orchestrator to notice them or use them. The work is done with whatever is in
the skill body and nothing else.

The user wants every Grimoire skill to **always survey the other skills
installed locally** and **make use of the relevant ones automatically**, within
guardrails that preserve Grimoire's core ethos: it never silently takes a
scope- or state-changing decision away from the user.

This is a **cross-cutting convention change**, identical in shape to the
finished page `006-user-facing-language`: a new shared `§` section in
`GRIMOIRE-CONVENTIONS.md` is authored once and wired into the
`[Required Reading]` block of all 11 SKILL.md files, then shipped with a version
bump and a CHANGELOG entry. No new skill and no code are produced — the entire
change lives in prompt/convention text.

## Goals

- Add a new shared convention section **`§ Skill composition`** to
  `GRIMOIRE-CONVENTIONS.md` (final section name negotiable at plan time) that is
  the single source of truth for how Grimoire skills discover and use other
  locally-installed skills. It must define:
  - **Discovery mechanism (decision 1A):** the orchestrator surveys the
    skill list the Claude Code runtime injects into context (the "available
    skills" block) plus the `Skill` tool registry, and matches candidates by
    each skill's `description`. **No filesystem scanning** of skill directories.
  - **Invocation posture (decision 2A):** *discover always; invoke with a
    one-line announcement.* Read-only / assistive helpers (e.g. research,
    review, verification, docs-lookup skills) are used automatically, announcing
    in one line which helper ran and why. Helpers that **write, have
    side-effects, or change the task's scope** are surfaced as a candidate and
    require an explicit user "ok" first — this gate folds into the skill's
    existing `§ Pause-point pattern` checkpoints rather than adding a new one.
  - **Guardrails / exclusions (decision 3):** explicitly **exclude conflicting
    orchestrators / planners** (any skill that would duplicate or fight
    Grimoire's own Spec → Plan → Execute pipeline, e.g. a competing
    `init` / `plan` / `review` workflow). A helper skill **never** takes
    write-ownership of `.grimoire/` state (`PROJECT.md`, `HISTORIC.md`,
    `CONSTRUCT.md`, page folders) and **never** overrides Grimoire's own
    contracts: `§ TDD`, `§ Commits`, `§ Pause-point pattern`, `§ Historic`
    ownership, and the dual-writer contracts stay in force.
  - **Grimoire-on-Grimoire:** Grimoire's own skills MAY invoke one another where
    a sibling genuinely helps, but each sibling keeps its own write-ownership and
    hard-stops; composition never bypasses a precondition hard-stop.
  - **Localization:** helper announcements and any "may I use X?" prompts are
    operator-facing prose and are rendered in the user's language per
    `§ User-facing language` (command/skill names preserved verbatim).
  - **Applicability note:** the convention applies to every skill, but each
    skill uses a helper only *where one materially helps* — a skill that rarely
    finds a relevant helper (e.g. `grimoire-update`) simply rarely composes.
- Wire `§ Skill composition` into the `[Required Reading]` section-name list at
  the top of **all 11** `SKILL.md` files (decision 4), matching how
  `§ User-facing language` was wired across the suite.
- Bump the plugin version in `.claude-plugin/plugin.json` **and**
  `.claude-plugin/marketplace.json` (kept in sync), and add a matching
  `CHANGELOG.md` section describing the new convention (decision 5).

## Non-goals

- **No filesystem scanning** of `~/.claude/skills/`, project `.claude/skills/`,
  or plugin caches (decision 1A rejects option 1B).
- **No new skill, no source code, no runtime tooling** — no skill registry,
  cache, or discovery script. The deliverable is convention + skill-body text.
- **No change to the pipeline structure** or to the meaning of any existing
  pause-point, hard-stop, or write-ownership rule. Helper-gating only *folds
  into* existing pause-points; it does not invent new pipeline phases.
- **No duplication** of the rule body inside any SKILL.md — bodies only
  reference `§ Skill composition` (the single-source-of-truth discipline).
- Not handling the version bump / CHANGELOG as a separate page — it ships inside
  this page (decision 5).

## Scope

- `GRIMOIRE-CONVENTIONS.md` — author the new `§ Skill composition` section; pick
  its placement among the existing sections; update the intro section-list
  sentence if present.
- All 11 `skills/*/SKILL.md` — add `§ Skill composition` to each
  `[Required Reading]` block's list of load-bearing sections
  (`grimoire-init`, `grimoire-spec`, `grimoire-plan`, `grimoire-execute`,
  `grimoire-quick`, `grimoire-know`, `grimoire-note`, `grimoire-deps`,
  `grimoire-construct`, `grimoire-construct-update`, `grimoire-update`).
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` — version
  bump, kept identical (CI enforces parity).
- `CHANGELOG.md` — new version section (the release workflow extracts notes from
  it, so it ships in the same change, not as a follow-up).

## Acceptance criteria

- `GRIMOIRE-CONVENTIONS.md` contains a new `§ Skill composition` section that
  specifies: runtime-list-based discovery (no FS scan), the
  discover-always / announce-on-use / gate-write-and-scope-changing-helpers
  posture, exclusion of conflicting orchestrators, the "helpers never own
  `.grimoire/` state or override Grimoire contracts" guardrail, the
  Grimoire-on-Grimoire allowance, and the `§ User-facing language` localization
  pointer.
- All 11 `SKILL.md` `[Required Reading]` blocks list `§ Skill composition`
  among their load-bearing sections.
- No SKILL.md body restates the rule — each only references the section name.
- `plugin.json` and `marketplace.json` carry the same new version, and
  `CHANGELOG.md` has a section for exactly that version describing this change.
- The new section is internally consistent with existing conventions: it does
  not contradict `§ Project context` / `§ Historic` / `§ Construct`
  write-ownership, `§ Pause-point pattern`, `§ TDD`, or `§ Commits`.

## Constraints

- Convention/skill source strings are **English canonical templates**; runtime
  output is localized per `§ User-facing language`.
- Follow `§ Commits` (Conventional Commits, English, atomic). Plugin-content
  edits use the `docs(grimoire): ...` namespace.
- `§ TDD` does not apply (no code). `marketplace.json` version **must** match
  `plugin.json` or release CI fails; the CHANGELOG section must exist for the
  new version before release.
- Preserve SKILL.md frontmatter and the `${CLAUDE_PLUGIN_ROOT}` /
  `$ARGUMENTS` / `$1` substitutions verbatim.
- The new convention must not weaken Grimoire's "never silently choose for the
  user" stance: any helper that writes, has side-effects, or changes scope is
  gated by an explicit user ok.

## Open questions

- Final name of the section (`§ Skill composition` vs e.g. `§ Skill discovery`
  / `§ Composing with other skills`) and its placement order within
  `GRIMOIRE-CONVENTIONS.md` — to settle at plan time.
- Whether the section should ship a short reusable announcement-string template
  (e.g. an `🧩`-prefixed one-liner) or leave the wording free-form per skill —
  to settle at plan time.
- Exact semver increment (minor `0.13.0` vs patch) — likely a minor, as it adds
  a user-visible behavior; confirm at plan/execute time.

## References

- `GRIMOIRE-CONVENTIONS.md` — `§ User-facing language`, `§ Pause-point pattern`,
  `§ Project context`, `§ Historic`, `§ Construct`, `§ Sub-agent spawning`
  (placement neighbor candidates).
- Finished page `006-user-facing-language` — the template for a cross-cutting
  convention wired into all 11 Required Reading blocks plus version/CHANGELOG.
- `.grimoire/PROJECT.md` — "never silently choose for the user" ethos that the
  invocation posture must honor.
- `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`,
  `CHANGELOG.md` — release-parity constraints.
