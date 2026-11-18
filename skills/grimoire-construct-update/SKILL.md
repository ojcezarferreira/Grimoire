---
name: grimoire-construct-update
description: Alter an existing construct in place — add, remove, or reorder pending references, edit a pending reference's seed, rewrite the construct intro, or rename it — on its GitHub milestone and reference issues, in the local .grimoire/constructs/ folder, or through native agentes.chat document and board tools. Specified references form an immutable locked prefix. Never creates a construct or a page; commits nothing.
argument-hint: A construct number or <name>, plus the alteration to make
---

**Managed catalog bootstrap (agentes.chat, Grimoire 0.14.1).** Before Required Reading, read `AGENTES-CHAT.md` from the matching distribution, or from `https://raw.githubusercontent.com/ojcezarferreira/Grimoire/v0.14.1/AGENTES-CHAT.md` through the connector/public fetch. Follow its bootstrap when `${GRIMOIRE_HOME}` is unresolved: catalog import does not run the installer. On agentes.chat its transport, permissions, native construct dispatch and managed-update rules refine the CLI examples below. Outside agentes.chat, use the normal installed-home flow.

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Construct` (the single source of truth — storage per backend, reference status, writer contract, and the **Alteration rules** that govern every in-place change), `§ Backends` (milestone and page markers, labels, `gh` cheat sheet), `§ .grimoire/ layout` (local construct folder + frontmatter), `§ Sub-agent spawning` (the `research` role), `§ Harness adaptation`, `§ Configuration`, `§ Documentation`, `§ Skill composition`, `§ Commits` (this skill commits **nothing**), `§ IDE-aware review`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ TDD`, `§ Code comments`, `§ Parallel execution`, `§ Review loop`, `§ Run` — this skill is orthogonal to the page pipeline; it is the construct analog of `grimoire-note`. **Do not restate any `§ Construct` / Alteration rule in this body — reference it.**
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md`. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` at the end (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice).
4. Detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). Missing required GitHub access → stop per `§ Backends`; on agentes.chat a verified connector qualifies without `gh`. Resolve construct storage independently when this skill touches constructs.

**[Objective]**
Alter an **existing** construct in place per the `§ Construct` Alteration rules — add, remove, or reorder references in the pending tail, refine a pending reference's seed, rewrite the construct intro / objective, or rename the construct — keeping the roadmap-of-record accurate without ever spawning a page or disturbing work already specified.

User's target + requested alteration:

$ARGUMENTS

**[Hard constraints — orthogonal skill]**
- Never create a construct (that is `grimoire-construct`) and never create a page. Never write `docs/`, `PROJECT.md`, or `config.toml` (`§ Documentation`).
- The locked prefix is immutable and the construct stays flat and self-contained — enforce the `§ Construct` Alteration rules; do not restate them.

**[Phase 1: Target Resolution & Precondition Check (HARD STOP)]**
For native construct storage, resolve/read/validate `ac:<UUID>` or the unique exact title per `AGENTES-CHAT.md`; use its locked-prefix, review and alteration protocol throughout Phases 1–6, skipping the milestone/local write branches. Otherwise resolve the target per `§ Backends` (identifiers) and `§ Construct` (resolution): **GitHub** — the milestone by number or exact title (`gh api repos/{owner}/{repo}/milestones/<n>`, or the `?state=all` list for a title); **local** — `.grimoire/constructs/NNN-<name>/` by `NNN` or `<name>`. If it does not exist, STOP — creating or changing nothing, never offering to run `grimoire-construct` — with:

> ❌ Construct N does not exist. Run /grimoire-construct first.

Once resolved, read the construct (GitHub: the milestone description + `gh issue list -m <n|title> -s all --json number,title,labels,state,body --limit 100`; local: `CONSTRUCT.md` + `references/*`) and split it into the **locked prefix** — specified references: label ≠ `grimoire:reference` (GitHub) / `status: specced` (local) — and the **pending tail**. Every later operation is confined to the pending tail or to construct-level metadata.

**[Phase 2: Research (conditional)]**
Only for add / edit operations that need grounding in the codebase or in an external convention: spawn `research` sub-agent(s) (`§ Sub-agent spawning`, `§ Harness adaptation`) with the docs pointers of `[Required Reading]` step 2. They return findings plus an explicit list of uncertainties (Phase 3 questions). Remove, reorder, and rename need no research — skip the phase.

**[Phase 3: Clarifying Questions / Operation Selection]**
Per `§ Pause-point pattern` (`grimoire-construct-update`: clarifying questions / operation selection): fix the **exact operation set** — which references are added, removed, or reordered and where in the pending tail; the new seed text; the new `depends-on`; the new intro; the new name. Surface the research uncertainties. PAUSE and iterate to consensus.

**[Phase 4: Validate Against the Locked Prefix]**
Check every operation against the locked prefix per the `§ Construct` Alteration rules. An edit, removal, or reorder of a specified reference — or an insertion ahead of one — is **refused**, naming the reference and its page (`§ Pause-point pattern`):
- local: `❌ Reference 2 has already been specified (page 007) — it cannot be edited, removed, or reordered.`
- GitHub: `❌ Reference 2 (#123) has already been specified — it cannot be edited, removed, or reordered.`

A refused operation changes nothing. When the set mixes legal pending-tail changes with an illegal one, refuse the illegal part and confirm with the user whether to proceed with the legal remainder.

**[Phase 5: Compose & Draft Review]**
Compose the altered construct per the `§ Construct` Alteration rules (permitted operations, numbering after a structural change) — content in English. Present it per `§ IDE-aware review`:
- **agentes.chat:** compose the full native document/reference diff per the adapter; do not alter remote objects before the existing review checkpoint.
- **GitHub:** the throwaway draft `.grimoire/bag/drafts/construct-<epoch>.md`, holding the operation set, the new milestone description (marker kept verbatim, `## References` list rewritten), and every new or edited seed with its marker line. No renumbering: issue numbers are permanent; only the pending tail's `order=` fields change.
- **Local:** before the first edit, back the folder up to `.grimoire/bag/drafts/construct-update-backup-<epoch>/` (`§ IDE-aware review`, in-place edits of git-ignored files). Then write the altered files at their final destination — `CONSTRUCT.md` (intro / derived checklist) and `references/N-*.md` — with the pending tail **renumbered contiguously** and every `depends-on` rewritten to the new numbers; the specced prefix never moves. A rename is a plain filesystem `mv` of the folder to `NNN-<new>` preserving `NNN`, with internal self-references updated (no git operation — the folder is git-ignored).
- Terminal-only → inline.

PAUSE per `§ Pause-point pattern` (`grimoire-construct-update`: draft review) for approval, edits, or abandonment. Edits → revise and re-pause. Abandonment → restore the construct to its pre-edit state (local: restore the folder from the backup, undoing any rename, then delete the backup; GitHub: nothing was written yet — delete the draft).

**[Phase 6: Persist]** — no commit (`§ Commits`)
- **agentes.chat:** apply the approved native alteration protocol in `AGENTES-CHAT.md`; re-read affected objects and report partial failures without claiming completion.
- **GitHub** — apply each approved operation with the `§ Backends` cheat sheet:
  - **add** → ensure the `grimoire:reference` label, `gh issue create -t "<title>" -F body.md -l grimoire:reference -m "<milestone title>"` with line 1 `<!-- grimoire:page v=1 construct=#M order=<n> depends-on=… -->`, inserted after the last locked entry or at the requested pending position;
  - **remove** → ensure the `grimoire:dropped` label (`§ Backends`, label-ensure rule), then `gh issue edit <n> --remove-milestone --add-label grimoire:dropped && gh issue close <n> -c "Removed from construct <name>"`, drop its entry, and drop it from every remaining `depends-on` header;
  - **reorder** — and after any add or remove — → rewrite the `order=` field of every pending reference whose position changed (`gh issue edit <n> -F body.md`, marker otherwise verbatim);
  - **edit** → rewrite the pending reference's issue body (`gh issue edit <n> -F body.md`, marker verbatim) and its one-line entry;
  - **rename** → `gh api -X PATCH repos/{owner}/{repo}/milestones/<M> -f title="<new name>"`;
  - finally write the new description (intro and/or `## References` list) with `gh api -X PATCH repos/{owner}/{repo}/milestones/<M> -F description=@desc.md`, then delete the draft.
- **Local:** the approved files are already in place (inline fallback: write them now); the checklist tokens are re-derived from the reference frontmatter (`§ Construct`); delete the backup.

**[Phase 7: Closing]**
- Tell the user what changed: the operations applied and the resulting pending-tail order.
- When a pending reference remains, point at `/grimoire-spec <m>` (next reference, one interview) and `/grimoire-run <m>` (the whole construct). Never run them automatically.
- If `PROJECT.md` was missing, remind the user about `grimoire-init`.

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language`; milestone, issue, and file content stays English.
- **Single source of truth.** All construct and alteration rules live in `§ Construct` — this body references them and never restates them.
