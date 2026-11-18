---
name: grimoire-spec
description: Specify a page with Grimoire — analyzes the codebase, interviews you to consensus, and writes the page SPEC as a GitHub issue (label grimoire:spec) or as a local .grimoire/pages/NNN-<slug>/SPEC.md. Given a construct number or native ac:<UUID>, it expands the construct's next pending reference into a page; a request too large for one page is routed to a construct.
argument-hint: Page request / what you want to build — or a construct number to consume its next reference
---

**Managed catalog bootstrap (agentes.chat, Grimoire 0.14.1).** Before Required Reading, read `AGENTES-CHAT.md` from the matching distribution, or from `https://raw.githubusercontent.com/ojcezarferreira/Grimoire/v0.14.1/AGENTES-CHAT.md` through the connector/public fetch. Follow its bootstrap when `${GRIMOIRE_HOME}` is unresolved: catalog import does not run the installer. On agentes.chat its transport, permissions, native construct dispatch and managed-update rules refine the CLI examples below. Outside agentes.chat, use the normal installed-home flow.

**[Required Reading]** — in the order of `§ Documentation`:
1. Read `${GRIMOIRE_HOME}/GRIMOIRE-CONVENTIONS.md`. Load-bearing for this skill: `§ Backends` (identifiers, page marker, labels, `gh` cheat sheet), `§ .grimoire/ layout` (local page folder + status frontmatter), `§ Construct` (consumption, writer contract, size-evaluation trigger & handoff brief), `§ Sub-agent spawning` (the `research` role), `§ Harness adaptation`, `§ Configuration`, `§ Documentation`, `§ Skill composition`, `§ Commits` (this skill commits **nothing**), `§ IDE-aware review`, `§ User-facing language`, `§ Pause-point pattern`. **Not applicable:** `§ TDD`, `§ Code comments`, `§ Parallel execution`, `§ Review loop`, `§ Run` — this skill produces a specification, not code. On construct objects it makes **only** the consumption edit of the `§ Construct` writer contract — never authoring.
2. Read `.grimoire/PROJECT.md` (the index), then `docs/conventions.md` and any other linked doc the request touches. Missing `PROJECT.md` → proceed without it and suggest `grimoire-init` at the end (non-blocking, `§ Documentation`).
3. Read `.grimoire/config.toml` and `${GRIMOIRE_HOME}/config.toml` per `§ Configuration` (including the one-line `session` notice).
4. Detect the backend per `§ Backends` and announce it (`🔗 Backend: GitHub (owner/repo)` / `📁 Backend: local`). Missing required GitHub access → stop per `§ Backends`; on agentes.chat a verified connector qualifies without `gh`. Resolve construct storage independently when this skill touches constructs.

**[Objective]**
Turn a request into a clear, agreed-upon page specification and persist it as a page in `spec` status — a GitHub issue labelled `grimoire:spec`, or a local `SPEC.md` with `status: spec` frontmatter. This is the **entry point** of the long-form Spec → Plan → Execute pipeline and the only skill that opens a page from free text.

Two modes, chosen by Phase 0:
- **New-page mode** (free text) — analyze, size-evaluate, interview, persist.
- **Construct-consumption mode** (bare number) — expand the construct's first pending reference into a normal page (`§ Construct`).

User's request:

$ARGUMENTS

**[Phase 0: Input-Mode Detection]**
Inspect the input (`$ARGUMENTS` / `$1`) **before any analysis**:
- **`ac:<UUID>`** → native construct-consumption mode per `AGENTES-CHAT.md`, preserving the explicit storage choice and page backend. Resolve the document and first pending seed, run the full interview below (skip Phase 1.5), then use native consumption persistence instead of the existing GitHub reference-issue rewrite.
- **Only digits** (optional leading zeros, nothing else) → **Construct-consumption mode** → go to **[Phase C]**. The number is a construct identifier per `§ Backends`: a milestone number on GitHub, `NNN` locally.
- **Anything else** → **New-page mode** → Phase 1.

**[Phase 1: Codebase Analysis]**
Spawn a `research` sub-agent (`§ Sub-agent spawning`, `§ Harness adaptation`) with the request (or the reference seed) and the docs pointers of `[Required Reading]` step 2. It returns: the relevant slice of the codebase, what can be reused, the patterns the page should follow, facts and constraints, and an explicit list of uncertainties. "Recent context" (`§ .grimoire/ layout`) may be consulted when it helps. **Do not invent facts** — uncertainties become Phase 2 questions.

**[Phase 1.5: Size Evaluation]** — new-page mode only
Per `§ Pause-point pattern` (size-evaluation pause) and `§ Construct` (size-evaluation trigger & handoff-brief contract):
- Fits one page (the common case) → Phase 2, no pause.
- **Too large for one page** → recommend a construct and PAUSE.
  - **On approval:** write the handoff brief — the best possible prompt for `grimoire-construct`: objective, envisioned arc, facts and constraints from Phase 1 — to `.grimoire/bag/drafts/construct-brief-<epoch>.md` (`<epoch>` = `$(date +%s)`; create the folder if needed). Then **STOP**: tell the user to start a fresh, clean-context session and run `/grimoire-construct` with that brief. Create no issue, no page folder, no `SPEC.md`. The brief persists — never delete it here.
  - **On decline:** continue as a normal (possibly large) page — the planner splits it into steps later.

**[Phase 2: Clarifying Questions]**
Per `§ Pause-point pattern` (clarifying questions). Typical topics: the underlying pain or goal; concrete acceptance criteria; scope boundaries (in / deliberately out); critical architectural decisions the SPEC must lock in (data model, public interface, integration points, failure semantics); non-obvious constraints (performance, compatibility, security, deadlines); open questions the planner should see. Answer the user's questions in turn. Write nothing until consensus.

**[Phase 3: Page Identity]**
Per `§ Backends` (identifiers):
- **GitHub:** a concise English title, meaningful on its own — the page `<slug>` is derived from it later (`§ Backends`, page slug). New page → the page number is the issue number GitHub assigns at creation (Phase 5) — nothing to compute. Consumption → the page number is the reference issue's number, and the issue is renamed to this title in Phase 5.
- **Local:** list `.grimoire/pages/`, take `max(NNN) + 1` zero-padded to 3 digits (`001` when empty or absent), plus the `<slug>`. Folder: `.grimoire/pages/NNN-<slug>/`.

**[Phase 4: Draft Review]**
- Compose the SPEC with this template (content in English, `§ User-facing language`):

  ```
  # <Page Title>

  ## Context
  Why this page exists, what triggered it, what outcome is expected.

  ## Goals
  - What the page must achieve.

  ## Non-goals
  - What the page deliberately does not address.

  ## Scope
  Files / modules / surfaces touched — specific paths when known.

  ## Acceptance criteria
  - Observable, testable criteria. The page is done when all of these hold.

  ## Constraints
  - Performance, compatibility, security, deadlines, conventions to honor.

  ## Open questions
  - Anything still ambiguous for the planner. Empty if none.

  ## References
  - Paths to existing code, prior pages, external docs.
  ```

- Present it per `§ IDE-aware review`: **GitHub** → the throwaway draft `.grimoire/bag/drafts/spec-<epoch>.md`, holding the future issue body (page marker on line 1 — new page: `<!-- grimoire:page v=1 -->`; consumption: the reference's marker line kept verbatim); **local** → the final destination `.grimoire/pages/NNN-<slug>/SPEC.md`, opening with the status frontmatter of `§ .grimoire/ layout` (`status: spec`, plus `construct` / `depends-on` when consuming). Terminal-only → inline.
- PAUSE per `§ Pause-point pattern` (draft review) until approved. Edits → revise in place and re-pause. Abandonment → delete what the draft created (`§ IDE-aware review`).

**[Phase 5: Persist]** — no commit (`§ Commits`)
- **Native construct consumption:** persist a new page and reconcile its typed backlink per `AGENTES-CHAT.md`; never use the GitHub consumption rewrite or local construct-file flip below. The page backend still determines the page format.
- **GitHub:** first ensure the `grimoire:spec` label (label-ensure rule, `§ Backends`).
  - **New page:** `gh issue create -t "<title>" -F <draft> -l grimoire:spec`. Report the issue number GitHub assigned — it is the page number.
  - **Consumption:** `gh issue edit <reference#> -t "<title>" -F <draft> --remove-label grimoire:reference --add-label grimoire:spec` — the reference issue takes the interview's title (the page slug derives from that final title), the body becomes the SPEC with its marker line (`construct=#M order=N depends-on=…`) kept verbatim; the milestone is already set.
  - Then delete the draft.
- **Local, new page:** the approved `SPEC.md` is already in place (inline fallback: write it now).
- **Local, consumption:** the `SPEC.md` names its construct and carries the reference's `depends-on` translated to page numbers; then flip the reference to `specced` with its `page:` backlink, rewrite the derived checklist token in `CONSTRUCT.md`, and set `CONSTRUCT.md` `status: done` when it was the last pending reference — one write, exactly per `§ Construct` (writer contract + consumption).

**[Phase 6: Closing]**
Tell the user the next step for page `<n>`:
- `/grimoire-plan <n>` — optional, to steer the plan interactively;
- `/grimoire-execute <n>` — plans automatically when no plan exists, then executes and reviews.

After a consumption, also: `/grimoire-spec <m>` consumes the construct's next pending reference, and `/grimoire-run <m>` runs the whole construct (`§ Run`). Never run them automatically. If `PROJECT.md` was missing, remind the user about `grimoire-init`.

**[Phase C: Construct Consumption]**
Reached only from Phase 0. Rules live in `§ Construct` (consumption) and `§ Pause-point pattern` (construct-consumption hard-stops) — do not restate them.

**C1 — Resolve the construct.** Native `ac:<UUID>` uses `AGENTES-CHAT.md` throughout C1–C3 and persistence; otherwise GitHub: the milestone with that number (`gh api repos/{owner}/{repo}/milestones/<n>`). Local: `.grimoire/constructs/NNN-*/`.
- Not found → `❌ Construct N does not exist. Run /grimoire-construct first.` STOP; no page created.

**C2 — Pick the reference.** Strictly the **first pending reference in list order**: GitHub — the first `## References` entry whose issue still carries `grimoire:reference`; local — the lowest-numbered reference with `status: pending`.
- None pending → `❌ Construct N has already been fully specified.` STOP; no page created.

**C3 — Seed the full interview.** Read the reference seed (the issue body / `references/N-<short-name>.md`) and run Phases 1 → 2 → 3 → 4 → 5 → 6 exactly as for a free-text page, **skipping Phase 1.5** — references are authored page-sized (`§ Construct`). The resulting page names its parent construct and inherits the reference's `depends-on`.
