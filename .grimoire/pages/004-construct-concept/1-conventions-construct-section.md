---
depends-on: []
touches:
  - GRIMOIRE-CONVENTIONS.md
---

# Step 1 — Add `§ Construct` to GRIMOIRE-CONVENTIONS.md (single source of truth)

This is the foundation step. The new `§ Construct` and the amendments below become the load-bearing rules that steps 2, 3, and 4 reference. **Steps 2–4 depend on this step.** Do not restate these rules inside any SKILL.md — they reference this file.

> **TDD note:** Per `§ TDD`, the Red/Green/Refactor loop applies to *code*. This page is markdown-only (no source code, no tests — see `.grimoire/PROJECT.md` → Tech Stack). There is nothing to test; the verification is editorial consistency. Follow `§ Commits` (atomic, Conventional Commits in English).

## Required reading before editing

- `GRIMOIRE-CONVENTIONS.md` in full (you are amending six of its sections).
- `.grimoire/pages/004-construct-concept/SPEC.md` (the contract this step implements).
- `.grimoire/PROJECT.md` for project conventions.

## Locked decisions (from the planning clarity check — adopt verbatim)

1. **Handoff brief lifecycle:** the brief at `.grimoire/bag/drafts/construct-brief-<epoch>.md` is **never auto-deleted by `grimoire-spec`**; `grimoire-construct` deletes it after successfully creating the construct.
2. **Reference status vocabulary:** **binary only** — `[pending]` / `[specced]`. No third "page finished" state at the construct level (that would force the construct to observe page completion and break self-containment).
3. **Consumption order:** **strictly the next `[pending]` reference in execution order** in v1. No out-of-order / user-pick (deferred to a future page).
4. **Reference file naming:** `references/N-<short-name>.md`, mirroring step-file numbering.

## What to write

### A. New `§ Construct` section

Add a new top-level section `## § Construct` to `GRIMOIRE-CONVENTIONS.md` (place it logically — after `§ Historic` and before `§ IDE-aware review` is a reasonable home, since it is a new artifact family). It is the **single source of truth** for constructs. It MUST cover:

- **Definition.** A **construct** is a larger-than-a-page objective decomposed into an *ordered, flat list of reference-seeds*. Each reference is later expanded — through the normal full `grimoire-spec` interview — into one real **page**. The construct is the roadmap-of-record; the pages it spawns are the actual work. Constructs are **flat and self-contained**: no nested constructs, no sub-references, no construct-of-constructs.

- **Folder layout.**
  - Path: `.grimoire/constructs/NNN-<name>/`.
  - `NNN` is an **independent incremental counter** scanned from `.grimoire/constructs/` — it does **not** share or collide with the `pages/` counter.
  - Contents: `CONSTRUCT.md` at the root, plus a `references/` folder holding ordered detail files `references/N-<short-name>.md` (`1-...md`, `2-...md`, …) in execution order.

- **`CONSTRUCT.md` format.** Specify:
  - A header/intro describing the larger objective (purpose, the arc, any research findings).
  - An **ordered reference checklist**, one entry per reference, each carrying:
    - a status token — `[pending]` or `[specced]` (binary; no third state),
    - a short one-line description,
    - the path to its `references/N-<short-name>.md` detail file,
    - a **page backlink** column/field that is empty while `[pending]` and is filled with the spawned page's `NNN` once `[specced]`.
  - Give a concrete illustrative entry format, e.g.:
    `N. [pending] <short description> → references/N-<short-name>.md`
    and once specced:
    `N. [specced] <short description> → references/N-<short-name>.md (page 007)`

- **Writer contract (who may touch construct files).**
  - **`grimoire-construct`** is the **only** skill that creates and authors construct files (`CONSTRUCT.md` and the `references/` detail files). It is also the only skill that may rewrite construct content.
  - **`grimoire-spec`** may make exactly **one kind of edit**: flipping a single reference's status from `[pending]` to `[specced]` **in place** and recording that reference's page backlink. This is analogous to the in-place `HISTORIC.md` status flips done by `grimoire-plan`/`grimoire-execute` — a surgical status update, never authoring. It performs no other construct edits.
  - **All other skills** never touch construct files.

- **Consumption rules (used by `grimoire-spec` consumption mode).**
  - Consumption is **strictly the next `[pending]` reference in execution order** (lowest-numbered `[pending]`). No out-of-order or user-pick in v1.
  - **Not-found error:** the referenced construct `NNN` does not exist under `.grimoire/constructs/` → hard error, no page created (the exact operator-facing message and the pause-point live in `§ Pause-point pattern`).
  - **All-specced / finished error:** every reference is already `[specced]` → hard error, no page created.
  - On a successful consumption: the next `[pending]` reference seeds the **full** `grimoire-spec` interview; a **normal page** is produced through the existing Spec phases (page folder, `SPEC.md`, the two spec commits, and a `HISTORIC.md` entry **that names the parent construct**); then that reference is flipped to `[specced]` with the new page's `NNN` backlink, committed atomically (commit message defined in `§ Commits`).
  - **No size re-evaluation at consumption time** — references are authored page-sized by `grimoire-construct`; `grimoire-spec` does not re-run the size gatekeeper when consuming a reference.

- **Self-containment.** A construct **never** gets a `HISTORIC.md` entry. Only the real pages it spawns appear in `HISTORIC.md`, and each such page's entry/Spec notes its parent construct. Construct progress is readable **solely** from `CONSTRUCT.md`.

- **Size-evaluation trigger & handoff-brief contract.** When `grimoire-spec` (new-page mode) judges a free-text request **too large for a single page**, it recommends creating a construct. On user approval it writes a **handoff brief** — the best possible prompt to feed `grimoire-construct` — to `.grimoire/bag/drafts/construct-brief-<epoch>.md` (epoch = Unix seconds at write time) and **STOPS without creating a page**, instructing the user to start a fresh, clean-context session and run `/grimoire-construct` with that brief. The brief **persists** (it is consumed by a different, clean-context session); `grimoire-construct` deletes it after successfully creating the construct. On decline, `grimoire-spec` proceeds as a normal large page.

### B. Amend `§ .grimoire/ layout`

- Document `.grimoire/constructs/` alongside `.grimoire/pages/`.
- Describe the construct folder's internal structure (`NNN-<name>/CONSTRUCT.md` + `references/N-<short-name>.md`).
- State that `constructs/` `NNN` is an independent counter from `pages/`.
- Cross-reference `§ Construct` for the full rules (do not duplicate them here — a pointer + the layout facts only).

### C. Amend `§ Commits`

Add two construct-related commit conventions:
- **Construct creation** (by `grimoire-construct`): `docs(grimoire): construct <name>` covering the new `CONSTRUCT.md` + `references/` files.
- **Reference-status flip** (by `grimoire-spec` on consumption): `chore: mark reference N specced in construct <name>` covering only the in-place `CONSTRUCT.md` status/backlink update. This is a **separate, atomic commit** from the page's own spec commits.

### D. Amend `§ Pause-point pattern`

Add:
- **`grimoire-spec` — size-evaluation pause:** after codebase analysis in new-page mode, if the request is judged too large for one page, recommend a construct and PAUSE for the user's decision (approve → write handoff brief + STOP; decline → proceed as a normal large page).
- **`grimoire-spec` — construct-consumption hard-stops:** when invoked in consumption mode (bare-number input):
  - Construct `NNN` not found → a clear hard-stop error, no page created. Provide the literal operator-facing message in Portuguese-BR consistent with existing hard-stop style (e.g. `❌ Construct NNN não existe. Rode /grimoire-construct primeiro.`).
  - All references already `[specced]` (construct finished) → a clear hard-stop error, no page created (e.g. `❌ Construct NNN já foi totalmente especificado.`).
- **`grimoire-construct` — clarifying questions:** after research, interview the user about facts that cannot be inferred, with pause-points.
- **`grimoire-construct` — draft review:** present the proposed `CONSTRUCT.md` + references for review per `§ IDE-aware review` and PAUSE before finalizing.

### E. Amend `§ Project context`

In the dual-writer / "all other skills" note, add **`grimoire-construct`** to the explicit list of skills that **never write `PROJECT.md`** (alongside `grimoire-spec`, `grimoire-plan`, `grimoire-execute`, `grimoire-quick`, `grimoire-know`, `grimoire-update`, `grimoire-deps`).

### F. Amend `§ Sub-agent spawning`

Add a bullet: **`grimoire-construct`** keeps the orchestrator lucid by running its research in sub-agent(s); the orchestrator interviews, resolves `NNN`, and writes the construct files. (Mirror the phrasing style of the existing bullets.)

## Acceptance for this step

- `GRIMOIRE-CONVENTIONS.md` has a new `## § Construct` containing all bullets in section A above.
- `§ .grimoire/ layout`, `§ Commits`, `§ Pause-point pattern`, `§ Project context`, and `§ Sub-agent spawning` are amended exactly as in B–F.
- No construct rules are restated outside `§ Construct` except the layout facts in `§ .grimoire/ layout` and the commit-message strings in `§ Commits` (which are the natural homes for those specifics).
- The locked decisions (handoff-brief lifecycle, binary status, strictly-next-in-order, `references/N-<short-name>.md`) are reflected accurately.

## Commit

One commit for this step: `docs(grimoire): add § Construct convention`.
