---
name: grimoire-construct
description: Research + interview a larger-than-a-page objective into a construct — an ordered list of page-sized reference-seeds, with dependencies where references are genuinely independent — stored as a GitHub milestone with one grimoire:reference issue per reference, locally under .grimoire/constructs/NNN-<name>/, or natively as an agentes.chat Drive document and board references. Commits nothing.
argument-hint: An objective too large for one page, or a path to a construct brief
---

**Managed catalog bootstrap (agentes.chat, Grimoire 0.14.1).** Before Required Reading, read `AGENTES-CHAT.md` from the matching distribution, or from `https://raw.githubusercontent.com/ojcezarferreira/Grimoire/v0.14.1/AGENTES-CHAT.md` through the connector/public fetch. Follow its bootstrap when `${GRIMOIRE_HOME}` is unresolved: catalog import does not run the installer. On agentes.chat its transport, permissions, native construct dispatch and managed-update rules refine the CLI examples below. Outside agentes.chat, use the normal installed-home flow.

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Construct` (the single source of truth for the construct — storage per backend, reference status, `depends-on` between references, writer contract, handoff brief), `§ Backends` (milestone and page markers, labels, `gh` cheat sheet), `§ .grimoire/ layout` (local construct folder + frontmatter), `§ Sub-agent spawning` (the `research` role), `§ Harness adaptation`, `§ Configuration`, `§ Documentation`, `§ Skill composition`, `§ Commits` (this skill commits **nothing**), `§ IDE-aware review`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ TDD`, `§ Code comments`, `§ Parallel execution`, `§ Review loop`, `§ Run` — this skill is orthogonal to the page pipeline and creates no page. **Do not restate any `§ Construct` rule in this body — reference it.**
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and any other linked doc the objective touches. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` at the end (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice).
4. Detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). Missing required GitHub access → stop per `§ Backends`; on agentes.chat a verified connector qualifies without `gh`. Resolve construct storage independently when this skill touches constructs.
5. **If invoked with a handoff brief** — a path to (or the pasted content of) a `.grimoire/bag/drafts/construct-brief-<epoch>.md` written by `grimoire-spec`'s size-evaluation pause — read it as the seed of the objective and memorize its exact path for Phase 6.

**[Objective]**
Turn the user's larger-than-a-page objective (or the seeding handoff brief) into a **construct** per `§ Construct`: a flat, ordered list of page-sized reference-seeds, each later expanded by `grimoire-spec` — through its full interview — into one real page. The construct is the roadmap-of-record; the pages it spawns are the actual work.

User's objective (or handoff-brief path / content):

$ARGUMENTS

**[Hard constraints — orthogonal skill]**
- Never create a page: no `grimoire:spec` issue, no `.grimoire/pages/` folder. Never write `docs/`, `PROJECT.md`, or `config.toml` (`§ Documentation`).
- This skill is the only one that brings a construct into existence (`§ Construct`, writer contract). Keep it flat and self-contained.

**[Phase 1: Research]**
Spawn `research` sub-agent(s) (`§ Sub-agent spawning`, `§ Harness adaptation`) so the orchestrator stays lucid; the orchestrator keeps the interview, the identity, and the writes.
- Brief each one with the objective (or the brief's content), the docs pointers of `[Required Reading]` step 2, and — when the objective's established shape depends on facts outside the repo — permission to search the web.
- Goal: the **decomposition** — a flat, ordered list of reference-seeds, **each sized to one normal page** (split what a single spec interview could not cover; merge trivial slivers), **and** the `depends-on` between references wherever some are genuinely independent of each other (`§ Construct`, `depends-on` between references).
- It returns the ordered list (one-line description + size / ordering rationale per reference), the proposed dependencies, and an explicit list of uncertainties. No invented facts — uncertainties become Phase 2 questions.

**[Phase 2: Clarifying Questions]**
Per `§ Pause-point pattern` (`grimoire-construct`: clarifying questions): ask only what the codebase and the brief cannot answer — scope boundaries, decomposition granularity, the execution order, and the proposed `depends-on`. Surface the research uncertainties. PAUSE and iterate to consensus on the ordered list and its dependencies before authoring anything.

**[Phase 3: Construct Identity]**
- **agentes.chat:** when native construct storage is selected, use `AGENTES-CHAT.md` (native identity/model), before the GitHub/local branches below.
- **GitHub:** the milestone title = the construct `<name>` — short, descriptive, meaningful on its own. The construct number is the milestone number GitHub assigns at creation (Phase 5).
- **Local:** list `.grimoire/constructs/`, take `max(NNN) + 1` zero-padded to 3 digits (`001` when empty or absent) — an independent counter (`§ .grimoire/ layout`) — plus a kebab-case `<name>` (2–5 words). Folder: `.grimoire/constructs/NNN-<name>/`.

**[Phase 4: Compose & Draft Review]**
Compose the construct per `§ Construct` (storage per backend) — content in English:
- the **intro**: the larger objective, the arc, the relevant research findings;
- the **ordered reference list**, every entry pending, with its one-line description and its dependencies;
- one **seed per reference**: what that future page must deliver — intent, scope hints, constraints, acceptance signals — enough for `grimoire-spec` to run a full interview from it.

Present it per `§ IDE-aware review`:
- **agentes.chat:** present the document intro/list and every native reference seed at the same review checkpoint; create no remote objects until covered by authorization.
- **GitHub:** the throwaway draft `.grimoire/bag/drafts/construct-<epoch>.md`, holding the future milestone description and every reference seed.
- **Local:** the final destination — `CONSTRUCT.md` (frontmatter `status: open`, intro, checklist in the `§ Construct` local format) and `references/N-<short-name>.md` in execution order (frontmatter `status: pending` and, when set, `depends-on` — earlier references only).
- Terminal-only → inline.

PAUSE per `§ Pause-point pattern` (`grimoire-construct`: draft review). Edits → revise in place and re-pause. Abandonment → delete everything the draft created (`§ IDE-aware review`).

**[Phase 5: Persist]** — no commit (`§ Commits`)
- **agentes.chat:** use the native creation/recovery protocol in `AGENTES-CHAT.md`, read back the document and all reference issues, then clean up the draft/brief only on complete success. Skip both GitHub/local persistence branches.
- **GitHub**, in this order:
  1. Create the milestone — `gh api repos/{owner}/{repo}/milestones -f title="<name>" -F description=@desc.md`, the description holding line 1 `<!-- grimoire:construct v=1 -->` and the intro — to obtain its number `M`.
  2. Ensure the `grimoire:reference` label (label-ensure rule, `§ Backends`). Then, in list order, create one issue per reference: `gh issue create -t "<title>" -F body.md -l grimoire:reference -m "<milestone title>"`, the body's line 1 being `<!-- grimoire:page v=1 construct=#M order=<n> depends-on=<issue numbers> -->` (omit `depends-on` when empty), followed by the seed. Dependencies use the issue numbers created earlier in this loop.
  3. Complete the milestone description — marker line, intro / arc / findings, then `## References`: the numbered list `1. #<issue> — <one line>` in execution order, with the optional `(after #…)` suffix mirroring the dependencies (`gh api -X PATCH repos/{owner}/{repo}/milestones/<M> -F description=@desc.md`).
  4. Delete the draft.
- **Local:** the approved files are already in place (inline fallback: write them now).

**[Phase 6: Handoff-Brief Cleanup]**
If a handoff brief seeded this run, delete it now — `grimoire-construct` cleans it up on success (`§ Construct`). No brief → nothing to delete; do not warn.

**[Phase 7: Closing]**
Tell the user the construct number `<m>` and the two ways forward — never run either automatically:
- `/grimoire-spec <m>` — expand the next pending reference into a page, one interview at a time;
- `/grimoire-run <m>` — interview every pending reference, then plan, execute, and review all pages autonomously (`§ Run`).

If `PROJECT.md` was missing, remind the user about `grimoire-init`.

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language`; milestone, issue, and file content stays English.
- **Single source of truth.** All construct rules live in `§ Construct` — this body references them and never restates them.
