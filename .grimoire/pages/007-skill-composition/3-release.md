# Step 3 — Release: version bump + CHANGELOG

Ship the convention as a release. Bump the plugin version to **`0.13.0`**
(minor — new user-visible behavior, mirroring how `0.12.0` shipped the
analogous `§ User-facing language` cross-cutting convention) in both manifest
files, and add the matching `CHANGELOG.md` section. The release workflow
extracts notes from the CHANGELOG, so it ships in this same change — never as a
follow-up.

`§ TDD` does not apply (no code). This step edits `plugin.json`,
`marketplace.json`, and `CHANGELOG.md`.

## What to do

1. **`.claude-plugin/plugin.json`** — change `"version": "0.12.0"` to
   `"version": "0.13.0"`.
2. **`.claude-plugin/marketplace.json`** — change `"version": "0.12.0"` to
   `"version": "0.13.0"`. The two **must** stay identical — release CI fails on
   mismatch.
3. **`CHANGELOG.md`** — add a new `0.13.0` section at the top of the entries,
   matching the structure and tone of the existing `0.12.0` section. It must
   describe this page's change: a new `§ Skill composition` convention by which
   every Grimoire skill surveys the runtime's available-skills list and composes
   with relevant helpers — read-only/assistive helpers run automatically with a
   `🧩` one-line announcement, while write/side-effect/scope-changing helpers
   are gated by an explicit user ok folded into existing pause-points; conflicting
   orchestrators are excluded; helpers never own `.grimoire/` state or override
   Grimoire contracts; and the section is wired into all 11 SKILL.md
   `[Required Reading]` blocks.

## Hard constraints

- `plugin.json` and `marketplace.json` versions **must** match exactly
  (`0.13.0`).
- The `CHANGELOG.md` section header **must** be for exactly `0.13.0` (the
  version the manifests now declare) — otherwise the release workflow fails to
  extract notes.
- Preserve the existing date/format conventions of the CHANGELOG (look at the
  `0.12.0` entry and follow its heading style and date format).

## Acceptance for this step

- `plugin.json` and `marketplace.json` both declare `0.13.0`.
- `CHANGELOG.md` has a `0.13.0` section describing the new convention.

## Commit

Per `§ Commits`, end this step with a single atomic commit covering the two
manifest files and the CHANGELOG:

`docs(grimoire): release 0.13.0 with skill-composition convention`
