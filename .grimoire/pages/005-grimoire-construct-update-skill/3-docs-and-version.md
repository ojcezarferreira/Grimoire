# Step 3 — Register the skill in docs + manifest, bump version

**Goal:** Make every user-facing surface aware of the new `grimoire-construct-update` skill, and bump the plugin version in lockstep. No code, no TDD — markdown + JSON edits. This step runs last so all descriptions match the skill body authored in Step 2 and the conventions from Step 1.

Six files are touched. Read each target region before editing so the new lines match the surrounding format exactly.

## 1. `CLAUDE.md`

- Add a `**grimoire-construct-update**` bullet to the **"The skills and how they connect"** enumeration, placed logically next to `grimoire-construct`. Describe it as the second authorized writer of construct files: alters an existing construct in place (add/remove/reorder references, edit a reference's detail, edit the construct intro, rename), enforces the locked-`[specced]`-prefix invariant with contiguous renumbering of the pending tail, never creates a construct or a page, never touches `HISTORIC.md`/`PROJECT.md`, ends with a single `docs(grimoire): update construct <name>` commit. Mirror the depth/tone of the existing `grimoire-construct` bullet.
- Update the **skill count** in the opening "What this repo is" paragraph: it currently says the plugin bundles **ten** skills — change to **eleven**.
- In the same opening paragraph, the parenthetical naming the skills' single-file paths lists each `skills/<name>/SKILL.md` — add `skills/grimoire-construct-update/SKILL.md` to that list.
- Anywhere `§ Construct`-dependent skills are referenced, include `grimoire-construct-update`.

## 2. `README.md`

- **Install line (~line 35):** append `/grimoire-construct-update` to the comma-separated list of available commands.
- **Skills table (~lines 65–67):** add a row for `/grimoire-construct-update <NNN|name> <change>` with a one-line description and a `[↓](#grimoire-construct-update)` detail anchor, placed after the `/grimoire-construct` row.
- **Skills in detail (~line 142+):** add a `### /grimoire-construct-update` subsection after `### /grimoire-construct`, in the same prose style: what it alters, the locked-`[specced]`-prefix safety rule, the four operation families, that it never creates a construct/page and never writes `HISTORIC.md`/`PROJECT.md`, and the single `docs(grimoire): update construct <name>` commit. Note it's orthogonal (same family as `grimoire-construct`, `grimoire-know`, `grimoire-update`, `grimoire-note`, `grimoire-deps`).

## 3. `README.pt-BR.md`

Mirror every `README.md` change in Portuguese-BR, matching the existing pt-BR phrasing and the parallel anchor/table structure:
- Install line (~line 35): append `/grimoire-construct-update`.
- Skills table (~lines 65–67): add the parallel row with `[↓](#grimoire-construct-update)`.
- Skills em detalhe (~line 142+): add the `### /grimoire-construct-update` subsection in pt-BR after `### /grimoire-construct`.

## 4. `CHANGELOG.md`

Add a new top version section `## [0.11.0] — <today's date, YYYY-MM-DD>` above `## [0.10.0]`. Under `### Added`, describe the new `grimoire-construct-update` skill (second authorized writer of construct files; alters existing constructs in place; four operation families; locked-`[specced]`-prefix invariant; contiguous pending-tail renumbering; rename preserves `NNN`; orthogonal — no page, no `HISTORIC.md`/`PROJECT.md`; single `docs(grimoire): update construct <name>` commit). Under `### Changed`, note the `GRIMOIRE-CONVENTIONS.md` amendments (`§ Construct` writer contract + new Alteration rules subsection, `§ Commits`, `§ Sub-agent spawning`, `§ Pause-point pattern`) and the `README`/`CLAUDE.md` doc updates. Match the wording style of the `0.10.0` entry.

**Use the real current date** for the section header — get it with `date +%F` (do not hardcode a guess).

## 5 & 6. Version bump (lockstep — CI enforces match)

- `.claude-plugin/plugin.json` — bump `"version": "0.10.0"` → `"0.11.0"`.
- `.claude-plugin/marketplace.json` — bump `"version": "0.10.0"` → `"0.11.0"`.

Both must carry the **same** version, and `CHANGELOG.md` must already have the matching `## [0.11.0]` section (done above) or the release workflow fails. Verify all three agree before committing.

## Discipline

- All descriptions must match the skill actually authored in Step 2 and the rules from Step 1 — no divergence.
- Conventional Commits in English; operator-facing prose in the READMEs follows each file's existing language (EN / pt-BR).
- Do **not** touch `HISTORIC.md` or `PROJECT.md` in this step.

## Commit

Per `§ Commits`, commit this step atomically (the doc + version edits are one tightly-coupled logical change — registering the skill across all surfaces). Suggested message:
`docs(grimoire): register grimoire-construct-update and bump to 0.11.0`
