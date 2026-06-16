---
name: grimoire-spec
description: Specify a page with Grimoire — gathers context, writes SPEC.md, and registers the page in HISTORIC.md.
argument-hint: Page request / what you want to build
---

**[Required Reading]**
1. Read `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`. Its rules (§ Commits, § .grimoire/ layout, § Project context, § Historic, § Construct, § IDE-aware review, § User-facing language, § Pause-point pattern) are load-bearing for this skill. **Note:** this skill is the writer for `HISTORIC.md` (bootstrap + append + rotate); `grimoire-plan` and `grimoire-execute` only update status in place. On construct files this skill makes **only** the single in-place `[pending]` → `[specced]` reference flip defined in `§ Construct` — it never authors or rewrites construct content. `§ TDD` does not apply here — this skill produces a specification, not code.
2. If `.grimoire/PROJECT.md` exists in the project root, read it for project context. If it does not exist, proceed without it and suggest the user run `grimoire-init` once this task is complete.
3. If `.grimoire/HISTORIC.md` exists, read it for recent-page context. If older context seems relevant, browse `.grimoire/bag/historic/` (newest suffix first). Missing → proceed without it; this skill will bootstrap it in Phase 6.

**[Objective]**
Turn a request into a clear, agreed-upon `SPEC.md` for a page, and register that page in `HISTORIC.md` with status `[spec]`. This is the **first step** of the long-form Spec → Plan → Execute pipeline. `grimoire-plan` will refuse to run on a page that does not have a `SPEC.md` and a matching `[spec]` entry, so this skill is the only legitimate way to open a new page.

This skill has **two modes**, chosen by Phase 0 from the input shape:
- **New-page mode** (free-text input) — the long-standing flow: analyze, interview, write `SPEC.md`, register in `HISTORIC.md`. It now also carries a size-evaluation pause that can route a too-large request to a construct.
- **Construct-consumption mode** (bare-number input) — expand the next `[pending]` reference of an existing construct into a normal page, then flip that reference to `[specced]` in `CONSTRUCT.md`. See `§ Construct`.

User's request:

$ARGUMENTS

**[Phase 0: Input-Mode Detection]**
Inspect the input (`$ARGUMENTS` / `$1`) and branch **before any analysis**:
- **Only digits** (one or more digits with optional leading zeros, e.g. `42` or `042` — nothing else, no surrounding words) → **Construct-consumption mode**. Skip Phases 1–7 and go straight to **[Phase C: Construct Consumption]** below.
- **Anything else** (free text) → **New-page mode**. Proceed to Phase 1 below.

The two paths are mutually exclusive; pick exactly one. The rest of this section (Phases 1–7) is the new-page path.

**[Phase 1: Codebase Analysis]**
- Analyze the relevant slice of the codebase for the user's request. Read only what is needed to form an informed opinion (existing modules, neighboring patterns, schemas, public APIs, tests in the same area).
- Identify what already exists and could be reused. Surface patterns the new page should follow.
- Collect candidate facts and constraints. Anything you cannot infer goes into Phase 2 as a question. **Do not invent facts.**

**[Phase 1.5: Size Evaluation]**
After the codebase/request analysis and **before** committing to write a page's `SPEC.md`, judge whether the request fits a single page. Apply the size-evaluation pause per `§ Pause-point pattern` (grimoire-spec: size-evaluation pause):
- If the request fits one page (the common case), continue to Phase 2 with no pause.
- If the request is **too large for a single page**, recommend creating a **construct** and PAUSE for the user's decision. Reference `§ Construct` (size-evaluation trigger & handoff-brief contract) — do not restate its rules here.
  - **On approval:** write the **handoff brief** — the best possible prompt to feed `grimoire-construct`, capturing the objective, the arc you envision, and the facts/constraints surfaced in Phase 1 — to `.grimoire/bag/drafts/construct-brief-<epoch>.md`, generating `<epoch>` as `$(date +%s)` at write time and creating `.grimoire/bag/drafts/` if needed. Then **STOP**: tell the user to start a fresh, clean-context session and run `/grimoire-construct` with that brief. **Create no page folder, no `SPEC.md`, no `HISTORIC.md` entry, and make no page-state commits.** The brief persists (it is consumed by a different session); do not delete it.
  - **On decline:** proceed exactly as today through Phases 2–7 as a normal (possibly large) page — `grimoire-plan` will split it into step files later.

**[Phase 2: Clarifying Questions]**
Per `§ Pause-point pattern` (grimoire-spec: clarifying questions), ask the user targeted questions. Iterate until consensus on what the page must deliver. Typical topics:
- The underlying pain or goal — what problem the page solves and for whom.
- Concrete acceptance criteria — how the user will know the page is done.
- Scope boundaries — what is in, what is deliberately out.
- Critical architectural decisions the SPEC must lock in (data model, public interface, integration points, failure semantics).
- Non-obvious constraints (perf budgets, compatibility, security, deadlines).
- Open questions that should remain visible in the SPEC for `grimoire-plan` to address later.

Answer the user's questions in turn. Do not write any file until consensus is reached.

**[Phase 3: NNN Resolution & Page Name]**
- List `.grimoire/pages/` (if it exists). Extract the integer `N` from each `NNN-*` subfolder name. Choose `max(N) + 1`, zero-padded to 3 digits (`NNN`). If the folder is empty or does not exist, use `001`.
- Choose `[page-name]` in short, descriptive kebab-case (2–5 words). Avoid generic names (`fix`, `update`) — the name must read meaningfully on its own in `HISTORIC.md`.
- The final folder will be `.grimoire/pages/NNN-[page-name]/`.

**[Phase 4: Draft Review]**
- Compose the proposed `SPEC.md` using this template:

  ```
  # NNN — <Page Title>

  ## Context
  Why this page exists, what triggered it, what outcome is expected.

  ## Goals
  - Bullet list of what the page must achieve.

  ## Non-goals
  - Bullet list of what the page deliberately does **not** address.

  ## Scope
  Files / modules / surfaces touched. Be specific with paths when known.

  ## Acceptance criteria
  - Observable, testable criteria. The page is done when all of these hold.

  ## Constraints
  - Perf budgets, compatibility, security, deadlines, conventions to honor.

  ## Open questions
  - Anything still ambiguous that `grimoire-plan` should resolve. Empty if none.

  ## References
  - Links / paths to existing code, ADRs, prior pages, external docs.
  ```

- Present the proposed content for review per `§ IDE-aware review`:
  - **IDE detected:** create `.grimoire/pages/NNN-[page-name]/` if it does not exist, then write the draft to `.grimoire/pages/NNN-[page-name]/SPEC.md` so the IDE renders it. Tell the user in one short line that the draft is open in the editor. Do **not** touch `HISTORIC.md` yet — that still belongs to Phase 6.
  - **Terminal-only fallback:** output the proposed content inline in the chat.
- Pause per `§ Pause-point pattern` (grimoire-spec: draft review): wait for the user's confirmation or edits. Do not advance to Phase 5 until approved. If the user abandons the draft, delete the file and the folder (IDE mode only).

**[Phase 5: Finalize SPEC.md]**
- **IDE mode:** the approved file is already at `.grimoire/pages/NNN-[page-name]/SPEC.md`. No additional write is needed.
- **Inline fallback:** create `.grimoire/pages/NNN-[page-name]/` if it does not exist, then write the approved content to `.grimoire/pages/NNN-[page-name]/SPEC.md`.
- Commit per `§ Commits`: `docs(grimoire): spec page <name>`. This commit covers only the new `SPEC.md` (and the folder it lives in).

**[Phase 6: HISTORIC.md Maintenance]**
Run this phase only after `SPEC.md` is committed. Follow `§ Historic` strictly. **You are the only skill that touches `HISTORIC.md` beyond an in-place status flip.**

- **If `.grimoire/HISTORIC.md` does not exist:** create it with the new page as entry `1.`:
  ```
  # HISTORIC

  1. **NNN-[page-name]** [spec] — <1–2 sentence description of what the page delivers>
  ```
- **If the entry for this page already exists** (re-spec): ensure its status is `[spec]` and refresh the description in place. Do not duplicate, do not move it.
- **If the entry does not exist and `HISTORIC.md` has fewer than 5 entries:** prepend the new entry as item `1.` with status `[spec]`, renumbering the previous ones.
- **If the entry does not exist and `HISTORIC.md` already has 5 entries:** rotate first per `§ Historic` — create `.grimoire/bag/historic/` if needed; determine the next suffix `N` as `max(existing HISTORIC-N.md suffix) + 1` (or `1` if empty); move `HISTORIC.md` to `.grimoire/bag/historic/HISTORIC-N.md`; then write a fresh `HISTORIC.md` containing only the new entry as item `1.` with status `[spec]`.

**[Phase 7: Historic Commit]**
- Commit the HISTORIC change per `§ Commits` as a separate commit: `chore: register page <name> in historic`.
- If a rotation also happened, the same commit covers both the rotated `HISTORIC-N.md` file and the fresh `HISTORIC.md`.
- **Construct-consumption note:** when this run was reached from Phase C, the entry's description **must name the parent construct** (e.g. append `(construct NNN)`) per `§ Construct` self-containment, so the spawned page is traceable back to its construct.
- End the run by telling the user the next step: `/grimoire-plan NNN` (using the numeric page identifier just assigned).

**[Phase C: Construct Consumption]**
Reached **only** from Phase 0 when the input was bare digits `NNN`. Produces a normal page from the next `[pending]` reference of an existing construct. Reference `§ Construct` (consumption rules + writer contract) and `§ Pause-point pattern` (construct-consumption hard-stops) — do not restate their rules.

**C1 — Resolve the construct.** Glob `.grimoire/constructs/NNN-*/` (matching the input number, with the construct's independent counter).
- No match → hard-stop per `§ Pause-point pattern`: `❌ Construct NNN does not exist. Run /grimoire-construct first.` Create no page.

**C2 — Find the next reference.** Read the construct's `CONSTRUCT.md` and pick the **next `[pending]` reference in execution order** (lowest-numbered `[pending]`).
- If **every reference is already `[specced]`** → hard-stop per `§ Pause-point pattern`: `❌ Construct NNN has already been fully specified.` Create no page.

**C3 — Seed and run the full interview.** Read the chosen reference's detail file `references/N-<short-name>.md` and use its content to seed a **full** spec interview. Run the normal new-page flow — **Phases 1 → 2 → 3 → 4 → 5 → 6 → 7** — exactly as for a free-text page, with two differences:
- **Do not run Phase 1.5 (size evaluation).** References are authored page-sized by `grimoire-construct`; the size gatekeeper is never re-run on consumption (per `§ Construct`).
- In **Phase 6**, the `HISTORIC.md` entry description names the parent construct `(construct NNN)` (see the construct-consumption note in Phase 6).

This yields a normal page: page folder, `SPEC.md` (with IDE-aware draft review), and the two normal spec commits (`docs(grimoire): spec page <name>` + `chore: register page <name> in historic`). `grimoire-spec` still owns `HISTORIC.md` for this page exactly as for any other.

**C4 — Flip the reference status (in place).** After the page is registered, edit `CONSTRUCT.md` **in place** per the `§ Construct` writer contract: change that reference from `[pending]` to `[specced]` and record the spawned page's `NNN` as its backlink. This is the **only** edit `grimoire-spec` ever makes to construct files — never author or rewrite construct content. Commit it **atomically and separately** per `§ Commits`: `chore: mark reference N specced in construct <name>` (covering only the `CONSTRUCT.md` change).

**C5 — Closing.** Tell the user the next steps: `/grimoire-plan <page-NNN>` to plan the new page, and that re-running `/grimoire-spec NNN` consumes the construct's next `[pending]` reference.
