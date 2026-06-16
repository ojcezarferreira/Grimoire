# Step 1 — Author `§ Skill composition` in `GRIMOIRE-CONVENTIONS.md`

Author the new shared convention section that is the **single source of truth**
for how every Grimoire skill discovers and uses other locally-installed skills.
This is the load-bearing step — Steps 2 and 3 only wire it in and release it.

`§ TDD` does not apply (no code). This step edits only
`GRIMOIRE-CONVENTIONS.md`.

## Decisions locked at plan time

- **Section name:** `§ Skill composition`.
- **Placement:** immediately **after `§ Sub-agent spawning`** and before
  `§ Parallel execution`. Both sections govern how the orchestrator delegates
  work (to sub-agents, and to sibling skills), so they read as a pair.
- **Announcement template:** ship a short reusable `🧩`-prefixed one-liner
  (see below) so helper announcements stay uniform across all 11 skills.

## What to write

Insert a new `## § Skill composition` section in `GRIMOIRE-CONVENTIONS.md`,
positioned right after the `## § Sub-agent spawning` section (and its trailing
`---` rule), before `## § Parallel execution`. The section must specify all of
the following, each as a clearly-labeled rule:

1. **Discovery mechanism (no FS scan).** The orchestrator surveys the
   skill list the Claude Code runtime injects into context (the "available
   skills" block) together with the `Skill` tool registry, and matches
   candidate helpers by each skill's `description`. State explicitly that
   Grimoire performs **no filesystem scanning** of skill directories
   (`~/.claude/skills/`, project `.claude/skills/`, or plugin caches).

2. **Invocation posture: discover always; invoke with a one-line announcement.**
   - **Read-only / assistive helpers** (research, review, verification,
     docs-lookup, etc.) are used **automatically** when one materially helps,
     announcing in one line which helper ran and why.
   - **Helpers that write, have side-effects, or change the task's scope** are
     surfaced as a candidate and require an explicit user **"ok"** first. This
     gate **folds into the skill's existing `§ Pause-point pattern`
     checkpoints** — it does **not** add a new pause-point or pipeline phase.

3. **Announcement template.** Define a single reusable operator-facing
   one-liner for read-only/assistive use, prefixed with the `🧩` glyph, e.g.:

   `🧩 Using <skill-name> to <reason>.`

   State that, like the `❌` and `📄` glyphs, the `🧩` glyph and the
   `<skill-name>` are preserved verbatim while the surrounding prose is
   localized per `§ User-facing language`. The "may I use `<skill-name>`?"
   gating prompt for write/scope-changing helpers is likewise operator-facing
   prose, localized the same way.

4. **Guardrails / exclusions.**
   - **Exclude conflicting orchestrators / planners** — any skill that would
     duplicate or fight Grimoire's own Spec → Plan → Execute pipeline (a
     competing `init` / `plan` / `review` / spec workflow) is never composed
     with.
   - A helper skill **never** takes write-ownership of `.grimoire/` state
     (`PROJECT.md`, `HISTORIC.md`, `CONSTRUCT.md`, page/construct folders).
   - A helper **never** overrides Grimoire's own contracts: `§ TDD`,
     `§ Commits`, `§ Pause-point pattern`, `§ Historic` ownership, the
     `§ Project context` / `§ Construct` dual-writer contracts, and every
     hard-stop stay in force regardless of any helper invoked.

5. **Grimoire-on-Grimoire.** Grimoire's own skills MAY invoke one another where
   a sibling genuinely helps, but each sibling keeps its own write-ownership and
   hard-stops; composition **never bypasses a precondition hard-stop**.

6. **Localization pointer.** All helper announcements and any "may I use X?"
   prompts are operator-facing prose rendered in the user's language per
   `§ User-facing language` (command/skill names and the `🧩` glyph preserved
   verbatim).

7. **Applicability note.** The convention applies to **every** skill, but each
   skill composes only *where a helper materially helps* — a skill that rarely
   finds a relevant helper (e.g. `grimoire-update`) simply rarely composes.
   Discovery is always performed; invocation is need-driven.

## Internal-consistency requirement

Before finishing, re-read the neighboring sections and confirm the new section
does **not** contradict existing rules:

- It must not weaken `§ Project context` / `§ Historic` / `§ Construct`
  write-ownership (helpers never own `.grimoire/` state).
- It must not invent a new pause-point — the write/scope gate folds into
  existing `§ Pause-point pattern` checkpoints.
- It must not override `§ TDD` or `§ Commits`.
- Announcement/gating localization must defer to `§ User-facing language`, not
  restate it.

## Intro section-list update

The file's top-of-file intro paragraph (the sentence listing which skills
reference this file) does not enumerate every `§` by name, so no per-section
list edit is required there. **However**, verify whether any intro/overview
sentence enumerates the section names; if one does, add `§ Skill composition`
to it in the correct (post-`§ Sub-agent spawning`) order. If no such
enumeration exists, make no intro edit.

## Acceptance for this step

- `GRIMOIRE-CONVENTIONS.md` contains a new `## § Skill composition` section
  placed immediately after `§ Sub-agent spawning`, specifying: runtime-list
  discovery (no FS scan), the discover-always / announce-on-use /
  gate-write-and-scope-changing-helpers posture, the `🧩` announcement
  template, exclusion of conflicting orchestrators, the "helpers never own
  `.grimoire/` state or override Grimoire contracts" guardrail, the
  Grimoire-on-Grimoire allowance, the `§ User-facing language` localization
  pointer, and the applicability note.
- No existing section is contradicted.

## Commit

Per `§ Commits`, end this step with a single atomic commit:

`docs(grimoire): add skill-composition convention`
