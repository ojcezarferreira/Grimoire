# Step 2 — Wire `§ Skill composition` into all 11 `[Required Reading]` blocks

Add the new section name to the load-bearing section list at the top of **every**
`SKILL.md`, exactly as `§ User-facing language` was wired across the suite in
page `006-user-facing-language`. This step depends on Step 1 having locked the
final section name (`§ Skill composition`).

`§ TDD` does not apply (no code). This step edits only the 11 `SKILL.md` files.

## The 11 files

1. `skills/grimoire-init/SKILL.md`
2. `skills/grimoire-spec/SKILL.md`
3. `skills/grimoire-plan/SKILL.md`
4. `skills/grimoire-execute/SKILL.md`
5. `skills/grimoire-quick/SKILL.md`
6. `skills/grimoire-know/SKILL.md`
7. `skills/grimoire-note/SKILL.md`
8. `skills/grimoire-deps/SKILL.md`
9. `skills/grimoire-construct/SKILL.md`
10. `skills/grimoire-construct-update/SKILL.md`
11. `skills/grimoire-update/SKILL.md`

## What to do in each file

- Locate the `[Required Reading]` block's first line — the sentence that reads
  `Read ... GRIMOIRE-CONVENTIONS.md. Its rules (§ ..., § ..., ...) are
  load-bearing for this skill.` (each skill lists a different subset).
- Add `§ Skill composition` to that parenthesized list. Place it in a sensible,
  consistent position relative to the other sections — directly after
  `§ Sub-agent spawning` where that section is listed, otherwise in an order
  that mirrors the section's placement in `GRIMOIRE-CONVENTIONS.md`. Match the
  surrounding punctuation/spacing exactly.
- If a particular skill's `[Required Reading]` enumerates sections in more than
  one place (some bodies repeat the list or annotate specific sections), only
  the load-bearing section-name list at the top needs the addition — do not
  invent new references elsewhere.

## Hard constraints

- **Do not** restate the rule body in any SKILL.md — bodies only **reference**
  the section name (single-source-of-truth discipline). Adding the name to the
  `[Required Reading]` list is the only edit.
- **Preserve verbatim** all SKILL.md frontmatter (`name`, `description`,
  `argument-hint`, the `---` delimiters) and the `${CLAUDE_PLUGIN_ROOT}` /
  `$ARGUMENTS` / `$1` substitutions. Do not reformat unrelated lines.

## Acceptance for this step

- All **11** `SKILL.md` `[Required Reading]` blocks list `§ Skill composition`
  among their load-bearing sections.
- No SKILL.md body restates the rule; each only names the section.
- Frontmatter and substitutions are untouched.

## Commit

Per `§ Commits`, end this step with a single atomic commit covering all 11
files (one tightly-coupled logical change):

`docs(grimoire): wire skill-composition into required reading`
