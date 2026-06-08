---
depends-on: [1]
touches:
  - skills/grimoire-spec/SKILL.md
---

# Step 3 — Add input-mode detection, size-evaluation, and construct-consumption to `grimoire-spec`

Extend `skills/grimoire-spec/SKILL.md` with three new behaviors, all referencing the rules added to `GRIMOIRE-CONVENTIONS.md` in Step 1. **Do not restate construct rules** — reference `§ Construct`, `§ Commits`, `§ Pause-point pattern` from `${CLAUDE_PLUGIN_ROOT}/GRIMOIRE-CONVENTIONS.md`.

> **Depends on Step 1.** The behaviors here rely on the `§ Construct` writer contract, consumption rules, size-evaluation trigger, and the two new pause-points.

> **TDD note:** markdown-only (no code, no tests). Verification is editorial: existing new-page behavior must remain byte-for-byte intact except for the additions below. Follow `§ Commits`.

## Required reading before editing

- `skills/grimoire-spec/SKILL.md` in full (you are extending it without breaking existing behavior).
- `GRIMOIRE-CONVENTIONS.md` — the new `§ Construct` and amended `§ Pause-point pattern`, `§ Commits`.
- `.grimoire/pages/004-construct-concept/SPEC.md`.

## Locked decisions (adopt verbatim)

- **Bare-number detection is the discriminator.** Input matching **only digits** (with optional leading zeros, e.g. `42` / `042`) → **construct-consumption mode**. Any other input (free text) → **new-page mode** (existing behavior). Detection must be unambiguous.
- Consumption is **strictly the next `[pending]` reference** in execution order — no re-evaluation of its size, no out-of-order pick.
- The handoff brief path is `.grimoire/bag/drafts/construct-brief-<epoch>.md` (epoch = Unix seconds at write time); it **persists** (not auto-deleted by spec).
- `grimoire-spec` may edit construct files **only** by flipping a single reference `[pending]` → `[specced]` in place + recording the page backlink (per `§ Construct` writer contract).

## What to add

### 1. Input-mode detection (new step at the very top of the skill flow)

Add a detection step before the existing analysis phases:
- If `$ARGUMENTS` / the input is **only digits** → go to **Construct-consumption mode** (section 3 below).
- Otherwise → **New-page mode** (existing flow), with the new size-evaluation pause added (section 2 below).

Make this the first branch so the rest of the skill reads as two clear paths.

### 2. Size-evaluation pause-point (new-page mode only)

After the existing codebase/request analysis and **before** committing to writing a page's `SPEC.md`, add the size-evaluation pause per `§ Pause-point pattern`:
- If the request is judged **too large for a single page**, recommend creating a **construct** and PAUSE for the user's decision.
- **On approval:** write the **handoff brief** (the best possible prompt to feed `grimoire-construct`) to `.grimoire/bag/drafts/construct-brief-<epoch>.md` (generate `<epoch>` as `$(date +%s)` at write time; create the folder if needed), then **STOP** — instruct the user to start a fresh, clean-context session and run `/grimoire-construct` with that brief. **No page is created, no `HISTORIC.md` entry, no commits to page state.** (The brief is an uncommitted throwaway-but-persistent draft, consumed by another session.)
- **On decline:** proceed exactly as today as a normal (possibly large) page — `grimoire-plan` will split it into step files later.

Reference `§ Construct` (size-evaluation trigger & handoff-brief contract) rather than restating it.

### 3. Construct-consumption mode (new path, bare-number input)

When input is only a number `NNN`:
1. **Resolve the construct.** Glob `.grimoire/constructs/NNN-*/`. Per `§ Pause-point pattern`:
   - No match → hard-stop with the not-found message (e.g. `❌ Construct NNN não existe. Rode /grimoire-construct primeiro.`), no page created.
2. **Read `CONSTRUCT.md`** and find the **next `[pending]` reference** in execution order (lowest-numbered `[pending]`).
   - If **all references are `[specced]`** → hard-stop with the finished message (e.g. `❌ Construct NNN já foi totalmente especificado.`), no page created.
3. **Seed a FULL spec interview** with that reference's `references/N-<short-name>.md` content. Run the **normal Spec phases** — this is a full interview, not an abbreviated one. Do **not** re-run the size gatekeeper (references are authored page-sized).
4. **Produce a normal page** through the existing flow:
   - create the page folder `.grimoire/pages/<page-NNN>-<name>/`,
   - write `SPEC.md` (IDE-aware draft review as usual),
   - the two normal spec commits (`docs(grimoire): spec page <name>` + `chore: register page <name> in historic`),
   - the `HISTORIC.md` entry **must name the parent construct** (e.g. note `(construct NNN)` or similar in the entry description), per `§ Construct` self-containment + `§ Historic`.
5. **Flip the reference status.** After the page is registered, edit `CONSTRUCT.md` **in place**: change that reference from `[pending]` to `[specced]` and record the spawned page's `NNN` as its backlink. Commit this atomically and separately per `§ Commits`: `chore: mark reference N specced in construct <name>`.
6. **Closing.** Tell the user the next step: `/grimoire-plan <page-NNN>` for the new page, and that re-running `/grimoire-spec NNN` will consume the next reference.

## Hard constraints (preserve / call out)

- Existing **new-page free-text behavior is unchanged** apart from the added size-evaluation pause.
- `grimoire-spec` still **owns `HISTORIC.md`** for the pages it creates (bootstrap/append/rotate per `§ Historic`) — consumption-mode pages are normal pages in that respect.
- `grimoire-spec` touches construct files **only** via the single in-place status flip — never authors or rewrites construct content.
- Never writes `PROJECT.md`.
- Preserve `$ARGUMENTS` / `$1` / `${CLAUDE_PLUGIN_ROOT}` verbatim; preserve the frontmatter contract.

## Acceptance for this step

- `grimoire-spec` detects bare-number input → consumption mode; free-text → new-page mode (unambiguous).
- New-page mode has the size-evaluation pause: too-large → recommend construct → on approval write `.grimoire/bag/drafts/construct-brief-<epoch>.md` and STOP (no page); on decline proceed as normal page.
- Consumption mode: not-found and all-specced hard-stops; otherwise full interview seeded by the next `[pending]` reference → normal page (folder, `SPEC.md`, two commits, HISTORIC entry naming the parent construct) → reference flipped to `[specced]` with page backlink in its own `chore: mark reference N specced in construct <name>` commit.
- No construct rules restated — referenced from `GRIMOIRE-CONVENTIONS.md`.

## Commit

One commit for this step: `feat(grimoire): add construct size-eval and consumption to grimoire-spec`.
