---
depends-on: [1]
touches:
  - CLAUDE.md
  - README.md
  - README.pt-BR.md
  - CHANGELOG.md
  - .claude-plugin/plugin.json
  - .claude-plugin/marketplace.json
---

# Step 4 — Update project docs and cut the release metadata

Wire the new construct concept and `grimoire-construct` skill into the maintainer/user docs and bump the version. This step is mechanical/editorial; it depends on Step 1 (conventions) for accurate cross-references but is independent of Steps 2 and 3 (disjoint files).

> **Depends on Step 1.** Describe the construct per the new `§ Construct`; do not invent rules.

> **TDD note:** markdown/JSON only (no code, no tests). Verification is consistency: skill count, skill list, vocabulary, layout, and version must all agree. Follow `§ Commits`. **Release discipline (from `.grimoire/PROJECT.md`):** `plugin.json` and `marketplace.json` versions MUST match (CI enforces), and the CHANGELOG must already contain a section for the new version (the release workflow extracts notes from it) — so the CHANGELOG entry is part of this commit, not a follow-up.

## Required reading before editing

- `CLAUDE.md`, `README.md`, `README.pt-BR.md`, `CHANGELOG.md`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`.
- `.grimoire/pages/004-construct-concept/SPEC.md`.
- `GRIMOIRE-CONVENTIONS.md` `§ Construct` (for accurate descriptions).
- `.grimoire/PROJECT.md` (release discipline, vocabulary, bilingual docs).

## What to do

### A. `CLAUDE.md`

- Update the skill count: **"nine skills" → "ten skills"** (search for the current count phrasing and update every occurrence).
- Add the `grimoire-construct` entry to the SKILL.md frontmatter file list near the top (alongside the existing `skills/<name>/SKILL.md` links).
- Add a **`grimoire-construct`** bullet to "The skills and how they connect" describing: orthogonal skill that researches + interviews → writes a construct (`.grimoire/constructs/NNN-<name>/` with `CONSTRUCT.md` + ordered `references/`); never creates a page, never writes `HISTORIC.md`/`PROJECT.md`; consumed by `grimoire-spec` bare-number mode.
- Extend the **Vocabulary** section: introduce **"construct"** as the larger-than-a-page objective container (flat ordered list of reference-seeds; each reference → one page via the normal spec interview; self-contained, no HISTORIC entry).
- Note the new size-evaluation + bare-number consumption modes of `grimoire-spec` in its bullet.
- Add `constructs/` to the shared-conventions / `§ .grimoire/ layout` summary mention, and add `§ Construct` to the list of shared conventions.

### B. `README.md` (English) and `README.pt-BR.md` (Portuguese)

For **both** READMEs (keep them in parity, each in its own language per `.grimoire/PROJECT.md`):
- Add `grimoire-construct` to the documented skill set.
- Describe the **construct flow**: when an objective is too big for one page, `grimoire-spec` recommends a construct; `grimoire-construct` decomposes it into ordered reference-seeds; then `/grimoire-spec <number>` expands them one page at a time.
- Update any skill-count or skill-list references to include the tenth skill.

### C. `CHANGELOG.md`

- Add a new top section for the new **minor** version (see D for the number). Summarize: introduces the **construct** (larger-than-a-page objective container), the new **`grimoire-construct`** skill, `grimoire-spec` size-evaluation + bare-number construct-consumption modes, and the new `§ Construct` convention. Follow the existing changelog entry style.

### D. `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json`

- Bump the version with a **minor** increment (current is `0.9.0` → `0.10.0`). Confirm the current value by reading the file before editing.
- Update **both** files to the **same** version (CI enforces parity).
- If `plugin.json`'s `description` enumerates skills or skill count, update it to include `grimoire-construct` / "ten skills".

## Acceptance for this step

- `CLAUDE.md` reflects ten skills, includes the `grimoire-construct` bullet, the "construct" vocabulary, the updated `grimoire-spec` modes, and `constructs/` in the layout + `§ Construct` in shared conventions.
- Both READMEs document `grimoire-construct` and the construct flow, in their respective languages.
- `CHANGELOG.md` has a new `0.10.0` section describing the construct feature.
- `plugin.json` and `marketplace.json` are both at `0.10.0` (versions match).
- All skill-count / skill-list references across the docs are consistent.

## Commit

This step's files form one coherent release-metadata + docs change; commit as a single commit: `docs(grimoire): document construct concept and bump to 0.10.0`. (If you prefer, the version bump MAY be a separate `chore(release): 0.10.0` commit — but keep the CHANGELOG entry in the same commit as the version bump per release discipline.)
