---
name: grimoire-note
description: Surgically fold a free-text note into the project's context — each rule is routed to docs/conventions.md (how code is written here) or to .grimoire/PROJECT.md's Grimoire rules (how the Grimoire agents behave here), with semantic dedup, retroactive consolidation, and IDE-aware diff review.
argument-hint: Free-text note(s) to fold into docs/conventions.md or PROJECT.md's Grimoire rules
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Documentation` (the routing rule, the synthesis discipline, the dual-writer contract), `§ Configuration`, `§ Harness adaptation`, `§ Skill composition`, `§ Commits`, `§ IDE-aware review`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ TDD`, `§ Code comments`, `§ Sub-agent spawning` (this skill spawns nothing), `§ Backends`, `§ .grimoire/ layout` (pages), `§ Construct`, `§ Parallel execution`, `§ Review loop`, `§ Run` — this skill is orthogonal to the page pipeline and never creates a page.
2. `.grimoire/PROJECT.md` (the index) and `docs/conventions.md` are this skill's **targets** — read them in Phase 1, where the hard-stop is checked.
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice) — `[docs].dir` locates `conventions.md`.
4. Backend detection is skipped per `§ Backends` (who detects) — this skill never reads or writes pages, constructs, or PRs.

**[Objective]**
Fold the user's free-text note(s) into the project's context with surgical, incremental edits — each rule routed per `§ Documentation` to `docs/conventions.md` or to `.grimoire/PROJECT.md` `## Grimoire rules`. Never rewrite a whole file, never add a section, never regenerate a skeleton — only sharpen what is already there or append a single well-phrased entry.

$ARGUMENTS

**[Hard constraints]**
- Only `docs/conventions.md` and the `## Grimoire rules` section of `.grimoire/PROJECT.md` may be edited (`§ Documentation`, dual-writer contract). No other file, no other section, no section header added, renamed, or removed.
- Never create `.grimoire/PROJECT.md` — hard-stop instead. `docs/conventions.md` MAY be created — a heading plus the routed rule(s) — when a rule routes there and the file is missing; no other `docs/*` file is ever created (`§ Documentation`).
- Never create a page, never touch a backend object, never spawn a sub-agent.

**[Phase 1: Precondition Check (HARD STOP)]**
Per `§ Pause-point pattern` (`grimoire-note`: precondition check): `.grimoire/PROJECT.md` is missing → print

> ❌ .grimoire/PROJECT.md does not exist.
> There is nowhere to write — run `/grimoire-init` first, then re-invoke `/grimoire-note`.

STOP. Never create a skeleton; never offer to run `grimoire-init` automatically. Otherwise read `## Grimoire rules` and `docs/conventions.md` in full. `docs/conventions.md` missing → it is created at Phase 6 only if a rule routes to it — a heading plus the routed rule(s), in `[docs].language`.

**[Phase 2: Input Parsing & Semantic Split]**
Parse the user's free-text input. Semantically split it into N distinct rules when the input carries several (e.g., two sentences encoding two unrelated conventions). Single-rule inputs stay as one entry. Produce a structured list internally — the user-facing surface of the split happens at Phase 6 ("Detected N distinct rules: …").

**[Phase 3: Routing]**
Classify each rule per `§ Documentation` (`grimoire-note`):
- **How code is written in this repository** (naming, structure, testing, error handling, commit style, constraints, notes about the code) → `docs/conventions.md` — neutral wording, zero Grimoire vocabulary, in `[docs].language`.
- **How the Grimoire agents must behave here** (e.g. "never touch `legacy/`", "always ask before editing migrations") → `.grimoire/PROJECT.md` `## Grimoire rules`.
- **Ambiguous** → propose the likelier target and ask at the Phase 6 pause — no separate question.

**[Phase 4: Synthesize Against the Target]**
For each rule, run a semantic pass against every existing entry of its target (all of `docs/conventions.md`, or all of `## Grimoire rules`) to detect:

- **Duplication** — the new rule already exists verbatim or in spirit.
- **Refinement** — the new rule sharpens or constrains an existing one.
- **Generalization** — the new rule subsumes (or is subsumed by) an existing one.
- **Contradiction** — the new rule conflicts with an existing one.

For each detected relationship, propose the best synthesis: merge, rewrite, generalize, or accept as new. **Minimum-word phrasing is an explicit objective** — favor terse, declarative entries over verbose ones, and prefer rewriting two near-duplicate lines into one over appending a third. In `docs/conventions.md`, place a new entry under the existing heading that fits best; when none fits, use the closest one and flag the misfit at Phase 6 so the user can override. **Never create a new section.**

**[Phase 5: Retroactive Consolidation Pass]**
Independently of the new input, scan the existing entries of both targets and propose rewrites where synthesis can be improved: consolidate near-duplicates, tighten verbose phrasings, merge adjacent rules that say the same thing — and flag any entry that sits in the wrong target per Phase 3 (moving it is part of the proposal). This pass runs **every invocation**, not just when the new input triggers it — the synthesis discipline keeps both files naturally small.

**[Phase 6: IDE-Aware Review]**
Per `§ IDE-aware review`:

**Snapshot first.** Before the first write, snapshot each target file — its content, or the fact that it is absent — into `.grimoire/bag/drafts/note-backup-<epoch>/`, the rule-7 way of `§ IDE-aware review`. A target that already had uncommitted changes is named in a warning at the pause (its changes would land in the commit).

- **IDE detected:** write the proposed content directly to the touched file(s) — their final destinations — and tell the user in one short line which files are open and what answer you're waiting for, e.g. `📄 Draft opened at docs/conventions.md and .grimoire/PROJECT.md — review it in the editor and say "ok" to proceed, or list changes.`
- **Terminal-only fallback:** present the diff inline in chat.

At this checkpoint also surface: the Phase 2 split (`Detected N distinct rules: …`), the target chosen for each rule, every ambiguous classification as a question, and any misfit placement.

PAUSE per `§ Pause-point pattern` (`grimoire-note`: draft review). Wait for explicit approval, requested edits, or abandonment.

- **On approval:** delete the snapshot and proceed to Phase 7.
- **On requested edits:** re-apply Phases 3–5 with the user's corrections and re-pause.
- **On abandonment:** restore every target from the snapshot (a file that was absent — e.g. a `docs/conventions.md` this run created — is deleted), then delete the snapshot — never leave an unapproved file on disk.

**[Phase 7: Commit]**
Per `§ Commits`:

- One atomic commit per invocation, message exactly: `docs(grimoire): refine project context`.
- The commit covers **only** the touched file(s) — stage exactly `docs/conventions.md` and/or `.grimoire/PROJECT.md` with `git add <paths>`, never `git add -A` or `git commit -a`. Any other path already staged is unstaged (`git restore --staged <path>`); any other dirty file stays out of this commit, and the user is warned.

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language`; the `❌` and `📄` lines keep their glyphs and literal tokens. Commit messages stay English; `docs/conventions.md` follows `[docs].language`.
- **Single source of truth.** The routing rule and the dual-writer contract between `grimoire-init` and `grimoire-note` live in `§ Documentation` — do not duplicate them here.
