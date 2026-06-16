# Step 3 — Wire `§ User-facing language` into all 11 `[Required Reading]` blocks

**Prerequisite:** Step 1 created the `§ User-facing language` section, so it now exists to be referenced. This step adds that reference to every skill's `[Required Reading]` so each skill loads the rule.

Touches **only** the `[Required Reading]` line (item `1.`, the parenthetical list of sections) in each `skills/*/SKILL.md`. Do not re-touch the `❌`/`📄` strings (Step 2) or version files (Step 4).

No TDD applies. Follow `§ Commits`.

## 3a — Add the section to each parenthetical list

Each skill's item `1.` of `[Required Reading]` contains a parenthetical like `(§ TDD, § Code comments, … § IDE-aware review, § Pause-point pattern)`. Add `§ User-facing language` to that list in **all 11** files:

1. `skills/grimoire-init/SKILL.md`
2. `skills/grimoire-spec/SKILL.md`
3. `skills/grimoire-plan/SKILL.md`
4. `skills/grimoire-execute/SKILL.md`
5. `skills/grimoire-quick/SKILL.md`
6. `skills/grimoire-know/SKILL.md`
7. `skills/grimoire-update/SKILL.md`
8. `skills/grimoire-note/SKILL.md`
9. `skills/grimoire-deps/SKILL.md`
10. `skills/grimoire-construct/SKILL.md`
11. `skills/grimoire-construct-update/SKILL.md`

**Placement rule (consistent across all files):** insert `§ User-facing language` **immediately before `§ Pause-point pattern`** in the list when that token is present (it governs operator-facing output, same as the IDE/pause sections it sits beside). If a given skill's list does not include `§ Pause-point pattern`, insert it immediately after `§ IDE-aware review`; if neither is present, append it at the end of the parenthetical. Keep the existing `§ ` prefix and comma-separated style exactly.

Some skills phrase the list slightly differently (e.g. wording around the parenthetical) — match the existing local style; the only required change is that `§ User-facing language` now appears in the list.

## 3b — Verify

- `grep -rl "§ User-facing language" skills/*/SKILL.md | wc -l` returns **11**.
- A full re-grep for pt-BR operator-facing literals across the repo is clean:
  `grep -rnE "não|já foi|Rode|está|Rascunho|primeiro|corrigir|aberto|seguir|may be pt-BR|pt-BR is permitted" skills/ GRIMOIRE-CONVENTIONS.md` returns nothing.
- Frontmatter and substitutions untouched.

## 3c — Commit

`docs(grimoire): wire user-facing-language into all required-reading blocks`

Cover only the 11 `skills/*/SKILL.md` files edited in this step.
