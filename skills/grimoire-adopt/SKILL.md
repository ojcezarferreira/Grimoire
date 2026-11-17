---
name: grimoire-adopt
description: Adopt an existing GitHub issue or milestone into Grimoire — analyze, clarify and improve it with you, then rewrite it as a page (issue) or a construct (milestone + reference issues). GitHub backend only.
argument-hint: Issue number (42 / #42) or milestone (milestone 3 / m3 / title)
---

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Backends` (identifiers, the GitHub state model — markers, labels, label-ensure rule, transitions — and the `gh` cheat sheet), `§ Construct` (storage per backend, reference status, `depends-on` between references, and the `grimoire-adopt` clause of the writer contract), `§ Sub-agent spawning` (the `research` role), `§ Harness adaptation`, `§ Configuration`, `§ Documentation`, `§ Skill composition`, `§ Commits` (this skill commits **nothing**), `§ IDE-aware review`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ TDD`, `§ Code comments`, `§ Parallel execution`, `§ Review loop`, `§ Run` — this skill writes GitHub objects only, never code; `§ .grimoire/ layout` only for the throwaway draft under `.grimoire/bag/drafts/`.
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and any other linked doc the object touches. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` at the end (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice).
4. Detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). `[github].mode = "on"` without auth → `❌ GitHub backend required but gh is not authenticated.` and STOP.

**[Objective]**
Bring a pre-existing GitHub issue or milestone under Grimoire management: analyze it against the codebase, sharpen it with the developer, and rewrite it — an **issue** becomes a page in `spec` status; a **milestone** becomes a construct whose issues are `grimoire:reference` seeds (`§ Construct`, writer contract).

Target:

$ARGUMENTS

**[Hard constraints]**
- **GitHub backend only.** Never specify a reference into a page (that is `grimoire-spec`); never create a local page or construct folder; never write `docs/`, `PROJECT.md`, or `config.toml` (`§ Documentation`); **never commit** (`§ Commits`).
- **Nothing is lost.** Every original issue text survives under `<details><summary>Original issue text</summary>…</details>`; markers are written per `§ Backends` and kept verbatim by every later writer.

**[Phase 0: Backend Gate, Input, Target Hard-Stops]**
Per `§ Pause-point pattern` (`grimoire-adopt`). STOP on the first failure with the literal message; nothing is changed.
1. **Backend gate — first.** Local backend → `❌ grimoire-adopt requires the GitHub backend.`
2. **Parse the input** per `§ Backends` (identifiers): `42` / `#42` → an **issue**; `milestone 3` / `m3` → a **milestone** by number; any other text → a milestone by **exact title** (`gh api 'repos/{owner}/{repo}/milestones?state=all'`).
3. **Target hard-stops.** Issue: `gh issue view <n> --json number,title,body,labels,milestone,state,comments`. Milestone: `gh api repos/{owner}/{repo}/milestones/<n>`.
   - Not found → `❌ Issue N does not exist.` / `❌ Milestone N does not exist.`
   - Closed → `❌ Issue N is closed.` / `❌ Milestone N is closed.`
   - Already managed — marker or Grimoire label present (`§ Backends`) → `❌ Issue N is already managed by Grimoire (grimoire:spec).` with the parenthesis naming the status label found / `❌ Milestone N is already managed by Grimoire.`

**[Phase 1: Read the Object]**
- **Issue:** title, body, labels, milestone, and every comment (already loaded in Phase 0).
- **Milestone:** title and description, then its issues — `gh issue list -m <n|title> -s all --json number,title,labels,state,body --limit 100` — and each issue's comments (`gh issue view <n> --json number,title,body,labels,milestone,state,comments`). Note every issue that is closed or already carries a Grimoire marker or label: it is raised at the Phase 3 pause, never silently folded in.

**[Phase 2: Research]**
Spawn a `research` sub-agent (`§ Sub-agent spawning`, `§ Harness adaptation` — `Explore` on Claude Code, instructed read-only on Codex) with the object's text and comments and the docs pointers of `[Required Reading]` step 2. It analyzes the codebase against the request and returns:
- **issue:** the relevant code slice, reuse candidates, patterns to follow, constraints, a size signal, and draft content for the SPEC sections of `§ Backends` (page);
- **milestone:** a mapping of the existing issues to page-sized references, the proposed execution order and `depends-on` (`§ Construct`), the **gaps** — references the objective needs that no issue covers — and issues too large or too small for one page;
- always an explicit list of uncertainties. No invented facts — uncertainties become Phase 3 questions.

**[Phase 3: Clarifications & Improvements]**
Per `§ Pause-point pattern` (`grimoire-adopt`: clarifications and improvements). Interview the developer: sharpen scope (in / deliberately out) and concrete acceptance criteria; for a milestone, confirm the order, the `depends-on`, the gaps to create, and the fate of each issue flagged in Phase 1. Flag **"too large → milestone"** when an issue spans more than one page and let the developer decide at this pause. Answer their questions in turn; PAUSE and iterate to consensus before drafting.

**[Phase 4: Draft Review]**
Compose the rewrite — content in English (`§ User-facing language`) — in the throwaway draft `.grimoire/bag/drafts/adopt-<epoch>.md` (`<epoch>` = `$(date +%s)`; create the folder if needed) per `§ IDE-aware review`:
- **Issue →** the future body: line 1 the page marker `<!-- grimoire:page v=1 -->` (`§ Backends`), then the SPEC sections (Context, Goals, Non-goals, Scope, Acceptance criteria, Constraints, Open questions, References), then `<details><summary>Original issue text</summary>…</details>` holding the original body verbatim.
- **Milestone →** the future description: line 1 `<!-- grimoire:construct v=1 -->`, the intro / arc / research findings, and `## References` — the numbered list in execution order with the optional `(after #…)` suffix (`§ Backends`); plus, per entry, the reference body: header `<!-- grimoire:page v=1 construct=#M order=N depends-on=… -->`, the seed, and — for an existing issue — its original body under `<details><summary>Original issue text</summary>…</details>`. Gaps are marked as new issues.

Terminal-only → inline. PAUSE per `§ Pause-point pattern` (`grimoire-adopt`: draft review). Edits → revise in place and re-pause. Abandonment → delete the draft; nothing on GitHub has changed.

**[Phase 5: Write]** — no commit (`§ Commits`)
Ensure every label about to be applied (label-ensure rule, `§ Backends`), then per the `gh` cheat sheet:
- **Issue:** `gh issue edit <n> -F body.md --add-label grimoire:spec`.
- **Milestone**, in list order: an existing issue → `gh issue edit <n> -F body.md --add-label grimoire:reference`; a gap → `gh issue create -t "<title>" -F body.md -l grimoire:reference -m "<milestone title>"`, its number filled into the list and into later `depends-on` fields. Then write the description — `gh api -X PATCH repos/{owner}/{repo}/milestones/<n> -F description=@desc.md`.
- Delete the draft (`§ IDE-aware review`). Never specify a reference.

**[Phase 6: Closing]**
Tell the user what was adopted and the next step — never run it automatically:
- **page `<n>`:** `/grimoire-plan <n>` (optional, to steer the plan) or `/grimoire-execute <n>` (auto-plans, executes, and reviews);
- **construct `<m>`:** `/grimoire-spec <m>` (expand the next reference into a page) or `/grimoire-run <m>` (interview every reference, then run all pages — `§ Run`).

If `PROJECT.md` was missing, remind the user about `grimoire-init`.

**[Style / discipline guardrails]**
- Operator-facing prose follows `§ User-facing language`; the `❌` lines keep their glyph and literal tokens. Issue and milestone content stays English.
- **Single source of truth.** Markers, labels, and construct rules live in `§ Backends` and `§ Construct` — this body references them and never restates them.
